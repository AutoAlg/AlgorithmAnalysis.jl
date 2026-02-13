using AlgorithmAnalysis
using Test

@testset "AlgorithmAnalysis.jl" begin
  for result ∈ KNOWN_RESULTS
    @test verify(result)
  end
end
