export AbstractVec, Point, Scalar, Points, Scalars, Variable, Constant, Value, ValueOrNothing, ExpressionOrValue, Expression, promote_rule, convert, Zero, Id, children, evaluate, hasvalue, getvalue, zero, squared_norm, label, label!

import Base.promote_rule, Base.convert, Base.==, Base.zero, Base.isequal, Base.:^


###############################################################################
# Basis vector

"The `i`th basis vector of dimension `n`."
function basis_vector(i::Int, n::Int)
  if i ≤ 0 || i > n
    error("Basis vector must have 1 ≤ i ≤ n.")
  end
  e = zeros(n)
  e[i] = 1
  e
end


###############################################################################
# Abstract types



struct Zero <: Expression end

###############################################################################
# Each `Expression` must either have the fields `label` and `children` and `parents` or it must
# specialize the following methods.

"Construct a variable expression."
function Expression()::Expression end

"Set the label of an expression."
function label!(x::Expression, label::String)::Nothing
  x.label = label
  nothing
end

"Get the label of an expression."
function label(x::Expression)::String
  x.label
end

"Check whether or not an expression is a leaf."
isleaf(x::Expression) = isempty(x.children)

"Children of an expression, which is a set/tuple/vector of expressions on which the atom is operated to produce the expression."
function children(x::Expression)
  isleaf(x) ? Dict(x => 1) : x.children
end

"Parents of an expression, which is the set of expressions for which this expression is a child."
function parents(x::Expression)::Set{Expression}
  x.parents
end

"Custom display of an expression."
function Base.show(io::IO, x::T) where {T<:Expression}
  println(io, "$T($(label(x)),$(length(children(x))))")
end

"Variables in an expression."
variables(x::Expression) = keys(children(x))

# "Data type for the values of an expression."
# type(::Expression{T}) where {T} = T

"Check whether or not the value of an expression is known."
hasvalue(x::Expression) = !isnothing(x.value)
getvalue(x::Expression) = x.value

"Evaluate an expression."
function evaluate(x::Expression)
  if hasvalue(x)
    getvalue(x)
  elseif isleaf(x) && !hasvalue(x)
    error("Cannot evaluate expression $x.")
  else
    val = zero(typeof(x))
    for (key, value) ∈ children(x)
      if isleaf(key) && !hasvalue(key)
        error("Cannot evaluate expression $key.")
      end
      val += value * evaluate(key)
    end
    val
  end
end

"Check if two expressions are equal."
function isequal(x1::Expression, x2::Expression)
  if isleaf(x1)
    if isleaf(x2)
      isequal(getvalue(x1), getvalue(x2))
    else
      false
    end
  else
    isequal(children(x1), children(x2))
  end
end

###############################################################################
# Each `VectorSpace` must specialize the following methods.

# sum(v1::VectorSpace, v2::VectorSpace) = error("Sum not implemented for type $(typeof(v1)) or $(typeof(v2)).")
# scale(a::Number, v::VectorSpace) = error("Scale not implemented for type $(typeof(v)).")

# const VectorSpace = Vec

###############################################################################
# Derived methods.

# "Add two vectors."
# function sum(x1::T, x2::T) where {T<:VectorSpace}
#   x = T(mergewith(+,children(x1),children(x2)))
#   mergewith!(+,parents(x1),Dict(x => 1))
#   mergewith!(+,parents(x2),Dict(x => 1))
#   x
# end

# "Scale a vector."
# scale(a::Number, v::T) where {T<:VectorSpace} = T(Dict(keys(children(v)) .=> map(x->a*x, values(children(v)))))

# ###############################################################################
# # InnerProductSpace

# "An abstract inner product space."
# abstract type InnerProductSpace <: VectorSpace end

# # Each `InnerProductSpace` must specialize the following methods.
# function Base.:*(v1::InnerProductSpace, v2::InnerProductSpace) end

# # Derived methods
# Base.:^(v::InnerProductSpace, n::Int) = (n == 2 ? v*v : error("Only squaring a vector is allowed."))

# ###############################################################################
# # ScalarField

# "An abstract scalar."
# abstract type ScalarField <: InnerProductSpace end

# ###############################################################################
# # Each `ScalarField` must specialize the following methods.

# "Construct a scalar field from a number."
# function ScalarField(a::Number)::ScalarField end


###############################################################################
# Point

"Point"
mutable struct Point <: Expression
  children::Dict
  value::Union{Vector,Nothing}
  label::String
  oracles::Vector{Oracle}
  constraints::Vector{Constraint}
  
  "Construct a point variable."
  Point() = new(Dict(),nothing,"",Oracle[],Constraint[])

  "Construct a point from its children."
  Point(children::Dict) = new(children,nothing,"",Oracle[],Constraint[])
