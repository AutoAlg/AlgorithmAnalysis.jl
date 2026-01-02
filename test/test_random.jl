using Test
using AlgorithmAnalysis
using LinearAlgebra

function test_random()
    @testset begin
        @algorithm begin
            x = R()
            rx = RandomR(x)
            @test rx isa RandomR
            @test rx.mean === x
            @test label(rx.mean) == label(x)

            s = x + rx
            @test s isa RandomR
            @test isequal(𝔼(s), 𝔼(x) + 𝔼(rx))
            @test isequal(𝔼(s), 𝔼(x + rx))
        end
    end


    @testset begin
        @algorithm begin
            x = RandomR()
            y = RandomR()

            z = 2x + y

            @test z isa RandomR
            @test hasdecomposition(z)
            @test isequal(𝔼(z), 𝔼(y) + 2 * 𝔼(x))
        end
    end


    @testset begin
        @algorithm begin
            w = RandomRⁿ()
            k = RandomRⁿ()

            inner_product = w' * k
            expected_inner_product = 𝔼(inner_product)

            @test inner_product isa RandomR
            @test expected_inner_product isa R
        end
    end
end