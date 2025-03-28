############################################################################################
# ABSTRACT TYPES
############################################################################################

"""
    Object

An algorithmic object.
"""
abstract type Object end

"""
    Space

A set of mathematical objects with a (possibly empty) set of structures.
"""
abstract type Space <: Object end

"""
    Expression{T}

An abstract expression.

Each expression either has a value, is a variable, or has a decomposition in terms of other expressions.

A subtype is [`AbstractVectorSpace`](@ref).
"""
abstract type Expression{T<:Space} <: Object end

"""
    Constraint

An abstract constraint that consists of an [`Expression`](@ref) belonging to a [`ConstraintSet`](@ref).

Concrete subtypes should provide methods for `expression`, `set`, `∈`, `isequal`, and `check`.
"""
abstract type Constraint <: Object end

"""
    ConstraintSet

An abstract set for use in a [`Constraint`](@ref).
"""
abstract type ConstraintSet <: Object end

"""
    Operator

An operator is a relation between pairs of expressions. Operators may be sampled at expressions in their domain to produce output expressions in their codomain. Operators may also have other associated operators; for instance, a linear operator has an associated adjoint. Each operator can be sampled at a point in its domain, and it can have a set of properties.

Any concrete subtype of `Operator` must have the following fields:
    label::String
    properties::Properties

Some concrete operators are [`LinearMap`](@ref), [`Functional`](@ref), etc.
"""
abstract type Operator{X<:Space, Y<:Space} <: Space end

"""
    Wrapper{T}

Wrapper for an object of type `T`.

Every concrete subtype must have a field `parent::T` that stores the object being wrapped, and the parent object must have a dictionary in the field `associations` whose key is the type of wrapper and whose value is the object being wrapped.
"""
abstract type Wrapper{T} <: Object end

"""
    Decomposition{T}

Decomposition of an object of type `T` in terms of other objects.
"""
abstract type Decomposition{T} <: Expression{T} end

abstract type CanonicalDecomposition{T} <: Decomposition{T} end

"""
    Relation{X,Y}

A relation is a subset of the product space Element{X} × Element{Y}.
"""
abstract type Relation{X,Y} end

############################################################################################
# SPACES
############################################################################################

struct CartesianProduct{T<:Tuple{Vararg{Space}}} <: Space end

const CartesianPower{T, N} = CartesianProduct{NTuple{N,T}}

spaces(::Type{CartesianProduct{T}}) where T = T

×(::Type{T}, ::Type{T}) where {T<:Space} = CartesianPower{T, 2}
×(::Type{CartesianPower{N, T}}, ::Type{T}) where {N<:Int, T<:Space} = CartesianPower{T, N+1}
×(::Type{T}, ::Type{CartesianPower{N, T}}) where {N<:Int, T<:Space} = CartesianPower{T, N+1}
×(::Type{CartesianPower{N1, T}}, ::Type{CartesianPower{N2, T}}) where {N1<:Int, N2<:Int, T<:Space} =
    CartesianPower{T, N1+N2}

×(::Type{T1}, ::Type{T2}) where {T1<:Space, T2<:Space} = CartesianProduct{Tuple{T1,T2}}
×(::Type{T1}, ::Type{T2}) where {T3, T1<:CartesianProduct{T3}, T2<:Space} = CartesianProduct{Tuple{fieldtypes(T3)...,T2}}
×(::Type{T1}, ::Type{T2}) where {T3, T1<:Space, T2<:CartesianProduct{T3}} = CartesianProduct{Tuple{T1,fieldtypes(T3)...}}
×(::Type{T1}, ::Type{T2}) where {T3, T4, T1<:CartesianProduct{T3}, T2<:CartesianProduct{T4}} = CartesianProduct{Tuple{fieldtypes(T3)...,fieldtypes(T4)...}}


############################################################################################
# Iteration over Cartesian product and power spaces

isempty(::Type{CartesianProduct{T}}) where T = iszero(length(T))
length(::Type{<:CartesianProduct{T}}) where T = fieldcount(T)
iterate(x::Type{<:CartesianProduct{T}}) where T = iterate(x,1)
function iterate(x::Type{<:CartesianProduct{T}}, state::Int) where T
    state > length(x) ? nothing : ( spaces(x).types[state], state+1 )
end

isempty(::Expression{<:CartesianProduct{T}}) where T = iszero(length(T))
length(::Expression{<:CartesianProduct{T}}) where T = length(T)
iterate(x::Expression{<:CartesianProduct{T}}) where T = iterate(x,1)
function iterate(x::Expression{<:CartesianProduct{T}}, state::Int) where T
    state > length(x) ? nothing : ( value(x)[state], state+1 )
