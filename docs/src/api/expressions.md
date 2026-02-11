
```@docs
Expression
```

## Abstract expression types

```@docs
AbstractVectorSpace
Field
VectorSpace
NormedVectorSpace
InnerProductSpace
```

## Methods

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
evaluate
⊆
⊗
```

## Macros to create types of expressions

```@docs
@field
@randomfield
@vectorspace
@normedvectorspace
@innerproductspace
@randominnerproductspace
```

## Concrete expression types

```@docs
R
Rⁿ
Rᵐ
RandomR
RandomRⁿ
Gram
```