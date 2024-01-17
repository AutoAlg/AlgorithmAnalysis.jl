# BlackBoxOptimization.jl

This Julia package provides a generic way to analyze optimization algorithms in a systematic manner.

```@contents
Depth = 2
```


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

## Basic Types

```@contents
Pages = ["expression.md", "oracle.md"]
Depth = 1
```

## Precompilation

For faster compilation times (for developers), you can build a custom system image.

```julia
using PackageCompiler
PackageCompiler.create_sysimage(
    [
        :Convex,
        :SCS,
        :LinearAlgebra,
    ];
    precompile_execution_file = "src/precompilation/precompile.jl",
    sysimage_path = "image.so",
)
```

Then start Julia with the -J flag pointing to the system image that was created, [see here for details](https://julialang.github.io/PackageCompiler.jl/dev/sysimages.html#Creating-a-sysimage-using-PackageCompiler). To have VSCode automatically load this system image, add the following to `settings.json`:
```json
"julia.additionalArgs": [
    "-Jpath_to_image.so"
]
```


## API

```@docs
VectorSpace
samples
@field
Field
Gradient
oracle
@normedvectorspace
weights
Constraints
Linearity
Hessian
operator
variables
Subdifferential
@vectorspace
Oracle
GramMatrix
Decomposition
prune!
linear
Transpose
Expression
constant
LinearDecomposition
Constraint
NormedVectorSpace
@autolabel
@innerproductspace
InnerProductSpace
adjoint
hash
⊗
∈
isempty
AffineDecomposition
Oracles
BlackBoxOptimization
Union
add_constraint!
hierarchy
```