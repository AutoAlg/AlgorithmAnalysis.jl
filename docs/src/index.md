```@raw html
<style>
  /* Default / Light theme */
  .logo-dark { display: none !important; }
  .logo-light { display: inline-block !important; }

  /* Documenter Dark theme */
  html.theme--documenter-dark .logo-dark { display: inline-block !important; }
  html.theme--documenter-dark .logo-light { display: none !important; }
</style>

<img class="logo-light" src="assets/logo-with-title-light.png" alt="AlgorithmAnalysis.jl Logo">
<img class="logo-dark" src="assets/logo-with-title-dark.png" alt="AlgorithmAnalysis.jl Logo">
```

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

This example code finds the worst-case convergence rate of the (squared) distance to optimality of the gradient descent algorithm at minimizing $L$-smooth and $\mu$-strongly convex functions.

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

## Documentation structure

- **Manual:** describes the data structures used by AlgorithmAnalysis.jl

- **API:** a comprehensive list of all public objects exported by AlgorithmAnalysis.jl

- **Developer Guide:** helps get researchers started in how to contribute novel algorithms or analysis techniques

## License

The software is licensed under the [MIT License](https://opensource.org/license/mit).

## Acknowledgement

This material is based upon work supported by the National Science Foundation under [Award No. 2347121](https://www.nsf.gov/awardsearch/show-award/?AWD_ID=2347121). Any opinions, findings and conclusions or recommendations expressed in this material are those of the author(s) and do not necessarily reflect the views of the National Science Foundation.
