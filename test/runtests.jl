using AlgorithmAnalysis
using Test

@testset "AlgorithmAnalysis.jl" begin
  for resultFile in getAllResult()
    for (name, handle) in resultFile.test_cases
      testResult = Base.invokelatest(handle.function_pointer)
      if typeof(testResult) != Bool || !testResult
        println("Test failure of test $(name) @ $(handle.function_path)");
      end

      @test testResult
    end
  end
end
