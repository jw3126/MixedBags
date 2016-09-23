using MixedBag
using Base.Test


@MixedBag Bar Int64 Float64
@testset "@MixedBag Bar Int64 Float64" begin
    @test eltypes(Bar) == [Int64, Float64]

    @testset "Empty constructor" begin
        @test eltypes(Bar()) == [Int64, Float64]
        @test Bar()[Int64] == Int64[]
        @test Bar()[Float64] == Float64[]
        acc = 0.
        foreach(Bar()) do x
            acc += x
        end
        @test acc == 0.
    end

    @testset "Mixed constructor" begin
        b = Bar(1, 2, 0.3)
        @test b == Bar(1, 2, 0.3)
        @test b != Bar(1,2,3)
        @test push!(b, 3) == Bar(1,2,3, 0.3)
        @test b[Int64] == [1,2,3]
        @test b[Float64] == [0.3]
        acc = 0.
        foreach(b) do x
            acc += x
        end
        @test acc ≈ 1+2+3+0.3
        @test mapreduce(√, +, 0, b) ≈ mapreduce(√, +, 0, [1,2,3,0.3])
    end

    @test Bar(1, 2) == Bar(1, 2)
end
