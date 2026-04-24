using Pkg

Pkg.activate(".")

using AlgorithmAnalysis
using Base.ScopedValues

original_context::AlgorithmContext = AlgorithmContext()
step_size::Float64 = 0.05

with(ALGORITHM_CONTEXT => original_context) do
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

println("=== Original Context ===")
print(original_context)

pruned_context::AlgorithmContext = eliminate_unreachable_expressions(original_context)

println("\n=== Pruned Cloned Context ===")
print(pruned_context)