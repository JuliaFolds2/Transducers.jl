module TestDoctest

using Documenter
using Test
using Transducers

# Workaround: Failed to evaluate `CurrentModule = Transducers` in `@meta` block.
@eval Main import Transducers

const __is32bit = Int == Int32


if !__is32bit 
    #the docs are meant with 64 bits in mind.
    #so we skip the doctests on 32 bits,because of the Int issue.
    @testset "/docs" begin
        doctest(Transducers; manual=true)
    end

    @testset "/test/doctests" begin
        doctest(joinpath((@__DIR__), "doctests"), Module[])
    end
end

end  # module
