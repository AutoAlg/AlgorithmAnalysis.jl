# Gradient Descent

## Mathematical Background

Gradient Descent is a fundamental algorithm used for convergence.


Mathematically, it is an algorithm that efficiently finds ``x^* = \arg\min f(x)``
where ``f`` is some function which is differentable with a gradient ``\nabla f(x)``.


The algorithm can be iteratively detailed as
``x_{k+1} = x_k - \alpha \nabla f(x_k)`` where ``x_k`` is the value of the
``k``th iteration of the algorithm and ``\alpha`` is a step size parameter that
can be used to adjust the convergence rate of the algorithm.


## Implementation within AlgorithmAnalysis.jl

Within our framework, this can be implemented as follows, over the basic classes


```julia
function GD(m, L, prev_rate=0)
    α = 2 / (L + m)
    @algorithm begin
        f = DifferentiableFunctional{Rⁿ}()
        xs = first_order_stationary_point(f)
        f' ∈ SectorBounded(m, L, xs, f'(xs))
        x0 = Rⁿ()
        x1 = x0 - α * f'(x0)
        x0 => x1
        performance = (x0 - xs)^2
    end
    @show rate(performance, prev_rate)
end
```

where the previously stated ``f`` is a $L$-smooth and $m$-strongly convex
function. Given the function class,


 Convex and Differentantable functin
$L$-smooth and $m$-strongly convex functions.

### Reasonable output

TODO, 