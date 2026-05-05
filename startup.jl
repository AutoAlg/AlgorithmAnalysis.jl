using Pkg

Pkg.activate(".")

using AlgorithmAnalysis
using Base.ScopedValues

original_context::AlgorithmContext = AlgorithmContext()
step_size::Float64 = 0.05

t = with_context(original_context) do
    f, ∇f = SSC(3, 10)
    set_alias!(f, "f")
    set_alias!(∇f, "∇f")
    
    x0 = NewRⁿ()
    set_alias!(x0, "x0")

    x1 = x0 - step_size * ∇f(x0)
    set_alias!(x1, "x1")
    
    transition = (x0 => x1)
    set_alias!(transition, "step")

    transition
end

print(original_context)

pruned_context::AlgorithmContext = eliminate_unreachable_expressions(original_context, [t])

print(pruned_context)