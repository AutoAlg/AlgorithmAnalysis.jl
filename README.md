![Algorithm Analysis Logo](/docs/src/assets/logo-with-title-dark.svg)

[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://AutoAlg.github.io/AlgorithmAnalysis.jl/dev/)
[![CI](https://github.com/AutoAlg/AlgorithmAnalysis.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/AutoAlg/AlgorithmAnalysis.jl/actions/workflows/CI.yml)

AlgorithmAnalysis.jl is a Julia package for the automated analysis of algorithms.

This package provides a generic way to analyze algorithms in a systematic manner in the [Julia programming language](https://julialang.org/). Algorithm analysis seeks to find a mathematically proven guarantee of an algorithm's performance over a class of problems. AlgorithmAnalysis.jl includes both the performance estimation (PEP) and control theoretic methodologies to analysis.

## Installation

The package can be downloaded from GitHub and imported with:
```julia
import Pkg; Pkg.add("AlgorithmAnalysis")
```

!!! tip
    By default, AlgorithmAnalysis uses [Clarabel](https://clarabel.org/) and [Hypatia](https://jump.dev/Hypatia.jl/) to solve convex cone programs. If you would like to use a different solver (such as [Mosek](https://www.mosek.com/)), you will need to install that as well.

## Example

This example code finds the worst-case convergence rate of the (squared) distance to optimality of the gradient descent algorithm at minimizing $L$-smooth and $m$-strongly convex functions.

```julia
using AlgorithmAnalysis

@alg begin
    α, μ, L, ρ ∈ R
    x, xs ∈ Rⁿ
    f ∈ F(Rⁿ)
    gs = f'(xs)
    g  = f'(x)
    x₊ = x - α * g
    t1 = x → x₊
    t2 = xs → xs
    t3 = (f → f) ∧ (f' → f')
    c1 = sector_bounded(f, μ, L)
    c2 = gs^2 == zero(R)
    con = t1 ∧ t2 ∧ t3 ∧ c1 ∧ c2
    perf = (x - xs)^2
    opt = rate(con, perf)
end

with_parameters(Dict(α => 0.1, μ => 1.0, L => 10.0)) do
    
    transformed_opt = simplify(opt)

    evaluate(transformed_opt) ≈ 0.81
end
```

## Documentation structure

- **Developer Guide:** helps get researchers started in how to contribute novel algorithms or analysis techniques

- **Manual:** describes the data structures used by AlgorithmAnalysis.jl

- **API:** a comprehensive list of all public objects exported by AlgorithmAnalysis.jl

- **Results:** illustrate the analyses on a variety of algorithms and problem classes
