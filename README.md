<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/src/assets/logo-with-title-dark.png">
  <source media="(prefers-color-scheme: light)" srcset="docs/src/assets/logo-with-title-light.png">
  <img alt="AlgorithmAnalysis.jl Logo" src="docs/src/assets/logo-with-title-light.png">
</picture>

[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://AutoAlg.github.io/AlgorithmAnalysis.jl/dev/)
[![CI](https://github.com/AutoAlg/AlgorithmAnalysis.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/AutoAlg/AlgorithmAnalysis.jl/actions/workflows/CI.yml)
[![DOI](https://img.shields.io/badge/DOI-10.5281/zenodo.22837128-blue)](https://doi.org/10.5281/zenodo.22837128)

AlgorithmAnalysis.jl is a [Julia](https://julialang.org/) package for the automated analysis of algorithms. This package enables users to specify algorithms and their analyses in a domain specific language, transform problems symbolically, and then solve the simplified problem numerically to obtain a mathematical bound on the performance of the algorithm. AlgorithmAnalysis.jl includes both the performance estimation (PEP) and control theoretic (Lyapunov-based) methodologies to analysis. To learn more, see the [documentation](https://AutoAlg.github.io/AlgorithmAnalysis.jl/dev/).

## Installation

The package can be installed using the Julia package manager:
```julia
import Pkg; Pkg.add("AlgorithmAnalysis")
```

## Example

This example code finds the worst-case convergence rate of the (squared) distance to optimality of the gradient descent algorithm at minimizing L-smooth and μ-strongly convex functions.

```julia
using AlgorithmAnalysis

@alg begin

    # variables
    α, μ, L, ρ ∈ R
    x, xs ∈ Rⁿ
    f ∈ differentiable_functional(Rⁿ)

    # algorithm update
    x₊ = x - α * f'(x)

    # state transitions
    trans = (x → x₊) ∧ (xs → xs)

    # constraints
    c1 = smooth_strongly_convex(f, μ, L)
    c2 = f'(xs)^2 == zero(R)
    con = c1 ∧ c2

    # performance measure
    perf = (x - xs)^2
    perf₊ = (x₊ - xs)^2

    # performance estimation problem
    pep = maximize(perf₊, con ∧ (perf ≤ 1))

    # Lyapunov-based stability certification
    cert = certify(ρ, perf, con ∧ trans)

    # optimal rate that is certifiable (using bisection)
    ρopt = rate(perf, con ∧ trans)
end

with_numerics(parameters = Dict(α => 0.1, μ => 1.0, L => 10.0)) do

    isapprox(evaluate(simplify(pep)), 0.81, atol=1e-6)  # true
end

with_numerics(parameters = Dict(α => 0.1, μ => 1.0, L => 10.0, ρ => 0.81000001)) do

    evaluate(simplify(cert))  # true
end

with_parameters(Dict(α => 0.1, μ => 1.0, L => 10.0)) do
    
    ρopt_simplified = simplify(ρopt)

    evaluate(ρopt_simplified) ≈ 0.81  # true
end
```

## License

The software is licensed under the [MIT License](https://opensource.org/license/mit).

## Acknowledgements

This material is based upon work supported by the National Science Foundation under [Award No. 2347121](https://www.nsf.gov/awardsearch/show-award/?AWD_ID=2347121). Any opinions, findings and conclusions or recommendations expressed in this material are those of the author(s) and do not necessarily reflect the views of the National Science Foundation.
