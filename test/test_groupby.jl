module TestGroupBy
include("preamble.jl")
using Transducers: DefaultInit

@testset begin
    @test foldl(right, GroupBy(string, Map(last), push!!), [1, 2, 1, 2, 3]) ==
          Dict("1" => [1, 1], "2" => [2, 2], "3" => [3])

    @test foldl(
        right,
        GroupBy(
            identity,
            opcompose(Map(last), Scan(+)),
            (_, x) -> x > 3 ? reduced(x) : x,
            nothing,
        ),
        [1, 2, 1, 2, 3],
    ) == Dict(2 => 4, 1 => 2)
end

@testset "post-groupby filtering" begin
    d = foldl(right, GroupBy(isodd, opcompose(Map(last), Filter(isodd)), +), 1:10)
    @test d == Dict(true => 25)
    @test d.state == Dict(true => 25, false => DefaultInit(+))
    @test valtype(d) <: Int
    @test valtype(d.state) <: Union{Int,typeof(DefaultInit(+))}
end

@testset "automatic asmonoid" begin
    @test foldl(right, GroupBy(identity, Map(first), (a, b) -> a + b), [1, 2, 1, 2, 3]) ==
          Dict(1 => 2, 2 => 4, 3 => 3)

    @test foldl(right, GroupBy(identity, (_, x) -> x), [1, 2, 1, 2, 3]) ==
          Dict(1 => 1 => 1, 2 => 2 => 2, 3 => 3 => 3)
end

@testset "GroupByViewDict" begin
    gd1 = foldl(right, GroupBy(string, Map(last), push!!), [1, 2, 1, 2, 3])
    gd2 = foldl(
        right,
        GroupBy(x -> gcd(x, 6), opcompose(Map(last), Filter(isodd)), push!!),
        1:10,
    )
    gd3 = foldl(
        right,
        opcompose(Filter(isodd), GroupBy(x -> gcd(x, 6), Map(last), push!!)),
        1:10,
    )
    gd4 = foldl(
        right,
        GroupBy(x -> gcd(x, 6), opcompose(Map(last), Unique(x -> gcd(x, 4))), push!!),
        1:10,
    )
    @test gd1 == Dict("1" => [1, 1], "2" => [2, 2], "3" => [3])
    @test gd2 == gd3
    @test gd4 == Dict(2 => [2, 4], 3 => [3], 6 => [6], 1 => [1])
    @test get(gd1, "1", Int[]) == [1, 1]
    @test get(gd1, "9", Int[]) == Int[]
    @test Dict(gd1) == Dict("1" => [1, 1], "2" => [2, 2], "3" => [3])
    @test Dict(gd2) == Dict(gd3)
    @test Dict(gd4) == Dict(2 => [2, 4], 3 => [3], 6 => [6], 1 => [1])

    # ensure we can use GroupByViewDict it in foldxt
    r1 = gd1 |> MapSplat((k, v) -> k=>sum(v)) |> tcollect
    @test Set(r1) == Set(["1"=>2, "2"=>4, "3"=>3])  # order not guaranteed

    # TODO: one would expect this to work, but it doesn't, because foldxt calls combine,
    # which needs to know about the inner reducing function (here push!!) which it can't
    # infer from this lambda
    gb = GroupBy(string, (y, (k, v)) -> push!!(y, v))
    @test_broken foldxt(right, gb, [1,2,1,2,3])
end

end  # module
