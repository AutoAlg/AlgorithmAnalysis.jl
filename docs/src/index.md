# AlgorithmAnalysis.jl

This package provides a generic way to analyze optimization algorithms in a systematic manner in the [Julia programming language](https://julialang.org/). Algorithm Analysis seeks to find a mathematically proven guarantee of an algorithm's performance optimizing a set of functions. AlgorithmAnalysis.jl includes the PEP framework and the Lyapunov-based approach to analysis. 

## Installation

The package relies on the following Julia packages:
- JuMP
- SCS (or any JuMP supported solvers)
- LinearAlgebra
- InteractiveUtils
- AbstractTrees
- Zeros
- MathOptInterface

The package can be downloaded from GitHub and imported with:
```julia
import Pkg
Pkg.add("AlgorithmAnalysis")
```

## Example

This example code finds the worst-case performance guarantee of the gradient descent algorithm with step size 2/11 at optimizing 1 smooth 10 strongly convex functions.

```julia
using AlgorithmAnalysis
m, L = 1, 10
α = 2/(L+m)
@algorithm begin
    f = DifferentiableFunctional{Rⁿ}()
    xs = first_order_stationary_point(f)
    f ∈ SmoothStronglyConvex(m, L)
    x0 = Rⁿ()
    x1 = x0 - α*f'(x0)
    x0 => x1
    performance = (x0-xs)^2
end
@show rate(performance)
```
