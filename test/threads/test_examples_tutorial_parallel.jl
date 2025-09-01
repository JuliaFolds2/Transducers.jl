module TestExamplesTutorialParallel
using LiterateTest.AssertAsTest: @assert

if VERSION < v"1.11-"
    # There's a bug in early versions of v.1.11 that cause this to segfault
    # Issue to track is https://github.com/JuliaLang/julia/issues/52032
    include("../../examples/tutorial_parallel.jl")
else
    @warn "Skipping tests on ../../examples/tutorial_parallel.jl due to a bug.\nPlease check and see if https://github.com/JuliaLang/julia/issues/52032 is fixed, and if so, re-enable this test"
end

end  # module
