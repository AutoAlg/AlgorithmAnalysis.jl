export AbstractVec, Point, Scalar, Points, Scalars, Variable, Constant, Value, ValueOrNothing, ExpressionOrValue, Expression, promote_rule, convert, Id, decompose, ancestors, evaluate, hasvalue, getvalue, zero, squared_norm, label, label!, iszero, decomposition, isleaf

import Base.promote_rule, Base.convert, Base.==, Base.zero, Base.isequal, Base.:^, Base.iszero


###############################################################################
# Each `Expression` must either have the following fields:
#  - `label`
#  - `ancestors`
#  - 'value'
# or it must specialize the following methods.

"Construct a variable expression."
function Expression() end

"Set the label of an expression."
label!(x::Expression, label::String) = (x.label = label; nothing)

"Get the label of an expression."
label(x::Expression) = x.label

"Check whether or not an expression is a leaf. Leaf expressions have no ancestors."
isleaf(x::Expression) = isempty(x.ancestors)

"Check whether or not an expression is zero."
function iszero(x::Expression) end

"Check whether or not an expression is a variable."
function isvariable(x::Expression)
  isempty(x.ancestors) && isnothing(x.value) && !iszero(x)
end
isvariable(x::Any) = false

"Check whether or not the value of an expression is known."
hasvalue(x::Expression) = iszero(x) || !isnothing(x.value)

"Get the value of an expression (should first check if the expression has a value)."
getvalue(x::Expression{T}) where {T} = (iszero(x) ? zero(T) : x.value)

"Decomposition of an expression into a dictionary whose keys are leaf expressions (variables or constants) and whose values are the corresponding weights."
function decomposition(x::Expression)
  if iszero(x)
    Dict()
  elseif isleaf(x)
    Dict(x => 1)
  else
    x.ancestors
  end
end

"Custom display of an expression."
function Base.show(io::IO, x::T) where {T<:Expression}
  if iszero(x)
    print(io, "$T(0)")
  elseif hasvalue(x)
    print(io, evaluate(x))
  elseif isleaf(x)
    print(io, "$T($(label(x)))")
  else
    print(io, "$T($(label(x)),$(length(decomposition(x))))")
  end
end

"Data type that an expression evaluates to."
type(::Expression{T}) where {T} = T

"Evaluate an expression."
function evaluate(x::Expression{T}) where {T}
  if hasvalue(x)
    getvalue(x)
  else
    if isleaf(x)
      error("Cannot evaluate expression $x.")
    else
      val = zero(T)
      for (key, value) ∈ decomposition(x)
        if isa(key, Expression)
          val += value * evaluate(key)
        elseif isa(key, Tuple{Point,Point})
          val += value * evaluate(key[1])'*evaluate(key[2])
        end
      end
      val
    end
  end
end

"Check if two expressions are equal."
function isequal(x1::Expression{T1}, x2::Expression{T2}) where {T1,T2}
  if T1 ≠ T2
    return false
  end
  if isleaf(x1)
    if isleaf(x2)
      hash(x1) == hash(x2)
    else
      false
    end
  else
    isequal(decomposition(x1), decomposition(x2))
  end
end

"Sum two expressions of the same type."
function sum(x1::T, x2::T) where {T<:Expression}
  T(mergewith(+, decomposition(x1), decomposition(x2)))
end

"Scale an expression."
function scale(a::Number, x::T) where {T<:Expression}
  if iszero(x) || iszero(a)
    zero(T)
  else
    T(Dict(keys(decomposition(x)) .=> map(v->a*v, values(decomposition(x)))))
  end
end

###############################################################################
# Vectors

"Sum two expressions."
Base.:+(x1::T, x2::T) where {T<:Expression} = sum(x1,x2)

"Subtract two expressions."
Base.:-(x1::T, x2::T) where {T<:Expression} = sum(x1,-x2)

"Scale an expression."
Base.:*(a::Number, x::T) where {T<:Expression} = scale(a,x)
Base.:*(x::T, a::Number) where {T<:Expression} = scale(a,x)
Base.:/(x::T, a::Number) where {T<:Expression} = scale(1/a,x)