end

zero(::Type{Point}) = (p=Point(); p.value=[0]; p.label="0"; p)

function Base.:*(p1::Point, p2::Point)
  d = Dict()
  for (key1, value1) ∈ children(p1)
    for (key2, value2) ∈ children(p2)
      mergewith!(+,d,Dict( (key1,key2) => value1*value2 ))
    end
  end
  Scalar(d)
end

Base.:^(v::Point, n::Int) = (n == 2 ? v*v : error("Only squaring a vector is allowed."))

"Add two vectors."
sum(x1::Point, x2::Point) = Point(mergewith(+,children(x1),children(x2)))

"Add vector with the zero vector."
sum(v::Point, ::Zero) = v
sum(::Zero, v::Point) = v

"Scale a vector."
scale(a::Number, v::Point) = Point(Dict(keys(children(v)) .=> map(x->a*x, values(children(v)))))

"Add two vectors."
Base.:+(v1::Point, v2::Point) = sum(v1,v2)

"Subtract two vectors."
Base.:-(v1::Point, v2::Point) = v1 + (-v2)

"Scale a vector."
Base.:*(a::Number, v::Point) = scale(a,v)
Base.:*(v::Point, a::Number) = a*v
Base.:/(v::Point, a::Number) = (1/a)*v

"Negate a vector."
Base.:-(v::Point) = -1*v

# "Multiply a vector with the identity matrix."
# Base.:*(::Identity, v::Point) = v

###############################################################################
# Scalar

mutable struct Scalar <: Expression
  children::Dict
  value::Union{Number,Nothing}
  label::String
  oracles::Vector{Oracle}
  constraints::Vector{Constraint}
  
  "Construct a scalar variable."
  Scalar(label::String = "") = new(Dict(),nothing,label,Oracle[],Constraint[])

  "Construct a scalar from its children."
  Scalar(children::Dict, label::String = "") = new(children,nothing,label,Oracle[],Constraint[])

  "Construct a constant scalar from a number."
  Scalar(a::Number, label::String = "") = new(Dict(),a,label,Oracle[],Constraint[])
end

zero(::Type{Scalar}) = Scalar(0,"0")

"Add two scalars."
sum(x1::Scalar, x2::Scalar) = Scalar(mergewith(+, children(x1), children(x2)))
sum(x1::Number, x2::Scalar) = Scalar(mergewith(+, children(x2), Dict(1 => x1)))
sum(x1::Scalar, x2::Number) = Scalar(mergewith(+, children(x1), Dict(1 => x2)))

"Add vector with the zero vector."
sum(v::Scalar, ::Zero) = v
sum(::Zero, v::Scalar) = v

"Scale a vector."
scale(a::Number, v::Scalar) = Scalar(Dict(keys(children(v)) .=> map(x->a*x, values(children(v)))))

"Add two vectors."
Base.:+(v1::Scalar, v2::Scalar) = sum(v1,v2)
Base.:+(v1::Scalar, v2::Number) = v1 + Scalar(v2)
Base.:+(v1::Number, v2::Scalar) = v2 + Scalar(v1)

"Subtract two vectors."
Base.:-(v1::Scalar, v2::Scalar) = v1 + (-v2)
Base.:-(v1::Scalar, v2::Number) = v1 + (-v2)
Base.:-(v1::Number, v2::Scalar) = v1 + (-v2)

"Scale a vector."
Base.:*(a::Number, v::Scalar) = scale(a,v)
Base.:*(v::Scalar, a::Number) = a*v
Base.:/(v::Scalar, a::Number) = (1/a)*v

"Negate a vector."
Base.:-(v::Scalar) = -1*v

###############################################################################
# Conversion and promotion

# "Promote a subtype of `Value` to a subtype of `Expression`."
# promote_rule(::Type{T}, ::Type{<:Value}) where {T<:Expression} = T

# "Convert a subtype of `Value` to a subtype of `Expression`."
# convert(::Type{T1}, x::T2) where {T1<:Expression,T2<:Value} = T1(x)


convert(::Type{Scalar}, x::Number) = Scalar(x)


###############################################################################
# Vectors

const Expressions = Vector{Expression}
const Scalars = Vector{Scalar}
const Points = Vector{Point}

###############################################################################
# Default tuple constructors

Tuple{X,Y}() where {X,Y} = (X(),Y())
Tuple{X,Y,Z}() where {X,Y,Z} = (X(),Y(),Z())



