![Algorithm Analysis Logo](./assets/logo-with-title-dark.svg)

AlgorithmAnalysis.jl is a Julia package for the automated analysis of algorithms.

This package provides a generic way to analyze algorithms in a systematic manner in the [Julia programming language](https://julialang.org/). Algorithm analysis seeks to find a mathematically proven guarantee of an algorithm's performance over a class of problems. AlgorithmAnalysis.jl includes both the performance estimation (PEP) and control theoretic methodologies to analysis.

## Installation

The package can be downloaded from GitHub and imported with:
```julia
import Pkg
Pkg.add("AlgorithmAnalysis")
```

!!! tip
    By default, AlgorithmAnalysis uses [SCS](https://www.cvxgrp.org/scs/) to solve convex cone programs. If you would like to use a different solver (such as [Mosek](https://www.mosek.com/)), you will need to install that as well.

## Example

This example code finds the worst-case convergence rate of the (squared) distance to optimality of the gradient descent algorithm at minimizing $L$-smooth and $m$-strongly convex functions.

```julia
using AlgorithmAnalysis
m, L = 1, 10
@algorithm begin
    f = DifferentiableFunctional{Rⁿ}()
    xs = first_order_stationary_point(f)
    f' ∈ SmoothStronglyConvex(m, L)
    x0 ∈ Rⁿ
    x0 => x0 - (1/L) * f'(x0)
    performance = (x0 - xs)^2
end
rate(performance)
```

## Documentation structure

- **Developer Guide:** helps get researchers started in how to contribute novel algorithms or analysis techniques

- **Manual:** describes the data structures used by AlgorithmAnalysis.jl

- **Examples:** illustrate the analyses on a variety of algorithms and problem classes

- **API:** a comprehensive list of all public objects exported by AlgorithmAnalysis.jl
