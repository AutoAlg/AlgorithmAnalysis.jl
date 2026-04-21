using Pkg

Pkg.activate(".")

using AlgorithmAnalysis
using Base.ScopedValues

ctx = AlgorithmContext()
α = 0.05

with(ALGORITHM_CONTEXT => ctx) do
    g, ∇g = SSC(3, 10)
    set_name!(g, "g")
    set_name!(∇g, "∇g")
    
    x0 = NewRⁿ()
    set_name!(x0, "x0")

    x1 = x0 - α * ∇g(x0)
    set_name!(x1, "x1")
    
    transition = (x0 => x1)
    set_name!(transition, "step")

    print(ctx)
end
