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
```

### Abstract expression types

```@docs
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
GramMatrix
```

# Macros to create other types of expressions

```@docs
@field
@vectorspace
@normedvectorspace
@innerproductspace
```

### Expression methods

```@docs
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