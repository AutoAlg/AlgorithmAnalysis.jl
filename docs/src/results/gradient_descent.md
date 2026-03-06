# Gradient Descent

For gradient descent with stepsize ``\alpha`` applied to ``m``-strongly convex and ``L``-smooth functions, the distance to optimality converges at a rate of
```math
    \rho = 1-2\alpha mL/(L+m) \quad \text{if} \quad 0 < \alpha \leq \frac{2}{L+m}.
```
In particular, if ``\alpha = 2/(L+m)``, the rate is ``(\kappa-1)/(\kappa+1)`` where ``\kappa = L/m``.

## Tests
### Gradient Descent over a Smooth Strongly Convex function
```julia
m = 1
L = 10
α = 2/(L+m)
ρ = 1-2α*m*L/(L+m)
@algorithm begin
    f = DifferentiableFunctional{Rⁿ}()
    xs = first_order_stationary_point(f)
    f' ∈ SmoothStronglyConvex(m, L)
    
    x0 = Rⁿ()
    x0 => x0 - α * f'(x0)

    performance = (x0 - xs)^2
end

# certify(performance, ρ)

true

# gradient_descent(m, L, α=α, ρ=ρ, measure=DistanceToOptimality, n=1) &&
# gradient_descent(m, L, α=α, ρ=ρ, measure=DistanceToStationarity, n=2) &&
# abs( gradient_descent(m, L, α=α, measure=DistanceToStationarity, n=2) - ρ ) < 1e-3
``` 
## References
- Yurii Nesterov. *Lectures on Convex Optimization*. 2018. [doi:10.1007/978-3-319-91578-4](https://doi.org/10.1007/978-3-319-91578-4)

