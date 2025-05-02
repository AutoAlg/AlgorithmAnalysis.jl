# API

## Expressions


```@docs
Expression
```

### Abstract expression types

```@docs
AbstractVectorSpace
Field
VectorSpace
NormedVectorSpace
InnerProductSpace
```

### Concrete expression types

```@docs
R
Rⁿ
Rᵐ
Gram
```

### Macros to create types of expressions

```@docs
@field
@vectorspace
@normedvectorspace
@innerproductspace
```

### Expression methods

```@docs
constraints
oracles
associations
isvariable
iszero
hasdecomposition
hasvalue
decomposition
value
value!
variables
selfdecomp
next!
next
update!
weights
size
length
evaluate
⊂
⊆
⊗
```

## Label

```@docs
label
label!
description
defaultlabel
@algorithm
```

## Constraints

```@docs
Constraint
ConstraintSet

add_constraint!
Satisfied
Unsatisfied
Cone
PositiveSemidefiniteCone
PositiveOrthant
ZeroSet
ConeConstraint
Positive
Semidefinite
Equality
∈
expression
set
cone
==
≤
≥
⪯
⪰
check
prune!
```

## Oracles

```@docs
Oracle
Operator
Map
ConstantMap
LinearMap
SymmetricLinearMap
SkewSymmetricLinearMap
Functional
SubdifferentiableFunctional
DifferentiableFunctional
TwiceDifferentiableFunctional
QuadraticFunctional
LinearFunctional
ZeroFunctional
relation
samples
sample
```

## Relation
```@docs
Relation
```

## Properties

```@docs
Property
Linear
RelativelyBounded
Monotone
SmoothStronglyConvex
PointwiseQuadraticConstraint
IncrementalQuadraticConstraint
TwoPointLinearQuadraticConstraint
SlopeRestricted
SectorBounded
quadraticform
linearquadraticform
reference
```


## Wrappers

```@docs
Wrapper
Decomposition
EmptyDecomposition
LinearDecomposition
# AffineDecomposition
Transpose
Subdifferential
Gradient
Hessian
# Adjoint
isempty
# linear
# constant
unwrap
```


## Other

```@docs
adjoint
hash
hierarchy
ConstantRelation
SingleValuedRelation
MultiValuedRelation
Dual
```

### Analysis methods
```@docs
bsmin
variables_constraints_oracles
```

