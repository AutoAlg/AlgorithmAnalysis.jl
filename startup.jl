cd("C:\\Users\\vanscob\\github\\AlgorithmAnalysis.jl\\")
using Pkg
Pkg.activate(".")
using Revise
using AlgorithmAnalysis


############################################################################################
# ALGEBRA

add = instance(R).addition
mul = instance(R).multiplication

@algorithm begin
    # a ∈ R
    # b ∈ R
    # c ∈ R
    # d = 2a - b + 3c

    # x ∈ Rⁿ
    # y ∈ Rⁿ
    # z = 2x - y

    f ∈ 𝓕{Rⁿ}
    α ∈ R
    x ∈ Rⁿ
    xs ∈ Rⁿ
    y = x - α * f'(x)
    
    performance = (x-xs)^2
end

# nodes(a)

# vars = filter(x -> isa(x, Element{R}) && !hasvalue(x), nodes(a))