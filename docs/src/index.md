![Algorithm Analysis Logo](./assets/logo-with-title-dark.svg)

[AlgorithmAnalysis.jl](https://github.com/AutoAlg/AlgorithmAnalysis.jl) is a Julia package for the automated analysis of algorithms.

This package provides a generic way to analyze algorithms in a systematic manner in the [Julia programming language](https://julialang.org/). Algorithm analysis seeks to find a mathematically proven guarantee of an algorithm's performance over a class of problems. AlgorithmAnalysis.jl includes both the performance estimation (PEP) and control theoretic methodologies to analysis.

## Installation

The package can be installed using the Julia package manager:
```julia
import Pkg; Pkg.add("AlgorithmAnalysis")
```

!!! tip
    By default, AlgorithmAnalysis.jl uses [Clarabel](https://clarabel.org/) and [Hypatia](https://jump.dev/Hypatia.jl/) to numerically solve optimization problems. If you would like to use a different solver (such as any of the [solvers supported by JuMP](https://jump.dev/JuMP.jl/stable/installation/#Supported-solvers)), you will need to install that as well.

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

## License

The software is licensed under the [MIT License](https://opensource.org/license/mit).

## Acknowledgement

This material is based upon work supported by the National Science Foundation under [Award No. 2347121](https://www.nsf.gov/awardsearch/show-award/?AWD_ID=2347121). Any opinions, findings and conclusions or recommendations expressed in this material are those of the author(s) and do not necessarily reflect the views of the National Science Foundation.
