############################################################################################
# Abstract types

"""
    Expression

An abstract expression.

An expression can be a constant (nonzero or zero), a variable (with known or unknown value), or a wrapper of other expressions.

Some subtypes are [`Field`](@ref), [`VectorSpace`](@ref), and [`GramMatrix`](@ref).
"""
abstract type Expression end

"""
    Field <: Expression

An abstract field.

An element of a field is a scalar. A scalar is an expression that can be an affine function of other scalars and inner products of points in an inner product space over the field.

Use [`@field]`](@ref) to construct a field.
"""
abstract type Field <: Expression end

"""
    VectorSpace{F<:Field} <: Expression

An abstract vector space.

A vector is an expression that can be a linear function of other vectors.
"""
abstract type VectorSpace{F<:Field} <: Expression end

"""
    NormedVectorSpace{F<:Field} <: VectorSpace{F}

An abstract normed vector space. The squared norm of a vector produces a scalar.
"""
abstract type NormedVectorSpace{F<:Field} <: VectorSpace{F} end

"""
    InnerProductSpace{F<:Field} <: NormedVectorSpace{F}

An abstract inner product space. The inner product of two vectors produces a scalar, and the squared norm is the inner product of a vector with itself.
"""
abstract type InnerProductSpace{F<:Field} <: NormedVectorSpace{F} end

"""
    Constraint

An abstract constraint that consists of an [`Expression`](@ref) belonging to a [`ConstraintSet`](@ref).

Concrete subtypes should provide methods for `expression`, `set`, `∈`, `isequal`, and `check`.
"""
abstract type Constraint end

"""
    ConstraintSet

An abstract set for use in a [`Constraint`](@ref).
"""
abstract type ConstraintSet end

"""
    Oracle

An oracle is a set of operators and the ways in which they are related. For instance, an oracle may consist of the operators A and Aᵀ where A is linear and Aᵀ is its tranpose. Each operator can be sampled at a point in its domain, and it can have a set of properties.

Any concrete subtype of `Oracle` must have the following fields:
    label::String
    properties::Properties

Some concrete oracles are [`LinearMap`](@ref), [`Functional`](@ref), etc.
"""
abstract type Oracle end

"""
    Wrapper

Generic wrapper for an object of type `T`.
"""
abstract type Wrapper{T} end


############################################################################################
# Oracles

abstract type AbstractOperator{X,Y} <: Oracle end
abstract type AbstractFunction{X,Y} <: AbstractOperator{X,Y} end
abstract type AbstractLinearMap{X,Y} <: AbstractFunction{X,Y} end
abstract type AbstractSymmetricLinearMap{X} <: AbstractLinearMap{X,X} end
abstract type AbstractSkewSymmetricLinearMap{X} <: AbstractLinearMap{X,X} end
abstract type AbstractFunctional{X} <: AbstractFunction{X,F where F} end
abstract type AbstractSubdifferentiableFunctional{X} <: AbstractFunctional{X} end
abstract type AbstractDifferentiableFunctional{X} <: AbstractSubdifferentiableFunctional{X} end
abstract type AbstractTwiceDifferentiableFunctional{X} <: AbstractDifferentiableFunctional{X} end
abstract type AbstractInfinitelyDifferentiableFunctional{X} <: AbstractTwiceDifferentiableFunctional{X} end
abstract type AbstractLinearFunctional{X} <: AbstractInfinitelyDifferentiableFunctional{X} end


############################################################################################
# Properties of oracles

"""
    Property{T}

Property of objects of type `T`.
"""
abstract type Property end

# abstract type OnePointProperty <: Property end
# abstract type TwoPointProperty <: Property end
# abstract type AllPointProperty <: Property end

abstract type OperatorProperty <: Property end
abstract type FunctionProperty <: Property end

abstract type InnerProductSpaceProperty <: OperatorProperty end
abstract type NormedVectorSpaceProperty <: OperatorProperty end
abstract type Monotonicity <: InnerProductSpaceProperty end
abstract type RelativeBoundedness <: NormedVectorSpaceProperty end
abstract type Boundedness <: NormedVectorSpaceProperty end
abstract type LinearMapProperty <: Property end
abstract type SquareLinearMapProperty <: Property end
abstract type FunctionalProperty <: Property end


############################################################################################
# Constants

# A set of oracles
const Oracles = Set{Oracle}

# A set of constraints
const Constraints = Set{Constraint}

# A set of properties
const Properties = Set{Property}

# An oracle or a wrapper of an oracle
const OracleOrWrapper = Union{Oracle, Wrapper{<:Oracle}}