"Negate an expression."
Base.:-(x::Expression) = scale(-1,x)

###############################################################################
# Numbers

"Sum two numbers."
Base.:+(x1::T, x2::Number) where {T<:Expression{Number}} = sum(x1,T(x2))
Base.:+(x1::Number, x2::T) where {T<:Expression{Number}} = sum(T(x1),x2)

"Subtract two numbers."
Base.:-(x1::T, x2::Number) where {T<:Expression{Number}} = sum(x1,T(-x2))
Base.:-(x1::Number, x2::T) where {T<:Expression{Number}} = sum(T(x1),-x2)

###############################################################################
# Point

"Point"
mutable struct Point <: Expression{Vector}
  ancestors::Dict{Point,Number}
  value::Union{Vector,Nothing}
  label::String
  oracles::Set{Oracle}
  constraints::Set{Constraint}
  iszero::Bool
  
  "Construct a point variable."
  Point() = new(Dict(),nothing,"",Set{Oracle}(),Set{Constraint}(),false)

  "Construct a point from its ancestors."
  Point(ancestors::Dict) = new(ancestors,nothing,"",Set{Oracle}(),Set{Constraint}(),false)

  "Construct a point from its value."
  Point(val::Union{Vector,Nothing}) = new(Dict(),val,"",Set{Oracle}(),Set{Constraint}(),false)
end

zero(::Type{Point}) = (x=Point(); x.iszero=true; x)

iszero(x::Point) = x.iszero

"Inner product of two points."
function Base.:*(x1::Point, x2::Point)
  ancestors = Dict{Tuple{Point,Point}, Number}()
  for (key1, value1) ∈ decomposition(x1)
    for (key2, value2) ∈ decomposition(x2)
      if !iszero(key1) && !iszero(key2)
        mergewith!(+, ancestors, Dict( (key1,key2) => value1*value2 ))
      end
    end
  end
  if isempty(ancestors)
    zero(Scalar)
  else
    Scalar(ancestors)
  end
end

Base.:^(v::Point, n::Int) = (n == 2 ? v*v : error("Only squaring a vector is allowed."))


###############################################################################
# Scalar

mutable struct Scalar <: Expression{Number}
  ancestors::Dict
  value::Union{Number,Nothing}
  label::String
  oracles::Set{Oracle}
  constraints::Set{Constraint}
  
  "Construct a scalar variable."
  Scalar(label::String = "") = new(Dict(),nothing,label,Set{Oracle}(),Set{Constraint}())

  "Construct a scalar from its ancestors."
  Scalar(ancestors::Dict, label::String = "") = new(ancestors,nothing,label,Set{Oracle}(),Set{Constraint}())

  "Construct a constant scalar from a number."
  Scalar(a::Number, label::String = "") = new(Dict(),a,label,Set{Oracle}(),Set{Constraint}())
end

zero(::Type{Scalar}) = Scalar(0,"0")

iszero(x::Scalar) = (x.value == 0)



###############################################################################
# Conversion and promotion

# "Promote a subtype of `Value` to a subtype of `Expression`."
# promote_rule(::Type{T}, ::Type{<:Value}) where {T<:Expression} = T

# "Convert a subtype of `Value` to a subtype of `Expression`."
# convert(::Type{T1}, x::T2) where {T1<:Expression,T2<:Value} = T1(x)

convert(::Type{Scalar}, x::Number) = Scalar(x)
promote_rule(::Type{Scalar}, ::Type{<:Number}) = Scalar


###############################################################################
# Vectors

const Expressions = Vector{Expression}
const Scalars = Vector{Scalar}
const Points = Vector{Point}


isequal(::Tuple{Point,Point}, ::Scalar) = false
isequal(::Scalar, ::Tuple{Point,Point}) = false
isequal(::Point, ::Scalar) = false

###############################################################################
# Default tuple constructors

