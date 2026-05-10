![Algorithm Analysis](/docs/src/assets/logo-with-title-dark.svg)

[![Build Status](https://github.com/vanscoy/AlgorithmAnalysis.jl/actions/workflows/CI.yml/badge.svg?branch=master)](https://github.com/vanscoy/AlgorithmAnalysis.jl/actions/workflows/CI.yml?query=branch%3Amaster)
[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://vanscoy.github.io/AlgorithmAnalysis.jl/stable)

AlgorithmAnalysis.jl is a Julia package for the automated analysis of algorithms.

This package provides a generic way to analyze algorithms in a systematic manner in the [Julia programming language](https://julialang.org/). Algorithm analysis seeks to find a mathematically proven guarantee of an algorithm's performance over a class of problems. AlgorithmAnalysis.jl includes both the performance estimation (PEP) and control theoretic methodologies to analysis.

## Installation

The package can be downloaded from GitHub and imported with:
```julia
import Pkg
Pkg.add("AlgorithmAnalysis")
```

## Example

This example code finds the worst-case performance guarantee of the gradient descent algorithm at minimizing $L$-smooth and $m$-strongly convex functions.

```julia
using AlgorithmAnalysis
m, L = 1, 10
@algorithm begin
    f = DifferentiableFunctional{Rⁿ}()
    xs = first_order_stationary_point(f)
    f ∈ SmoothStronglyConvex(m, L)
    x0 ∈ Rⁿ
    x0 => x0 - (1/L) * f'(x0)
    performance = (x0 - xs)^2
end
rate(performance)
```