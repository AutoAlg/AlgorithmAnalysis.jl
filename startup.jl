using Pkg
Pkg.activate(".")
using Revise
using AlgorithmAnalysis

m = 1
L = 10
α = 2/(L+m)

@algorithm begin
    f = SmoothStronglyConvexFunction{Rⁿ}(m, L)
    xs = first_order_stationary_point(f)
    fs = f(xs)
    
    x0 = Rⁿ()
    x1 = x0 - α * f'(x0)
    x0 => x1

    performance = (x0 - xs)^2
end

objs = connected_components(performance)

types = Set( typeof(x) for x in objs )
