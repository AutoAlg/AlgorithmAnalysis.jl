# AlgorithmAnalysis.jl

AlgorithmAnalysis.jl is a Julia package for the automated analysis of algorithms.

This package provides a generic way to analyze algorithms in a systematic manner in the [Julia programming language](https://julialang.org/). Algorithm analysis seeks to find a mathematically proven guarantee of an algorithm's performance over a class of problems. AlgorithmAnalysis.jl includes both the performance estimation (PEP) and control theoretic methodologies to analysis.

## Installation

The package can be downloaded from GitHub and imported with:
```julia
import Pkg
Pkg.add("AlgorithmAnalysis")
```

!!! tip
    By default, AlgorithmAnalysis uses the SCS solver to solve cone programs. If you would like to use a different solver (such as Mosek), you will need to install that as well.

## Example

This example code finds the worst-case performance guarantee of the gradient descent algorithm at minimizing $L$-smooth and $m$-strongly convex functions.

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

## Documentation structure

- **Manual:** describes the data structures used by AlgorithmAnalysis.jl

- **Examples:** illustrate the analyses on a variety of algorithms and problem classes

- **API:** a comprehensive list of all public objects exported by AlgorithmAnalysis.jl

- **Developer Guide:** helps get researchers started in how to contribute novel algorithms or analysis techniques