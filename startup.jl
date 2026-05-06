using Pkg

Pkg.activate(".")

using AlgorithmAnalysis
using Base.ScopedValues

original_context::AlgorithmContext = AlgorithmContext()
step_size::Float64 = 0.05

e = with_context(original_context) do
    f, ∇f = SSC(3, 10)
    set_alias!(f, "f")
    set_alias!(∇f, "∇f")

    xs = NewRⁿ();
    set_alias!(xs, "xs");
    # TODO: constraints

    
    x0 = NewRⁿ()
    set_alias!(x0, "x0")

    x1 = x0 - step_size * ∇f(x0)
    set_alias!(x1, "x1")
    
    transition = (x0 => x1)
    set_alias!(transition, "step")

    performance = (x1 - xs)^2;
    set_alias!(performance, "performance");

    [performance, transition]
end

print(original_context)

pruned_context::AlgorithmContext = eliminate_unreachable_expressions(original_context, e)

print(pruned_context)