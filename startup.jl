using Pkg

Pkg.activate(".")

using AlgorithmAnalysis
using Base.ScopedValues

original_context::AlgorithmContext = AlgorithmContext()
step_size::Float64 = 0.05

with_context(original_context) do
    g, ∇g = SSC(3, 10)
    set_name!(g, "g")
    set_name!(∇g, "∇g")
    
    x0 = NewRⁿ()
    set_name!(x0, "x0")

    x1 = x0 - step_size * ∇g(x0)
    set_name!(x1, "x1")
    
    transition = (x0 => x1)
    set_name!(transition, "step")
end

print(original_context)

pruned_context::AlgorithmContext = eliminate_unreachable_expressions(original_context)

print(pruned_context)