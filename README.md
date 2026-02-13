# AlgorithmAnalysis.jl

![Algorithm Analysis Logo](docs/src/assets/logo.png)

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

> [!TIP]
> By default, AlgorithmAnalysis uses [SCS](https://www.cvxgrp.org/scs/) to solve convex cone programs. If you would like to use a different solver (such as [Mosek](https://www.mosek.com/)), you will need to install that as well.

## Example

This example code finds the worst-case performance guarantee of the gradient descent algorithm at minimizing $L$-smooth and $m$-strongly convex functions.

```julia
using AlgorithmAnalysis
m, L = 1, 10
α = 2 / (L + m)
@algorithm begin
    f = DifferentiableFunctional{Rⁿ}()
    xs = first_order_stationary_point(f)
    f' ∈ SectorBounded(m, L, xs, f'(xs))
    x0 ∈ Rⁿ
    x1 = x0 - α * f'(x0)
    x0 => x1
    performance = (x0 - xs)^2
end
@show rate(performance)
```