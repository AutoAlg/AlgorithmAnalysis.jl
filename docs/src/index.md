# BlackBoxOptimization.jl

This package provides a generic way to analyze optimization algorithms in a systematic manner using the [Julia programming language](https://julialang.org/).

## Installation

```julia
import Pkg; Pkg.add("BlackBoxOptimization")
```

## Quick Example

```julia
using BlackBoxOptimization

@field R
@innerproductspace Rⁿ, R

A = LinearMap{Rⁿ,Rᵐ}()
A ∈ RelativelyBounded{1,10}()
```
