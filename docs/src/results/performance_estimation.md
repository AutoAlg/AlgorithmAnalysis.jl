# Gradient Descent via the Performance Estimation method

Using the performance estimation method we are able to provide a bounded convergence rate for a fixed number of steps. 
For an in depth explanation, see [Lyapunov Analysis](./../manual/lyap.md)

## Tests
### Performance estimation
```julia
@alg begin
    α, L ∈ R, x, xs ∈ Rⁿ, f ∈ differentiable_functional(Rⁿ)

    gs = f'(xs)
    g = f'(x)
    init = (x - xs)^2
    x⁺ = x - α * g
    f⁺ = f(x⁺)
    c1 = smooth_convex(f, L)
    c2 = gs^2 == zero(R)
    c3 = init ≤ one(R)
    con = c1 ∧ c2 ∧ c3
    obj = f⁺ - f(xs)
    opt = maximize(obj, con)
end

topt = simplify(opt)

return with_numerics(T=BigFloat, parameters=Dict(α => big"0.075", L => big"10.0")) do
    evaluate(topt) ≈ 2.0
end
``` 
