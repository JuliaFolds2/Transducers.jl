module TestAqua

using Aqua
using Accessors
using Test
using Transducers

# https://github.com/JuliaCollections/DataStructures.jl/pull/511
to_exclude = Any[map!]

# These are needed because of a potential ambiguity with ChainRulesCore's mapfoldl on a Thunk.
if isdefined(Core, :kwcall)
    push!(to_exclude, Core.kwcall)

    Aqua.test_all(
        Transducers;
        ambiguities = (; exclude = to_exclude),
        unbound_args = false,  # TODO: make it work
        deps_compat = (; check_extras = false)
    )

else
    nothing
    # Let's just skip this for now on old versions that don't have kwcall, it's too annoying to deal with.
end



end  # module
