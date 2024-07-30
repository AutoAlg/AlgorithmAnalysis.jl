############################################################################################
# Abstract types

"""
    Expression

An abstract expression.

An expression can be a constant (nonzero or zero), a variable (with known or unknown value), or a decomposition of other expressions.

A subtype is [`AbstractVectorSpace`](@ref).
"""
abstract type Expression end

"""
    AbstractVectorSpace <: Expression

An abstract vector space.

Some subtypes are [`Field`](@ref) and [`VectorSpace`](@ref).
"""
abstract type AbstractVectorSpace <: Expression end

"""
    Field <: AbstractVectorSpace

An abstract field.

An element of a field is a scalar. A scalar is an expression that can be an affine function of other scalars and inner products of points in an inner product space over the field.

Use [`@field]`](@ref) to construct a field.
"""
abstract type Field <: AbstractVectorSpace end

"""
    VectorSpace{F<:Field} <: Expression

An abstract vector space.

A vector is an expression that can be a linear function of other vectors.
"""
abstract type VectorSpace{F<:Field} <: AbstractVectorSpace end

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

An oracle is a relation between pairs of expressions. Oracles may be sampled at expressions in their domain to produce output expressions in their codomain. Oracles may also have other associated oracles; for instance, a linear operator has an associated adjoint. Each operator can be sampled at a point in its domain, and it can have a set of properties.

Any concrete subtype of `Oracle` must have the following fields:
    label::String
    properties::Properties

Some concrete oracles are [`LinearMap`](@ref), [`Functional`](@ref), etc.
"""
abstract type Oracle end

"""
    Wrapper{T}

Wrapper for an object of type `T`.

Every concrete subtype must have a field `parent::T` that stores the object being wrapped.
"""
abstract type Wrapper{T} end

"""
    Decomposition{T}

Decomposition of an object of type `T` in terms of other objects.
"""
abstract type Decomposition{T} end


############################################################################################
# Oracles

abstract type AbstractOperator{X,Y} <: Oracle end
abstract type AbstractFunction{X,Y} <: AbstractOperator{X,Y} end
abstract type AbstractLinearMap{X,Y} <: AbstractFunction{X,Y} end
abstract type AbstractSymmetricLinearMap{X} <: AbstractLinearMap{X,X} end
abstract type AbstractSkewSymmetricLinearMap{X} <: AbstractLinearMap{X,X} end
abstract type AbstractFunctional{X} <: AbstractFunction{X,F where F} end
abstract type AbstractLocallyLipschitzFunctional{X} <: AbstractFunctional{X} end
abstract type AbstractSubdifferentiableFunctional{X} <: AbstractLocallyLipschitzFunctional{X} end
abstract type AbstractDifferentiableFunctional{X} <: AbstractLocallyLipschitzFunctional{X} end
abstract type AbstractTwiceDifferentiableFunctional{X} <: AbstractDifferentiableFunctional{X} end
abstract type AbstractInfinitelyDifferentiableFunctional{X} <: AbstractTwiceDifferentiableFunctional{X} end
abstract type AbstractLinearFunctional{X} <: AbstractInfinitelyDifferentiableFunctional{X} end


############################################################################################
# Decompositions

abstract type AbstractLinearDecomposition{T} <: Decomposition{T} end


############################################################################################
# Properties of oracles

"""
    Property{T}

Property of objects of type `T`.
"""
abstract type Property{T} end

# abstract type OnePointProperty <: Property end
# abstract type TwoPointProperty <: Property end
# abstract type AllPointProperty <: Property end

# abstract type OperatorProperty <: Property end
# abstract type FunctionProperty <: Property end

# abstract type InnerProductSpaceProperty <: OperatorProperty end
# abstract type NormedVectorSpaceProperty <: OperatorProperty end
# abstract type Monotonicity <: InnerProductSpaceProperty end
# abstract type RelativeBoundedness <: NormedVectorSpaceProperty end
# abstract type Boundedness <: NormedVectorSpaceProperty end
# abstract type LinearMapProperty <: Property end
# abstract type SquareLinearMapProperty <: Property end
# abstract type FunctionalProperty <: Property end


############################################################################################
# Constants

# A set of expressions
# const Variables = Set{Variable}

# A set of oracles
const Oracles = Set{Oracle}

# A set of constraints
const Constraints = Set{Constraint}

# A set of properties
const Properties = Set{Property}

# An oracle or a wrapper of an oracle
const OracleOrWrapper = Union{Oracle, Wrapper}

# A dictionary of associations between wrappers and oracles
const Associations = Dict{Type{<:Wrapper}, Oracle}

# An expression is a variable or a decomposition of variables
# const Expression = Union{Variable, Decomposition{<:Variable}}

# A vector or a decomposition of vectors
const VectorExpression = Union{AbstractVectorSpace, Decomposition{<:AbstractVectorSpace}}

# A vector or a wrapper of a vector
const VectorOrWrapper = Union{AbstractVectorSpace, Wrapper{<:AbstractVectorSpace}}

const VectorWrapperDecomposition = Union{AbstractVectorSpace, Decomposition{<:AbstractVectorSpace}, Wrapper{<:AbstractVectorSpace}, Decomposition{<:Wrapper{<:AbstractVectorSpace}}}

# A set of expressions
const Expressions = Set{Expression}

# A set of vector expressions
const VectorExpressions = Set{VectorExpression}

# The type of a next or previous state of type T
const State{T} = Union{T, Missing}

# An object of type T or a wrapper of that type
const OrWrapper{T} = Union{T, Wrapper{<:T}}

const ScalarValue{T} = Union{Number,Decomposition{T},Missing}
const VectorValue{T} = Union{Vector,Zero,Decomposition{T},Missing}

const ArrayOrSet{T} = Union{AbstractArray{<:T}, AbstractSet{<:T}}
