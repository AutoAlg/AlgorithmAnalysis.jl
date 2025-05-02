############################################################################################
# ABSTRACT TYPES
############################################################################################

"""
    Space

A set of mathematical objects with a (possibly empty) set of structures.
"""
abstract type Space end

"""
    Object{T}

An object in space `T`.

A subtype is [`AbstractVectorSpace`](@ref).
"""
abstract type Object{T<:Space} end

"""
    Decomposition{T}

An object in space `T` that is a decomposition of other objects.
"""
abstract type Decomposition{T<:Space} <: Object{T} end

"""
    Constraint

An abstract constraint that consists of an [`Object`](@ref) belonging to a [`ConstraintSet`](@ref).

Concrete subtypes should provide methods for `object`, `set`, `∈`, `isequal`, and `check`.
"""
abstract type Constraint end

"""
    ConstraintSet

An abstract set for use in a [`Constraint`](@ref).
"""
abstract type ConstraintSet end

"""
    Operator

An operator is a relation between pairs of objects. Operators may be sampled at objects in their domain to produce output objects in their codomain. Operators may also have other associated operators; for instance, a linear operator has an associated adjoint. Each operator can be sampled at a point in its domain, and it can have a set of properties.

Any concrete subtype of `Operator` must have the following fields:
    label::String
    properties::Properties

Some concrete operators are [`LinearMap`](@ref), [`Functional`](@ref), etc.
"""
abstract type Operator{X<:Space, Y<:Space} <: Space end

"""
    Relation{X,Y}

A relation is a subset of the product space Element{X} × Element{Y}.
"""
abstract type Relation{X,Y} <: Space end



abstract type Ring <: Space end

"""
    Field <: Space

An abstract field.

An element of a field is a scalar. A scalar is an object that can be an affine function of other scalars and inner products of points in an inner product space over the field.

Use [`@field]`](@ref) to construct a field.
"""
abstract type Field <: Ring end

"""
    VectorSpace{F<:Field} <: Space

An abstract vector space.

A vector is an object that can be a linear function of other vectors.
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


############################################################################################
# CARTESIAN PRODUCT
############################################################################################

struct CartesianProduct{T<:Tuple{Vararg{Space}}} <: Space end

const CartesianPower{T, N} = CartesianProduct{NTuple{N,T}}

spaces(::Type{CartesianProduct{T}}) where T = T

×(::Type{T}, ::Type{T}) where {T<:Space} = CartesianPower{T, 2}
×(::Type{CartesianPower{N, T}}, ::Type{T}) where {N<:Int, T<:Space} = CartesianPower{T, N+1}
×(::Type{T}, ::Type{CartesianPower{N, T}}) where {N<:Int, T<:Space} = CartesianPower{T, N+1}
×(::Type{CartesianPower{N1, T}}, ::Type{CartesianPower{N2, T}}) where {N1<:Int, N2<:Int, T<:Space} = CartesianPower{T, N1+N2}

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

isempty(::Object{<:CartesianProduct{T}}) where T = iszero(length(T))
length(::Object{<:CartesianProduct{T}}) where T = length(T)
iterate(x::Object{<:CartesianProduct{T}}) where T = iterate(x,1)
function iterate(x::Object{<:CartesianProduct{T}}, state::Int) where T
    state > length(x) ? nothing : ( value(x)[state], state+1 )
end

isempty(x::Object{<:CartesianPower}) = iszero(length(value(x)))
length(x::Object{<:CartesianPower}) = length(value(x))
iterate(x::Object{<:CartesianPower}) = iterate(x,1)
function iterate(x::Object{<:CartesianPower}, state::Int)
    state > length(x) ? nothing : ( value(x)[state], state+1 )
end

length(::Type{T}) where {T<:Tuple} = length(T.types)


const Scaling{V<:VectorSpace, F<:Field} = AbstractFunction{CartesianProduct{Tuple{F,V}}, V}

field(::Type{Scaling{V,F}}) where {V,F} = F
vectorspace(::Type{Scaling{V,F}}) where {V,F} = V

const UnaryOperator{X<:Space} = AbstractFunction{X, X}
# const BinaryOperator{X<:Space} = AbstractFunction{CartesianPower{X, 2}, X}
# const NaryOperator{X<:Space} = AbstractFunction{CartesianPower{X}, X}

abstract type BinaryOperator{X<:Space} <: Space end
abstract type NaryOperator{X<:Space} <: Space end

arity(::UnaryOperator) = 1
arity(::BinaryOperator) = 2

# abstract type GroupOperator{X} <: NaryOperator{X} end
abstract type Addition{X} <: NaryOperator{X} end
abstract type Multiplication{X} <: NaryOperator{X} end


############################################################################################
# DOMAIN / CODOMAIN
############################################################################################

# domain(::TypeVar) = Union{}
# codomain(::TypeVar) = Union{}

domain(::Type{<:Operator{X,Y}}) where {X,Y} = X
codomain(::Type{<:Operator{X,Y}}) where {X,Y} = Y

codomain(::Type{<:Functional{V}}) where {F<:Field, V<:VectorSpace{F}} = F

domain(e::Object) = domain(space(e))
codomain(e::Object) = codomain(space(e))

domain(::Type{<:BinaryOperator{T}}) where T = T × T
codomain(::Type{<:BinaryOperator{T}}) where T = T

domain(::Type{<:NaryOperator{T}}) where T = CartesianPower{T}
codomain(::Type{<:NaryOperator{T}}) where T = T

# domain(::Type{<:Object{CartesianPower{T}}}) where {T, N} = NTuple{N, T}


############################################################################################
# TYPES OF SPACES
############################################################################################

isfunction(::Type{<:Space}) = false
isfunction(::Type{<:Operator}) = true
isfunction(::Type{<:BinaryOperator}) = true
isfunction(::Type{<:NaryOperator}) = true

function issinglevalued(::Type{T}) where {T<:Space}
    isfunction(T) ? false : error("$T is not a function space.")
end
issinglevalued(::Type{<:AbstractFunction}) = true
issinglevalued(::Type{<:Functional}) = true
issinglevalued(::Type{<:BinaryOperator}) = true
issinglevalued(::Type{<:NaryOperator}) = true

issubset(T1::Type{<:Space}, T2::Type{<:Space}) = T1 <: T2

function canevaluate(::Type{T1}, ::Type{T2}) where {T1<:Space, T2<:Space}
    isfunction(T1) && issubset(T2, domain(T1)) ? true : false
end

isfunctional(::Type{<:Space}) = false
isfunctional(::Type{<:Functional}) = true

# additiveidentity(::Type{T}) where {T<:Space} = isgroup(T, +) ? Zero{T}() : error("Space $T is not a group over addition")

# multiplicativeidentity(::Type{T}) where {T<:Space} = isgroup(T, *) ? One{T}() : error("Space $T is not a group over multiplication")


space(::Union{Object{T}, Type{<:Object{T}}}) where T = T

isvectorspace(e1::Object, e2::Object) = isvectorspace(space(e1),space(e2))
canevaluate(e1::Object, e2::Object) = canevaluate(space(e1), space(e2))
isfunction(e::Object) = isfunction(space(e))
issinglevalued(e::Object) = issinglevalued(space(e))
isfunctional(e::Object) = isfunctional(space(e))


############################################################################################
# OPERATOR PROPERTIES
############################################################################################

"""
    Property{T}

Property of objects of type `T`.
"""
abstract type Property end

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
const Operators = Set{Object{<:Operator}}
const Constraints = Set{Constraint}
const Properties = Set{Property}
const Relations = Set{Relation}
