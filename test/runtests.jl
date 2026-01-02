using AlgorithmAnalysis
using Test
using Revise

@testset "AlgorithmAnalysis.jl" begin
  include("test_random.jl")

  test_random()
  # ###############################################################################
  # # Relation
  # r1 = Relation( Set{Pair{Int64, Float64}}([ 1 => 1.0, 1 => 2.0, 2 => 4.0, 3 => 4.0 ]) )
  # r2 = Relation( Set{Pair{Float64, Int64}}([ 6.0 => 2, 2.0 => 5 ]) )

  # @test domain(r1) == Int64
  # @test codomain(r1) == Float64
  # @test inputs(r1) == Set{Int64}([1,2,3])
  # @test outputs(r1) == Set{Float64}([1.0,2.0,4.0])
  # @test r1(1) == Set{Float64}([1.0,2.0])
  # @test r1(Set{Int64}([2,3])) == Set{Float64}([4.0])
  # @test inv(r1) == Relation( Set([ 1.0 => 1, 2.0 => 1, 4.0 => 2, 4.0 => 3 ]) )
  # @test r1 ∘ r2 == Relation( Set([ 6.0 => 4.0 ]) )
  # @test r2 ∘ r1 == Relation( Set([ 1 => 5 ]) )
  # @test r1 + inv(r2) == Relation( Set([ 2 => 10.0 ]) )
  # @test r2 + inv(r1) == Relation( Set([ 2.0 => 6 ]) )

  # @test begin
  #   m, L = 1, 10
  #   α = 2 / (L + m)
  #   @algorithm begin
  #     f = DifferentiableFunctional{Rⁿ}()
  #     xs = first_order_stationary_point(f)
  #     f' ∈ SectorBounded(m, L, xs, f'(xs))
  #     x0 = Rⁿ()
  #     x1 = x0 - α * f'(x0)
  #     x0 => x1
  #     performance = (x0 - xs)^2
  #   end
  #   rate(performance) ≈ ((L - m) / (L + m))^2
  # end
end
