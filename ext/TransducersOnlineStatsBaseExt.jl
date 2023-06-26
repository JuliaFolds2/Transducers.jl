module TransducersOnlineStatsBaseExt

if isdefined(Base, :get_extension)
    using Transducers: Transducers, reducingfunction, Transducer, foldxl, foldxt, foldxd, extract_transducer, OSNonZeroNObsError
    using Transducers.InitialValues
    using InitialValues: GenericInitialValue
    using OnlineStatsBase
else
    using ..Transducers: Transducers, reducingfunction, Transducer, foldxl, foldxt, foldxd, extract_transducer, OSNonZeroNObsError
    using ..Transducers.InitialValues
    using ..InitialValues: GenericInitialValue
    using ..OnlineStatsBase
end

"""
    Transducer(o::OnlineStat)

Use an `OnlineStat` as a stateful transducer.

It is implemented as:

```julia
opcompose(Scan(fit!, CopyInit(o)), Map(value))
```

# Examples
```jldoctest
julia> using Transducers
       using OnlineStats: Mean

julia> collect(Transducer(Mean()), 1:4)
4-element Vector{Float64}:
 1.0
 1.5
 2.0
 2.5
```
"""
Transducers.Transducer(o::OnlineStatsBase.OnlineStat) =
Transducers.Map(OnlineStatsBase.value) ∘ Transducers.Scan(OnlineStatsBase.fit!, Transducers.CopyInit(o))
# TODO: implement `combine`

"""
    reducingfunction([xf::Transducer,] o::OnlineStat; simd)

Convert an `OnlineStat` to a reducing function.  Returned function can
be used with [`foldl`](@ref), [`foldxt`](@ref), and [`foldxd`](@ref).
Note that input `o` is only used as a "prototype"; i.e., it's not
going to be mutated.

# Examples
```jldoctest
julia> using Transducers
       using OnlineStats: Mean

julia> foldl(reducingfunction(Mean()), Map(x -> x^2), 1:4)
Mean: n=4 | value=7.5

julia> foldl(Mean(), Map(x -> x^2), 1:4)  # equivalent to above
Mean: n=4 | value=7.5

julia> foldxt(Mean(), Map(x -> x^2), 1:4)  # threaded
Mean: n=4 | value=7.5

julia> foldl(Mean(), eduction(x^2 for x in 1:4))  # ditto
Mean: n=4 | value=7.5

julia> foldxt(Mean(), eduction(x^2 for x in 1:4))  # ditto
Mean: n=4 | value=7.5
```

[`foldxd`](@ref) can be used instead of `foldxt`.  However the usual caveats
of code availability for Distributed.jl apply.
"""
Transducers.reducingfunction(xf::Transducer, stat::OnlineStatsBase.OnlineStat; kwargs...) =
    Transducers.reducingfunction(xf, reducingfunction(stat); kwargs...)

@inline Transducers._reducingfunction(xf, stat::OnlineStatsBase.OnlineStat; kwargs...) =
Transducers._reducingfunction(xf, reducingfunction(stat); kwargs...)

struct OnlineStatReducingFunction{T<:OnlineStatsBase.OnlineStat} <: Function
    init::T
end

Transducers.reducingfunction(stat::OnlineStatsBase.OnlineStat) = OnlineStatReducingFunction(stat)

InitialValues.hasinitialvalue(::Type{<:OnlineStatReducingFunction}) = true

# `GenericInitialValue{T}` for case when `init=Init(op::OnlineStat)`
# is explicitly passed.
const OSInit{T} =
    Union{GenericInitialValue{T},GenericInitialValue{OnlineStatReducingFunction{T}}}

(rf::OnlineStatReducingFunction{T})(::OSInit{T}, x) where {T<:OnlineStatsBase.OnlineStat} =
    rf(copy(rf.init), x)

function (::OnlineStatReducingFunction)(acc, x)
    OnlineStatsBase.fit!(acc, x)
    return acc
end

Transducers.combine(::OnlineStatReducingFunction{T}, a::T, b::T) where {T<:OnlineStatsBase.OnlineStat} =
    merge!(a, b)

    Transducers.combine(
    ::OnlineStatReducingFunction{T},
    a::Union{T,OSInit{T}},
    ::OSInit{T},
) where {T<:OnlineStatsBase.OnlineStat} = a

Transducers.combine(
    ::OnlineStatReducingFunction{T},
    ::OSInit{T},
    b::T,
) where {T<:OnlineStatsBase.OnlineStat} = b



function validate_reduce_ostat(stat)
    if OnlineStatsBase.nobs(stat) != 0
        throw(OSNonZeroNObsError)
    end
    return stat
end

# Method plumbing:
Transducers.foldxl(stat::OnlineStatsBase.OnlineStat, xform::Transducer, itr; kwargs...) =
    foldxl(reducingfunction(stat), xform, itr; kwargs...)

Transducers.foldxl(stat::OnlineStatsBase.OnlineStat, foldable; kwargs...) =
    foldxl(reducingfunction(stat), extract_transducer(foldable)...; kwargs...)

Transducers.foldxt(stat::OnlineStatsBase.OnlineStat, xform::Transducer, itr; kwargs...) =
    foldxt(reducingfunction(validate_reduce_ostat(stat)), xform, itr; kwargs...)

Transducers.foldxt(stat::OnlineStatsBase.OnlineStat, foldable; kwargs...) = foldxt(
    reducingfunction(validate_reduce_ostat(stat)),
    extract_transducer(foldable)...;
    kwargs...,
)

Transducers.foldxd(stat::OnlineStatsBase.OnlineStat, xform::Transducer, itr; kwargs...) =
    foldxd(reducingfunction(validate_reduce_ostat(stat)), xform, itr; kwargs...)

Transducers.foldxd(stat::OnlineStatsBase.OnlineStat, foldable; kwargs...) = foldxd(
    reducingfunction(validate_reduce_ostat(stat)),
    extract_transducer(foldable)...;
    kwargs...,
)

end #module
