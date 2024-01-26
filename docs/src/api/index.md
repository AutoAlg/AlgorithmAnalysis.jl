# API

## General

```@docs
label
label!
@autolabel
```

## Expressions

```@docs
Expression
Field
R
@field
VectorSpace
@vectorspace
NormedVectorSpace
@normedvectorspace
InnerProductSpace
@innerproductspace
GramMatrix
⊗
variables
```

## Constraints

```@docs
Constraint
ConstraintSet
add_constraint!
check
prune!
constraints
```

## Oracles

```@docs
Oracle
Operator
Map
ConstantMap
Relation
LinearMap
Functional
oracle
suboracle
samples
sample
```

## Properties

```@docs
Property
Linear
allproperties
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