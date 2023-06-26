module TestDoctest

using Documenter
using Test
using Transducers

# Workaround: Failed to evaluate `CurrentModule = Transducers` in `@meta` block.
@eval Main import Transducers

const __is32bit = Int == Int32


if !__is32bit && Base.VERSION >= v"1.7"
    #the docs are meant with 64 bits in mind.
    #so we skip the doctests on 32 bits,because of the Int issue.

    #the version issue is https://github.com/joshday/OnlineStatsBase.jl/issues/32 .
    #should be solved by https://github.com/joshday/OnlineStatsBase.jl/pull/34 .
    #in the meanwhile, skip doctests for 1.6
    @testset "/docs" begin
        doctest(Transducers; manual=true)
    end

    @testset "/test/doctests" begin
        doctest(joinpath((@__DIR__), "doctests"), Module[])
    end
end

end  # module