Tuple{X,Y}() where {X,Y} = (X(),Y())
Tuple{X,Y,Z}() where {X,Y,Z} = (X(),Y(),Z())


zero(::Type{Tuple{X,Y}}) where {X,Y} = (zero(X),zero(Y))



###############################################################################
# Traits

# Expression
#  - Composite
#  - Simple
#    - Variable
#    - Constant
#      - Nonzero
#      - Zero

# # Trait: iszero
# abstract type IsZero end
# struct Zero <: IsZero end
# struct Nonzero <: IsZero end

# # Expressions are nonzero by default
# IsZero(::Type{<:Expression}) = Nonzero()

# method(x::T) where {T} = method(IsZero(T), x)
# method(::Zero, x) = true
# method(::Nonzero, x) = false


# abstract type LeafBranch end
# struct Leaf <: LeafBranch end
# struct Branch <: LeafBranch end

# abstract type VariableConstant end
# struct Variable <: VariableConstant end
# struct Constant <: VariableConstant end

# abstract type IsZero end
# struct Zero <: IsZero end
# struct Nonzero <: IsZero end

# sum(x1::T1, x2::T2) where {T1<:Expression,T2<:Expression} = sum(LeafBranch(T1), LeafBranch(T2), x1, x2)
# sum(::Leaf, ::Leaf, x1, x2) = T(Dict(x1 => 1, x2 => 1))
# sum(::Leaf, ::Branch, x1, x2) = T(mergewith(+, Dict(x1 => 1), x2.ancestors))
# sum(::Branch, ::Leaf, x1, x2) = T(mergewith(+, x1.ancestors, Dict(x2 => 1)))
# sum(::Branch, ::Branch, x1, x2) = T(mergewith(+, x1.ancestors, x2.ancestors))

# ###############################################################################
# # Point

# abstract type Point <: Expression{Vector} end
# abstract type LeafPoint <: Point end
# abstract type ConstantPoint <: LeafPoint end

# mutable struct VariablePoint <: LeafPoint
#   oracles::Set{Oracle}
#   constraints::Set{Constraint}
#   label::String

#   "Construct a variable leaf point."
#   LeafPoint() = new(Set{Oracle}(),Set{Constraint}(),"")
# end

# mutable struct NonzeroPoint <: ConstantPoint
#   value::Vector
#   label::String

#   "Construct a constant leaf point from its value."
#   LeafPoint(val::Vector) = new(val,"")
# end

# mutable struct ZeroPoint <: ConstantPoint end

# mutable struct BranchPoint <: Point
#   ancestors::Dict{LeafPoint,Number}
#   label::String

#   "Construct a branch point from its ancestors."
#   BranchPoint(ancestors::Dict) = new(ancestors,"")
# end

# LeafBranch(::Type{<:LeafPoint}) = Leaf()
# LeafBranch(::Type{<:BranchPoint}) = Branch()

# VariableConstant(::Type{<:VariablePoint}) = Variable()
# VariableConstant(::Type{<:ConstantPoint}) = Constant()

# IsZero(::Type{<:ZeroPoint}) = Zero()
# IsZero(::Type{<:NonzeroPoint}) = Nonzero()




###############################################################################
# Each `VectorSpace` must specialize the following methods.

# sum(v1::VectorSpace, v2::VectorSpace) = error("Sum not implemented for type $(typeof(v1)) or $(typeof(v2)).")
# scale(a::Number, v::VectorSpace) = error("Scale not implemented for type $(typeof(v)).")

# const VectorSpace = Vec

###############################################################################
# Derived methods.

# "Add two vectors."
# function sum(x1::T, x2::T) where {T<:VectorSpace}
#   x = T(mergewith(+,decomposition(x1),decomposition(x2)))
#   mergewith!(+,parents(x1),Dict(x => 1))
#   mergewith!(+,parents(x2),Dict(x => 1))
#   x
# end

# "Scale a vector."
# scale(a::Number, v::T) where {T<:VectorSpace} = T(Dict(keys(decomposition(v)) .=> map(x->a*x, values(decomposition(v)))))

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