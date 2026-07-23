using AlgorithmAnalysis

@alg begin
    α ∈ R
    x ∈ Rⁿ
    g ∈ Rⁿ
    x → x - α * g
end

println("Transition defined: ", isdefined(Main, :__transition__))
if isdefined(Main, :__transition__)
    println("Transition type: ", typeof(__transition__))
    println("Transition: ")
    println(__transition__)
end
