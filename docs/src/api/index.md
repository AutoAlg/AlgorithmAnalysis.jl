# API

## Expressions

```@docs
Expression
Field
@field
VectorSpace
@vectorspace
NormedVectorSpace
@normedvectorspace
InnerProductSpace
@innerproductspace
GramMatrix
⊗
@autolabel
variables
```

## Constraints

```@docs
Constraint
ConstraintSet
add_constraint!
check
prune!
```

## Oracles

```@docs
Oracle
Relation
LinearMap
Functional
oracle
suboracle
relation
samples
sample
```

## Properties

```@docs
Property
Linear
allproperties
```

## Interpolation

```@docs
interpolation_conditions
```

## Wrappers

```@docs
Wrapper
LinearDecomposition
AffineDecomposition
Transpose
Subdifferential
Gradient
Hessian
isempty
weights
linear
constant
unwrap
```

## Other

```@docs
adjoint
hash
hierarchy
```