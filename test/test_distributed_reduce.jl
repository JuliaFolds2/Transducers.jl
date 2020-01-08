module TestDistributedReduce

include("preamble.jl")
using BangBang
using Distributed
using Logging: LogLevel
using StructArrays: StructVector
using Test: collect_test_logs

const ProgressLevel = LogLevel(-1)

@testset "dreduce" begin
    fname = gensym(:attach_pid)
    @everywhere $fname(x) = [(x, getpid())]
    fun = getproperty(Main, fname)

    pids = fetch.(map(id -> remotecall(getpid, id), workers()))
    xs0 = 1:10
    @testset "dreduce(..., $xslabel; $kwargs...)" for (xslabel, xs) in Any[
            # Input containers:
            ("$xs0", xs0),
            ("withprogress(xs; interval=0)", withprogress(xs0; interval = 0)),
        ],
        kwargs in Any[
            # Keyword arguments to `dreduce`:
            (),
            (basesize = 1,),
            (basesize = 1, threads_basesize = 1),
            (basesize = 4, threads_basesize = 2),
            (basesize = 4, threads_basesize = 2, simd = true),
        ]

        ys = dreduce(append!!, Map(fun), xs; init = Union{}[], kwargs...)
        @test first.(ys) == xs0
        @test Set(last.(ys)) == Set(pids)
    end
end

@testset "dcollect & dcopy" begin
    @test dcollect(Filter(iseven), 1:10, basesize = 2) == 2:2:10

    fname = gensym(:makerow)
    @everywhere $fname(x) = (a = x,)
    makerow = getproperty(Main, fname)
    @everywhere import StructArrays
    @test dcopy(Map(makerow), StructVector, 1:3, basesize = 2) == StructVector(a = 1:3)
end

@testset "basesize > 0" begin
    @test dcollect(Map(identity), [1]) == [1]
end

@testset "empty input" begin
    @test isempty(dcollect(Map(identity), []))
end

@testset "withprogress" begin
    xs = 1:10
    @testset "dreduce(..., withprogress(xs; interval=0); $kwargs...)" for kwargs in Any[
        # Keyword arguments to `dreduce`:
        (),
        (basesize = 4, threads_basesize = 2),
        (basesize = 4, threads_basesize = 2, simd = true),
    ]
        logs, ans = collect_test_logs(min_level = ProgressLevel) do
            dreduce(+, Map(identity), withprogress(xs; interval = 0.0); kwargs...)
        end
        @test ans == sum(xs)
        @test length(logs) > 2
        @test logs[1].kwargs[:progress] === 0.0
        @test all(l.kwargs[:progress] isa Float64 for l in logs[2:end-1])
        @test logs[end].kwargs[:progress] === "done"
    end
end

end  # module