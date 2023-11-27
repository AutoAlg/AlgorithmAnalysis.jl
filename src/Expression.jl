export AbstractVec, Point, Scalar, Points, Scalars, Variable, Constant, Value, ValueOrNothing, ExpressionOrValue, Expression, promote_rule, convert, Zero, Id

import Base.promote_rule, Base.convert

"An abstract expression in a linear computational graph."
abstract type Expression end

const Value = Union{Number,AbstractArray}
const ValueOrNothing = Union{Value,Nothing}
const ExpressionOrValue = Union{Expression,Value}

function isleaf end
function type end
function evaluate end


struct Variable{T<:Value} <: Expression end

struct Constant{T<:Value} <: Expression
  value::T
end

"Zero expression (additive identity)."
struct Zero <: Expression end

"Identity expression (multiplicative identity)."
struct Id <: Expression end

"Promote a subtype of `Value` to a subtype of `Expression`."
promote_rule(::Type{T}, ::Type{<:Value}) where {T<:Expression} = T

"Convert a subtype of `Value` to a subtype of `Expression`."
convert(::Type{T1}, x::T2) where {T1<:Expression,T2<:Value} = T1(x)
# convert(::Type{Constant{T}}, x::T) where {T} = Constant{T}(x)
# convert(::Type{Expression}, x::T) where {T<:Value} = Constant{T}(x)


# leaf or non-leaf
# variable or constant
# type of value
# algebraic properties

###############################################################################
# Each `Expression` must specialize the following methods.

"Construct a leaf node expression."
function Expression()::Expression end

"Construct a non-leaf node expression from its children."
function Expression(children::Dict)::Expression end

"Get the children of an expression."
function children(e::Expression)::Dict end

"Check whether or not an expression is a leaf node."
function isleaf(e::Expression)::Bool end

###############################################################################
# Derived methods.

"Add two expressions."
function sum(e1::T1, e2::T2) where {T1<:Expression,T2<:Expression}
  E1,E2 = promote(e1,e2)
  T = typeof(E1)
  T(mergewith(+,children(E1),children(E2)))
end
sum(e::Expression, ::Zero) = e
sum(::Zero, e::Expression) = e

"Scale an expression."
scale(a::Number, e::T) where {T<:Expression} = T(Dict(keys(children(e)) .=> map(x->a*x, values(children(e)))))


###############################################################################
# AbstractVec

"An abstract vector space over the field `Number`."
const AbstractVec = Expression



###############################################################################
# Each `AbstractVec` must specialize the following methods.

# "Construct a leaf node expression."
# function AbstractVec()::AbstractVec end

# "Construct a non-leaf node expression from its children."
# function AbstractVec(children::Dict)::AbstractVec end

# "Get the children of an expression."
# function children(e::AbstractVec)::Dict end

# "Check whether or not an expression is a leaf node."
# function isleaf(e::AbstractVec)::Bool end

# sum(v1::AbstractVec, v2::AbstractVec) = error("Sum not implemented for type $(typeof(v1)) or $(typeof(v2)).")
# scale(a::Number, v::AbstractVec) = error("Scale not implemented for type $(typeof(v)).")

###############################################################################
# Derived methods.

# "Add two expressions."
# sum(e1::T, e2::T) where {T<:Expression{<:Value}} = T(mergewith(+,children(e1),children(e2)))
# sum(e::Expression, ::Zero) = e
# sum(::Zero, e::Expression) = e

# "Scale an expression."
# scale(a::Number, e::T) where {T<:Expression} = T(Dict(keys(children(e)) .=> map(x->a*x, values(children(e)))))

"Add two vectors."
Base.:+(v1::T1, v2::T2) where {T1<:Union{AbstractVec,Value},T2<:Union{AbstractVec,Value}} = sum(promote(v1,v2)...)

"Subtract two vectors."
Base.:-(v1::T1, v2::T2) where {T1<:AbstractVec,T2<:AbstractVec} = v1 + (-v2)

"Scale a vector."
Base.:*(a::Number, v::T) where {T<:AbstractVec} = scale(a,v)
Base.:*(v::AbstractVec, a::Number) = a*v
Base.:/(v::AbstractVec, a::Number) = (1/a)*v

"Negate a vector."
Base.:-(v::AbstractVec) = -1*v

# "Add vector with the zero vector."
# sum(v::AbstractVec, ::Zero) = v
# sum(::Zero, v::AbstractVec) = v


###############################################################################
# Point

struct Point <: AbstractVec
  is_leaf::Bool
  children::Dict
end

# required methods

Point() = Point(true,Dict())
Point(children::Dict) = Point(false,children)
children(p::Point) = ( p.is_leaf ? Dict(p => 1) : p.children )
isleaf(p::Point) = p.is_leaf
zero(::Type{Point}) = Point(true,Dict())

# additional methods

Base.:*(p1::Point, p2::Point) = Scalar(true,Dict( (p1,p2) => 1 ),0)

"Custom display of a point."
function Base.show(io::IO, p::Point)
  @show p.is_leaf
  @show p.children
end

###############################################################################
# Scalar

struct Scalar <: AbstractVec
  is_leaf::Bool
  children::Dict
  constant::Number
end

# required methods

Scalar() = Scalar(true,Dict(),0)
Scalar(children::Dict) = Scalar(false,children,0)
Scalar(v::Number) = Scalar(true,Dict(),v)
children(s::Scalar) = ( s.is_leaf ? Dict(s => 1) : s.children )
isleaf(s::Scalar) = s.is_leaf
zero(::Type{Scalar}) = Scalar(true,Dict(),0)

# additional methods

"Add a scalar and a number."
Base.:+(a::Number, s::Scalar) = Scalar(false,s.children,s.constant+a)
Base.:+(s::Scalar, a::Number) = a+s

"Subtract a scalar and a number."
Base.:-(a::Number, s::Scalar) = a+(-s)
Base.:-(s::Scalar, a::Number) = s+(-a)

"Multiply a number and a scalar."
scale(a::Number, s::Scalar) = Scalar(false,Dict(keys(children(s)) .=> map(x->a*x, values(children(s)))),a*s.constant)

###############################################################################
# Vectors

const Expressions = Vector{Expression}
const Scalars = Vector{Scalar}
const Points = Vector{Point}

###############################################################################
# Default tuple constructors

Tuple{X,Y}() where {X,Y} = (X(),Y())
Tuple{X,Y,Z}() where {X,Y,Z} = (X(),Y(),Z())