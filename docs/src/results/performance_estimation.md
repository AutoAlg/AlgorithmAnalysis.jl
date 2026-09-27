# Performance Estimation Gradient Descent

For gradient descent over an ``L``-smooth convex function, a common choice for the step size parameter ``\alpha`` is ``\alpha = \frac{1}{L}``.

Additionally, provided that ``\alpha \leq \frac{1}{L}`` it can be shown that ``f(x⁺) - f(xs) \leq \frac{L}{4LN\alpha + 2} \cdot ||x - xs||^2`` where ``N`` is the number of PEP iterations.
However, in this simple demonstration, we only show one iteration.

Internally this is implemented by rewriting the constraints on the optimization problem in terms of inner products, and then using a Gram matrix.

Using the performance estimation method we are able to provide a bounded convergence rate for a fixed number of steps. 
For an in depth explanation, see [Performance Estimation](./../manual/pep.md)

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

with_numerics(T=BigFloat, parameters=Dict(α => big"0.075", L => big"10.0")) do
    @test evaluate(topt) ≈ 2.0
end
``` 
## References
- Laurent Lessard, Benjamin Recht and Andrew Packard. *Analysis and Design of Optimization Algorithms via Integral Quadratic Constraints*. 2016. [doi:10.1137/15M1009597](https://doi.org/10.1137/15M1009597)

- Yoel Drori and Marc Teboulle. *Performance of first-order methods for smooth convex minimization: a novel approach*. 2013. [doi:10.1007/s10107-013-0653-0](https://doi.org/10.1007/s10107-013-0653-0)