end

isempty(x::Expression{<:CartesianPower}) = iszero(length(value(x)))
length(x::Expression{<:CartesianPower}) = length(value(x))
iterate(x::Expression{<:CartesianPower}) = iterate(x,1)
function iterate(x::Expression{<:CartesianPower}, state::Int)
    state > length(x) ? nothing : ( value(x)[state], state+1 )
end

length(::Type{T}) where {T<:Tuple} = length(T.types)


abstract type Ring <: Space end

"""
    Field <: Space

An abstract field.

An element of a field is a scalar. A scalar is an expression that can be an affine function of other scalars and inner products of points in an inner product space over the field.

Use [`@field]`](@ref) to construct a field.
"""
abstract type Field <: Ring end

"""
    VectorSpace{F<:Field} <: Space

An abstract vector space.

A vector is an expression that can be a linear function of other vectors.
"""
abstract type VectorSpace{F<:Field} <: Space end

"""
    NormedVectorSpace{F<:Field} <: VectorSpace{F}

An abstract normed vector space.
"""
abstract type NormedVectorSpace{F<:Field} <: VectorSpace{F} end

"""
    InnerProductSpace{F<:Field} <: NormedVectorSpace{F}

An abstract inner product space. The inner product of two vectors produces a scalar, and the squared norm is the inner product of a vector with itself.
"""
abstract type InnerProductSpace{F<:Field} <: NormedVectorSpace{F} end


############################################################################################
# OPERATORS
############################################################################################

# abstract type AbstractOperator{X,Y} <: Oracle{X,Y} end
# abstract type AbstractFunction{X,Y} <: AbstractOperator{X,Y} end
# abstract type AbstractLinearMap{X,Y} <: AbstractFunction{X,Y} end
# abstract type AbstractSymmetricLinearMap{X} <: AbstractLinearMap{X,X} end
# abstract type AbstractSkewSymmetricLinearMap{X} <: AbstractLinearMap{X,X} end
# abstract type AbstractFunctional{X} <: AbstractFunction{X,Space} end
# abstract type AbstractLocallyLipschitzFunctional{X} <: AbstractFunctional{X} end
# abstract type AbstractSubdifferentiableFunctional{X} <: AbstractLocallyLipschitzFunctional{X} end
# abstract type AbstractDifferentiableFunctional{X} <: AbstractLocallyLipschitzFunctional{X} end
# abstract type AbstractTwiceDifferentiableFunctional{X} <: AbstractDifferentiableFunctional{X} end
# abstract type AbstractInfinitelyDifferentiableFunctional{X} <: AbstractTwiceDifferentiableFunctional{X} end
# abstract type AbstractLinearFunctional{X} <: AbstractInfinitelyDifferentiableFunctional{X} end




abstract type AbstractFunction{X,Y} <: Operator{X,Y} end
abstract type LinearMap{X,Y} <: AbstractFunction{X,Y} end
abstract type SymmetricLinearMap{X} <: LinearMap{X,X} end
abstract type SkewSymmetricLinearMap{X} <: LinearMap{X,X} end
abstract type DifferentiableFunction{X,Y} <: AbstractFunction{X,Y} end

abstract type Functional{T<:VectorSpace} <: AbstractFunction{T, Field} end
abstract type LocallyLipschitzFunctional{T} <: Functional{T} end
abstract type SubdifferentiableFunctional{T} <: LocallyLipschitzFunctional{T} end
abstract type DifferentiableFunctional{T} <: LocallyLipschitzFunctional{T} end
abstract type TwiceDifferentiableFunctional{T} <: DifferentiableFunctional{T} end
abstract type LinearFunctional{T} <: DifferentiableFunctional{T} end

const Scaling{V<:VectorSpace, F<:Field} = AbstractFunction{CartesianProduct{Tuple{F,V}}, V}

const UnaryOperator{X<:Space} = AbstractFunction{X, X}
const BinaryOperator{X<:Space} = AbstractFunction{CartesianPower{X, 2}, X}
const NaryOperator{X<:Space} = AbstractFunction{CartesianPower{X}, X}

arity(::UnaryOperator) = 1
arity(::BinaryOperator) = 2
arity(::NaryOperator{X}) where X = nothing

abstract type GroupOperator{X} <: NaryOperator{X} end
abstract type Addition{X} <: GroupOperator{X} end
abstract type Multiplication{X} <: GroupOperator{X} end


############################################################################################
# DOMAIN / CODOMAIN
############################################################################################

# domain(::TypeVar) = Union{}
# codomain(::TypeVar) = Union{}

