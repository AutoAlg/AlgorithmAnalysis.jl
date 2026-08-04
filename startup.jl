using Pkg, Revise
Pkg.activate(".")
using AlgorithmAnalysis

# TODO
# can/should we use Real and Bool instead of R and Prop?
# distinguish between parameters (that will be instantiated) and their values

@alg begin
    α, L ∈ R, x, xs ∈ Rⁿ, f ∈ differentiable_functional(Rⁿ)

    gs   = f'(xs)
    g    = f'(x)
    init = (x - xs)^2
    x⁺   = x - α * g
    f⁺   = f(x⁺)
    c1   = smooth_convex(f, L)
    c2   = gs^2 == zero(R)
    c3   = init ≤ one(R)
    con  = c1 ∧ c2 ∧ c3
    obj  = f⁺ - f(xs)
    opt  = maximize(obj, con)
end

topt = simplify(opt)

with_numerics(parameters = Dict(α => 0.075, L => 10.0)) do
    evaluate(topt)
end
