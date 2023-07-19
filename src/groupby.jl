"""
    GroupBy(key, xf::Transducer, [step = right, [init]])
    GroupBy(key, rf, [init])

Group the input stream by a function `key` and then fan-out each group
of key-value pairs to the eduction `xf'(step)`.  This is similar to the
`groupby` relational database operation.

For example

    [1,2,1,2,3] |> GroupBy(string, Map(last)'(+)) |> foldxl(right)

returns a result equivalent to `Dict("1"=>2, "2"=>4, "3"=>3)` while

    [1,2,1,2,3] |> GroupBy(string, Map(last) ⨟ Map(Transducers.SingletonVector), append!!) |> foldxl(right)

returns a result equivalent to `Dict("1"=>[1,1], "2"=>[2,2], "3"=>[3,3])`.

Alternatively, one can provide a reducing function directly, though this is disfavored since it prevents
results from being combined with [`Transducers.combine`](@ref) and therefore cannot be used
with [`foldxt`](@ref) or [`foldxd`](@ref).  For example, if `GroupBy` is used as in:

    xs |> Map(upstream) |> GroupBy(key, rf, init) |> Map(downstream)

then the function signatures would be:

    upstream(_) :: V
    key(::V) :: K
    rf(::Y, ::Pair{K, V}) ::Y
    downstream(::Dict{K, Y})

That is to say,

* Ouput of the `upstream` is fed into the function `key` that produces
  the group key (of type `K`).

* For each new group key, a new transducible process is started with
  the initial state `init :: Y`.  Pass [`OnInit`](@ref) or
  [`CopyInit`](@ref) object to `init` for creating a dedicated
  (possibly mutable) state for each group.

* After one "nested" reducing function `rf` is called, the
  intermediate result dictionary (of type `Dict{K, Y}`) accumulating
  the current and all preceding results is then fed into the
  `downstream`.

See also `groupreduce` in
[SplitApplyCombine.jl](https://github.com/JuliaData/SplitApplyCombine.jl).

# Examples
```jldoctest; setup = :(using Transducers)
julia> [1,2,3,4] |> GroupBy(iseven, Map(last)'(+)) |> foldxl(right)
Transducers.GroupByViewDict{Bool,Int64,…}(...):
  0 => 4
  1 => 6
```

```jldoctest; setup = :(using Transducers)
julia> using Transducers: SingletonDict;

julia> using BangBang; # for merge!!

julia> x = [(a="A", b=1, c=1), (a="B", b=2, c=2), (a="A", b=3, c=3)];

julia> inner = Map(last) ⨟ Map() do ξ
           SingletonDict(ξ.b => ξ.c)
       end;

julia> x |> GroupBy(ξ -> ξ.a, inner, merge!!) |> foldxl(right)
Transducers.GroupByViewDict{String,Dict{Int64, Int64},…}(...):
  "B" => Dict(2=>2)
  "A" => Dict(3=>3, 1=>1)
```

Note that the reduction stops if one of the group returns a
[`reduced`](@ref).  This can be used, for example, to find if there is
a group with a sum grater than 3 and stop the computation as soon as
it is find:

```jldoctest; setup = :(using Transducers)
julia> result = transduce(
           GroupBy(
               string,
               Map(last) ⨟ Scan(+) ⨟ ReduceIf(x -> x > 3),
           ),
           right,
           nothing,
           [1, 2, 1, 2, 3],
       );

julia> result isa Reduced
true

julia> unreduced(result)
Transducers.GroupByViewDict{String,Any,…}(...):
  "1" => 2
  "2" => 4
```
"""
struct GroupBy{K, R, T} <: Transducer
    key::K
    rf::R
    init::T
end

function GroupBy(key, xf::Transducer, step = right, init = DefaultInit)
    rf = _reducingfunction(xf, step; init = init)
    return GroupBy(key, rf, init)
end

GroupBy(key, rf) = GroupBy(key, _asmonoid(rf), DefaultInit)

# `GroupByViewDict` wraps a dictionary whose values are the
# (composite) states of the reducing function and provides a view such
# that the its values are the state/result/accumulator of the bottom
# reducing function.
struct GroupByViewDict{K,V,S<:DefaultInitOf,D<:AbstractDict{K}} <: AbstractDict{K,V}
    state::D
end

