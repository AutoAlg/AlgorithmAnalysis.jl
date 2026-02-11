using AlgorithmAnalysis
using Test

@testset "AlgorithmAnalysis.jl" begin
  @test gradient_descent(1, 10, ρ = (9/11)^2, measure = DistanceToOptimality)
  @test gradient_descent(1, 10, ρ = (9/11)^2, measure = DistanceToStationarity, n=2)
end