domain(::Type{<:Operator{X,Y}}) where {X,Y} = X
codomain(::Type{<:Operator{X,Y}}) where {X,Y} = Y

codomain(::Type{<:Functional{V}}) where {F<:Field, V<:VectorSpace{F}} = F

domain(e::Expression) = domain(space(e))
codomain(e::Expression) = codomain(space(e))

# domain(::Type{<:Expression{CartesianPower{T}}}) where {T, N} = NTuple{N, T}


############################################################################################
# TYPES OF SPACES
############################################################################################

isfunction(::Type{<:Space}) = false
isfunction(::Type{<:Operator}) = true

function issinglevalued(::Type{T}) where {T<:Space}
    isfunction(T) ? false : error("$T is not a function space.")
end
issinglevalued(::Type{<:AbstractFunction}) = true
issinglevalued(::Type{<:Functional}) = true

issubset(T1::Type{<:Space}, T2::Type{<:Space}) = T1 <: T2

function canevaluate(::Type{T1}, ::Type{T2}) where {T1<:Space, T2<:Space}
    isfunction(T1) && issubset(T2, domain(T1)) ? true : false
end

# isvectorspace(::Type{<:Space}) = false
# isvectorspace(::Type{<:VectorSpace}) = true
# isvectorspace(::Type{<:Field}) = true
# isvectorspace(::Type{<:LinearFunctional{<:VectorSpace}}) = true

# function isvectorspace(::Type{T1}, ::Type{T2}) where {T1<:Space, T2<:Space}
#     isvectorspace(T1) ? isequal(T2, field(T1)) : false
# end

# islinear(::Type{<:Space}) = false
# islinear(::Type{<:LinearFunctional}) = true
# islinear(::Type{<:VectorSpace}) = true
# islinear(::Type{<:Field}) = true

isfunctional(::Type{<:Space}) = false
isfunctional(::Type{<:Functional}) = true


# isgroup(::Type{<:Space}, ::Function) = false
# isgroup(::Type{<:Field}, ::typeof(+)) = true
# isgroup(::Type{<:VectorSpace}, ::typeof(+)) = true
# isgroup(::Type{<:Field}, ::typeof(*)) = true

# additiveidentity(::Type{T}) where {T<:Space} = isgroup(T, +) ? Zero{T}() : error("Space $T is not a group over addition")

# multiplicativeidentity(::Type{T}) where {T<:Space} = isgroup(T, *) ? One{T}() : error("Space $T is not a group over multiplication")

# isring(::Type{<:Space}) = false
# isring(::Type{<:Field}) = true

# isfield(::Type{<:Space}) = false
# isfield(::Type{<:Field}) = true

# ismagma(::Type{<:Space}, ::Function) = false
# ismagma(::Type{<:Field}, ::typeof(+)) = true
# ismagma(::Type{<:VectorSpace}, ::typeof(+)) = true
# ismagma(::Type{<:Field}, ::typeof(*)) = true


space(::Union{Expression{T}, Type{<:Expression{T}}}) where T = T

isvectorspace(e1::Expression, e2::Expression) = isvectorspace(space(e1),space(e2))
canevaluate(e1::Expression, e2::Expression) = canevaluate(space(e1), space(e2))
isfunction(e::Expression) = isfunction(space(e))
issinglevalued(e::Expression) = issinglevalued(space(e))
isfunctional(e::Expression) = isfunctional(space(e))



# @traitdef IsGroup{G,F}
# @traitimpl IsGroup{G,F} <- isgroup(G, F)

# @traitdef IsVectorSpace{V}
# @traitimpl IsVectorSpace{V} <- isvectorspace(V)

# @traitdef IsVectorSpaceField{V,F}
# @traitimpl IsVectorSpaceField{V,F} <- isvectorspacefield(V,F)

# @traitdef IsLinear{T}
# @traitimpl IsLinear{T} <- islinear(T)

# @traitdef IsSubset{T1,T2}
# @traitimpl IsSubset{T1,T2} <- issubset(T1,T2)

# @traitdef CanEvaluate{T1,T2}
# @traitimpl CanEvaluate{T1,T2} <- canevaluate(T1,T2)


############################################################################################
# OPERATOR PROPERTIES
############################################################################################

"""
    Property{T}

Property of objects of type `T`.
"""
abstract type Property{T} <: Object end

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
# CONSTANTS
############################################################################################

const Objects = Set{Object}
const Expressions = Set{Expression}
const Operators = Set{Expression{<:Operator}}
const Constraints = Set{Constraint}
const Properties = Set{Property}
const Relations = Set{Relation}