# https://github.com/JuliaLang/julia/issues/30751
_typesubtract(::Type{Larger}, ::Type{Smaller}) where {Larger,Smaller} =
    _typesubtract_impl(Smaller, Larger)
_typesubtract_impl(::Type{T}, ::Type{T}) where {T} = Union{}
_typesubtract_impl(::Type{T}, ::Type{Union{T,S}}) where {S,T} = S
_typesubtract_impl(::Type, ::Type{S}) where {S} = S

_bottom_state_type(::Type{T}) where {T} = T
_bottom_state_type(::Type{Union{}}) = Union{}
_bottom_state_type(::Type{<:PrivateState{<:Any,<:Any,R}}) where {R} = R

function GroupByViewDict(state::AbstractDict{K,V0}, xf::GroupBy) where {K,V0}
    S = typeof(DefaultInit(_realbottomrf(xf.rf)))
    V = _typesubtract(_bottom_state_type(V0), S)
    return GroupByViewDict{K,V,S,typeof(state)}(state)
end

struct _NoValue end

Base.IteratorSize(::Type{<:GroupByViewDict}) = Base.SizeUnknown()
function Base.iterate(dict::GroupByViewDict{<:Any,<:Any,S}, state = _NoValue()) where {S}
    y = state isa _NoValue ? iterate(dict.state) : iterate(dict.state, state)
    y === nothing && return nothing
    while true
        (k, v), state = y
        v isa S || return (k => unwrap_all(unreduced(v))), state
        y = iterate(dict.state, state)
        y === nothing && return nothing
    end
end

Base.length(dict::GroupByViewDict) = count(true for _ in dict)
function Base.showarg(io::IO, dict::GroupByViewDict, _toplevel)
    print(io, GroupByViewDict, '{', keytype(dict), ',', valtype(dict), ",…}")
end

function Base.getindex(dict::GroupByViewDict{<:Any,<:Any,S}, key) where {S}
    value = unwrap_all(unreduced(dict.state[key]))
    value isa S && throw(KeyError(key))
    return value
end

function Base.get(dict::GroupByViewDict{<:Any,<:Any,S}, key, default) where {S}
    val = get(dict.state, key, _NoValue())
    if val ≡ _NoValue()
        default
    else
        val = unwrap_all(unreduced(something(val)))
        val isa S ? default : val
    end
end

#this is copied from SplittablesBase.halve(::DictLike) which should probably be more generic
function SplittablesBase.halve(dict::GroupByViewDict{K,V,S}) where {K,V,S}
    i1 = SplittablesBase.Implementations.firstslot(dict.state)
    i3 = SplittablesBase.Implementations.lastslot(dict.state)
    i2 = (i3 - i1 + 1) ÷ 2 + i1
    left = SplittablesBase.Implementations.DictView(dict, i1, i2 - 1)
    right = SplittablesBase.Implementations.DictView(dict, i2, i3)
    (left, right)
end

function start(rf::R_{GroupBy}, result)
    gstate = Dict{Union{},Union{}}()
    return wrap(rf, gstate, start(inner(rf), result))
end

complete(rf::R_{GroupBy}, result) = complete(inner(rf), unwrap(rf, result)[2])

@inline function next(rf::R_{GroupBy}, result, input)
    wrapping(rf, result) do gstate, iresult
        key = xform(rf).key(input)
        gstate, somegr = modify!!(gstate, key) do value
            if value === nothing
                gr0 = start(xform(rf).rf, xform(rf).init)
            else
                gr0 = something(value)
            end
            return Some(next(xform(rf).rf, gr0, key => input))  # Some(gr)
        end
        gr = something(somegr)
        iresult = next(inner(rf), iresult, GroupByViewDict(gstate, xform(rf)))
        if gr isa Reduced && !(iresult isa Reduced)
            return gstate, reduced(complete(inner(rf), iresult))
        else
            return gstate, iresult
        end
    end
end

function combine(rf::R_{GroupBy}, a, b)
    gstate_a, ira = unwrap(rf, a)
    gstate_b, irb = unwrap(rf, b)
    gstate_c = mergewith!!(gstate_a, gstate_b) do ua, ub
        combine(xform(rf).rf, ua, ub)
    end
    irc = combine(inner(rf), ira, irb)
    irc = next(inner(rf), irc, GroupByViewDict(gstate_c, xform(rf)))
    return wrap(rf, gstate_c, irc)
end
