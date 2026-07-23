using AlgorithmAnalysis

@alg let
    x ∈ R
    A = [-2 x; x -2]
end

println("Test 1 passed: @alg let syntax works")

@alg begin
    α ∈ R
    x ∈ Rⁿ
    g ∈ Rⁿ
    x → x - α * g
end

println("Test 2 passed: @alg with transitions works")
if isdefined(Main, :__transition__)
    println("Transition defined: ", __transition__)
end
