module TestExamplesTutorialParallel
using LiterateTest.AssertAsTest: @assert

# It looks like `Channel` was not thread-safe before 1.2.
# * https://travis-ci.com/JuliaFolds/Transducers.jl/jobs/270458293
# * https://github.com/JuliaLang/julia/commit/961907977a57ae7b72ddb374e63341f3633a0f0a
if VERSION >= v"1.2"
    if VERSION < v"1.11-"
        # There's a bug in early versions of v.1.11 that cause this to segfault
        # Issue to track is https://github.com/JuliaLang/julia/issues/52032
        include("../../examples/tutorial_parallel.jl")
    else
        @warn "Skipping tests on ../../examples/tutorial_parallel.jl due to a bug.\nPlease check and see if https://github.com/JuliaLang/julia/issues/52032 is fixed, and if so, re-enable this test"
    end
end

end  # module
