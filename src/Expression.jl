###############################################################################
# Value
#  - Scalar
#  - Point
# Expression{T} where T <: Value
#  - AbstractAffine{T}
#    - Affine{T}
#    - AbstractLinear{T}
#      - Linear{T}
#    - AbstractConstant{T}
#      - Constant{T}
#      - Zero{T}
#  - Variable{T}
#  - InnerProduct{Scalar}

export Value, Point, Scalar
export Expression, Variable, Variables
export AbstractConstant, Constant, Zero
export AbstractLinear, Linear, AbstractAffine, Affine, InnerProduct
export type, label, label!, evaluate, variables, constraints, weights, hasvalue
export ⊗, linear, constant

import Base.show, Base.isequal
import Base.+, Base.-, Base.*, Base./, Base.^
import Base.promote_rule, Base.convert
import Base.adjoint, Base.zero, Base.iszero


###############################################################################
# Value types

mutable struct Scalar <: Value{Number}
  value::Union{Number, Missing}
end

mutable struct Point <: Value{Vector}
  value::Union{Vector, Missing}
end

+(x1::V, x2::V) where {T,V<:Value{T}} = V(x1.value + x2.value)

*(a::Number, x::V) where {T,V<:Value{T}} = V(a*x.value)

"Default constructor for any subtype of `Value`."
(::Type{V})() where {V<:Value} = V(missing)

"Construct any subtype of Expression from its value."
(::Type{E})(x::T) where {T,V<:Value{T},E<:Expression{V}} = E(V(x))


###############################################################################
# Arrays of expressions

adjoint(x::Expression) = x

zero(::E) where {T,E<:Expression{T}} = Zero{T}()

⊗(x1::Vector{<:Expression{Point}}, x2::Vector{<:Expression{Point}}) = Expression{Scalar}[ x1[i]*x2[j] for i ∈ 1:length(x1), j ∈ 1:length(x2) ]


###############################################################################
# Expression
#  .label
#  evaluate, variables, isequal, +, *(::Number, ::Expression)

"Data type that an expression evaluates to."
type(::Expression{T}) where {T} = T

"Set the label of an expression."
label!(x::Expression, label::String) = (x.label = label; missing)

"Get the label of an expression."
label(x::Expression) = x.label

"Check if an expression has a value."
hasvalue(x::Expression) = !ismissing(evaluate(x))

"Evaluate an expression. Returns `missing` if the expression cannot be evaluated."
function evaluate end

"Variables in an expression."
function variables end

"Check if two expressions are equal."
function isequal end

# Subtraction

"Subtract two expressions."
-(x1::Expression, x2::Expression) = x1 + (-x2)
-(x1::Expression, x2) = x1 + (-x2)
-(x1, x2::Expression) = x1 + (-x2)

# Scaling

"Scale an expression. Each subtype of `Expression` should implement scaling the expression by a `Number`."
*(a::Number, x::Expression) = error("Scaling not defined for $(typeof(x))")
*(x::Expression, a::Number) = a*x
/(x::Expression, a::Number) = (1/a)*x

"Negate an expression."
-(x::Expression) = (-1)*x


###############################################################################
# Variable

"A variable expression."
mutable struct Variable{T} <: Expression{T}
  value::Union{T, Missing}
  label::String
  constraints::Constraints
  relations::Relations
  
  Variable{T}(label::String = "") where {T<:Value} = new(missing, label, Constraints(), Relations())
  # Variable(value::T) where {T<:Value} = new{T}(value, string(value), Constraints(), Relations())
end

"A set of variables."
const Variables = Set{Variable}

"Initialize an expression as a variable (used when sampling an oracle)."
Expression{T}() where {T} = Variable{T}()


###############################################################################
# Constant / Linear / Affine

abstract type AbstractAffine{T} <: Expression{T} end
abstract type AbstractLinear{T} <: AbstractAffine{T} end
abstract type AbstractConstant{T} <: AbstractAffine{T} end

"The zero expression."
mutable struct Zero{T} <: AbstractConstant{T}
  label::String

  Zero{T}(label::String = "") where {T} = new(label)
end

"A nonzero constant expression."
mutable struct Constant{T} <: AbstractConstant{T}
  value::T
  label::String
  
  Constant(value::T, label::String = "") where {T<:Value} = new{T}(value, label)
end

"Check whether or not a constant expression is zero."
iszero(x::Expression) = false
iszero(x::AbstractConstant) = isa(x, Zero)

"A linear expression."
mutable struct Linear{T} <: AbstractLinear{T}
  weights::Dict{Expression{T}, Number}
  label::String

  Linear{T}(weights::Dict, label::String = "") where {T} = new(weights, label)
  Linear{T}(label::String = "") where {T} = new(Dict(), label)
  Linear(x::Expression{T}) where {T} = new{T}(Dict(x => 1), x.label)
end

"An affine expression."
mutable struct Affine{T} <: AbstractAffine{T}
  linear::AbstractLinear{T}
  constant::AbstractConstant{T}
  label::String

  Affine(linear::AbstractLinear{T}, constant::AbstractConstant{T} = Zero{T}(), label::String = "") where {T} = new{T}(linear, constant, label)
  Affine(constant::AbstractConstant{T}) where {T} = new{T}(Linear{T}(), constant, "")
  Affine{T}(label::String = "") where {T} = new(Dict(), Zero{T}(), label)
end

"Constant of an affine expression."
constant(x::AbstractConstant) = x
constant(x::Linear{T}) where {T} = Zero{T}()
constant(x::Affine) = x.constant

"Linear part of an affine expression."
linear(x::AbstractConstant{T}) where {T} = Linear{T}()
linear(x::Linear) = x
linear(x::Affine) = linear(x.linear)

"Dictionary whose keys are expressions and whose values are the corresponding weights in an affine expression."
weights(x::AbstractAffine) = linear(x).weights


###############################################################################
# InnerProduct

"An inner product of two points."
struct InnerProduct <: Expression{Scalar}
  left::Expression{Point}
  right::Expression{Point}
  label::String

  InnerProduct(left::Expression{Point}, right::Expression{Point}, label::String = "") = hash(left) < hash(right) ? new(left, right, label) : new(right, left, label)
end

"Inner product of two points."
function *(x1::AbstractLinear{Point}, x2::AbstractLinear{Point})
  w = Dict{InnerProduct, Number}()
  for (key1, value1) ∈ weights(x1)
    for (key2, value2) ∈ weights(x2)
      mergewith!(+, w, Dict( InnerProduct(key1,key2) => value1*value2 ))
    end
  end
  Linear{Scalar}(w)
end

# convert variables to linear expressions to compute inner products
*(x1::Variable{Point}, x2::Variable{Point}) = Linear(x1)*Linear(x2)
*(x1::Variable{Point}, x2::AbstractLinear{Point}) = Linear(x1)*x2
*(x1::AbstractLinear{Point}, x2::Variable{Point}) = x1*Linear(x2)

# inner product with zero
*(x1::Zero{Point}, x2::Zero{Point}) = Zero{Scalar}()
*(x1::Zero{Point}, x2::Expression{Point}) = Zero{Scalar}()
*(x1::Expression{Point}, x2::Zero{Point}) = Zero{Scalar}()

# inner product of points
*(x1::Point, x2::Point) = x1.value'*x2.value

^(x::AbstractLinear{Point}, n::Int) = (n == 2 ? x*x : error("Can only square point weights."))
^(x::Variable{Point}, n::Int) = (n == 2 ? x*x : error("Can only square point variables."))
^(x::Zero{Point}, n::Int) = (n == 2 ? Zero{Scalar}() : error("Can only square zero points."))

###############################################################################
# Evaluate

evaluate(x::Expression) = error("Evaluate not implemented for $(typeof(x)).")
evaluate(x::Constant) = x.value
evaluate(x::Zero) = x
evaluate(x::Linear{T}) where {T} = mapreduce( pair -> pair.second * evaluate(pair.first), +, weights(x); init=Zero{T}() )
evaluate(x::Variable) = x.value
evaluate(x::Affine) = evaluate(constant(x)) + evaluate(linear(x))
evaluate(x::InnerProduct) = evaluate(x.left)*evaluate(x.right)
evaluate(x::Value) = x.value


###############################################################################
# Variables

variables(x::Expression) = error("Variables not implemented for $(typeof(x)).")
variables(x::AbstractAffine) = mapreduce(variables, ∪, keys(weights(x)); init=Variables())
variables(x::Variable) = Variables([x])
variables(x::InnerProduct) = variables(x.left) ∪ variables(x.right)


###############################################################################
# IsEqual

isequal(x1::Expression, x2::Expression) = false

isequal(x1::Constant{T}, x2::Constant{T}) where {T} = isequal(x1.value, x2.value)
isequal(x1::Zero{T}, x2::Zero{T}) where {T} = true
isequal(x1::Linear{T}, x2::Linear{T}) where {T} = isequal(weights(x1), weights(x2))
isequal(x1::Variable{T}, x2::Variable{T}) where {T} = objectid(x1) == objectid(x2)
isequal(x1::Affine{T}, x2::Affine{T}) where {T} = isequal(linear(x1), linear(x2)) && isequal(constant(x1), constant(x2))
isequal(x1::InnerProduct, x2::InnerProduct) = ( isequal(x1.left,x2.left) && isequal(x1.right,x2.right) ) || ( isequal(x1.left,x2.right) && isequal(x1.right,x2.left) )

isequal(x1::AbstractArray{<:Expression}, x2::Expression) = false
isequal(x1::Expression, x2::AbstractArray{<:Expression}) = false
isequal(a1::AbstractArray{E}, a2::AbstractArray{E}) where {E<:Expression} = size(a1) == size(a2) && all( isequal(a1[i],a2[i]) for i ∈ eachindex(a1) )

isequal(x1::V, x2::V) where {V<:Value} = isequal(x1.value, x2.value)


###############################################################################
# Summation

+(x1::Zero{T}, x2::Zero{T}) where {T} = Zero{T}()
+(x1::Expression{T}, x2::Zero{T}) where {T} = x1
+(x1::Zero{T}, x2::Expression{T}) where {T} = x2
+(x1::AbstractAffine{T}, x2::Zero{T}) where {T} = x1
+(x1::Zero{T}, x2::AbstractAffine{T}) where {T} = x2
+(x1::Variable{T}, x2::Zero{T}) where {T} = x1
+(x1::Zero{T}, x2::Variable{T}) where {T} = x2
+(x1::T, x2::Zero{T}) where {T} = x1
+(x1::Zero{T}, x2::T) where {T} = x2

# +(x1::Variable{T}, x2::AbstractAffine{T}) where {T} = Affine(Linear(x1)+linear(x2), constant(x2))
# +(x1::AbstractAffine{T}, x2::Variable{T}) where {T} = Affine(linear(x1)+Linear(x2), constant(x2))

# +(x1::Variable{T}, x2::AbstractLinear{T}) where {T} = Linear(Linear(x1)+linear(x2))
# +(x1::AbstractLinear{T}, x2::Variable{T}) where {T} = Linear(linear(x1)+Linear(x2))

+(x1::Constant{T}, x2::Constant{T}) where {T} = Constant(x1.value + x2.value)
+(x1::Variable{T}, x2::Constant{T}) where {T} = Affine(Linear(x1), x2)
+(x1::Constant{T}, x2::Variable{T}) where {T} = Affine(Linear(x2), x1)
+(x1::AbstractAffine{T}, x2::AbstractAffine{T}) where {T} = Affine(linear(x1)+linear(x2), constant(x1)+constant(x2))
+(x1::InnerProduct, x2::Constant{Scalar}) = Linear(x1) + x2
+(x1::Constant{Scalar}, x2::InnerProduct) = Linear(x2) + x1

+(x1::Variable{T}, x2::Variable{T}) where {T} = Linear(x1) + Linear(x2)
+(x1::Variable{T}, x2::Linear{T}) where {T} = Linear(x1) + x2
+(x1::Linear{T}, x2::Variable{T}) where {T} = x1 + Linear(x2)
+(x1::Variable{T}, x2::Affine{T}) where {T} = Linear(x1) + x2
+(x1::Affine{T}, x2::Variable{T}) where {T} = x1 + Linear(x2)
+(x1::Variable{Scalar}, x2::InnerProduct) = Linear(x1) + Linear(x2)
+(x1::InnerProduct, x2::Variable{Scalar}) = Linear(x1) + Linear(x2)

function +(x1::AbstractLinear{T}, x2::AbstractLinear{T}) where {T}
  x = Linear{T}(mergewith(+, weights(x1), weights(x2)))
  for (key,value) ∈ x.weights
    if iszero(value)
      delete!(x.weights, key)
    end
  end
  if isempty(x.weights)
    Zero{T}()
  else
    x
  end
end
+(x1::Linear{Scalar}, x2::InnerProduct) = x1 + Linear(x2)
+(x1::InnerProduct, x2::Linear{Scalar}) = x2 + Linear(x1)

+(x1::Affine{Scalar}, x2::InnerProduct) = x1 + Linear(x2)
+(x1::InnerProduct, x2::Affine{Scalar}) = x2 + Linear(x1)

+(x1::InnerProduct, x2::InnerProduct) = Linear(x1) + Linear(x2)

+(x1::Expression{T}, x2::T) where {T} = x1 + Constant(x2)
+(x1::T, x2::Expression{T}) where {T} = Constant(x1) + x2

+(x1::Expression{Scalar}, x2::Number) = x1 + Constant(Scalar(x2))
+(x1::Number, x2::Expression{Scalar}) = Constant(Scalar(x1)) + x2

+(x1::Expression{Point}, x2::Vector) = x1 + Constant(Point(x2))
+(x1::Vector, x2::Expression{Point}) = Constant(Point(x1)) + x2

+(::Expression, ::Missing) = missing
+(::Missing, ::Expression) = missing


###############################################################################
# Scaling

*(a::Number, x::Constant{T}) where {T} = Constant(a*x.value, "")
*(a::Number, x::Zero) = x
*(a::Number, x::Variable{T}) where {T} = Linear{T}(Dict(x => a))
*(a::Number, x::Linear{T}) where {T} = Linear{T}(Dict(keys(x.weights) .=> map(v->a*v, values(x.weights))))
*(a::Number, x::Affine{T}) where {T} = Affine{T}(a*x.linear, a*x.constant)
*(a::Number, x::InnerProduct) = Linear{Scalar}(Dict(x => a))

*(x1::T, x2::Zero{T}) where {T} = Zero{T}()
*(x1::Zero{T}, x2::T) where {T} = Zero{T}()
/(::Zero{T}, ::Number) where {T} = Zero{T}()
/(::Any, ::Zero) = error("Division by zero.")


###############################################################################
# Show

# show(io::IO, ::MIME"text/plain", x::Expression) = print(io, x.label)

show(io::IO, x::AbstractConstant) = print(io, x.value)


function show(io::IO, x::Variable)
  value = evaluate(x)
  if !ismissing(value)
    print(io, value)
  elseif !isempty(label(x))
    print(io, label(x))
  else
    print(io, "Variable{$(type(x))}")
  end
end

show(io::IO, ::Zero{T}) where {T} = print(io, "Zero{$T}")

function show(io::IO, x::Linear)
  if hasvalue(x)
    show(io, evaluate(x))
    return
  end
  first = true
  for (key, value) ∈ x.weights
    if first
      first = false
      if value == 1
        print(io, key)
      elseif value == -1
        print(io, "-", key)
      else
        print(io, value, " ", key)
      end
    else
      if value == 1
        print(io, " + ", key)
      elseif value ≥ 0
        print(io, " + ", value, " ", key)
      else
        print(io, " - ", -value, " ", key)
      end
    end
  end
end

show(io::IO, x::Constant) = print(io, x.value)

function show(io::IO, x::Affine)
  print(io, linear(x))
  if !iszero(constant(x))
    print(io, " + ", constant(x))
  end
end

show(io::IO, x::InnerProduct) = hasvalue(x) ? print(io, evaluate(x)) : print(io, "⟨$(x.left),$(x.right)⟩")

show(io::IO, x::Value) = print(io, x.value)


###############################################################################
# Default tuple constructors

Tuple{X,Y}() where {X,Y} = (X(),Y())
Tuple{X,Y,Z}() where {X,Y,Z} = (X(),Y(),Z())


###############################################################################
# Hash

# Override hash function because of
# https://github.com/JuliaLang/julia/issues/10267
import Base.hash

"Hash of an expression."
hash(x::Constant, h::UInt) = hash(x.value, h)
hash(x::Zero{T}, h::UInt) where {T} = hash(T, h)
hash(x::Linear, h::UInt) = hash(weights(x), h)
hash(x::Variable, h::UInt) = objectid(x)
hash(x::Affine, h::UInt) = hash(linear(x), hash(constant(x), h))
hash(x::InnerProduct, h::UInt) = hash(x.left, hash(x.right, h))
hash(c::Constraint, h::UInt) = hash(set(c), hash(expression(c), h))
hash(x::Value, h::UInt) = hash(x.value, h)

function hash(a::AbstractArray{<:Expression}, h::UInt)
  h = hash(size(a), h)
  for x ∈ a
    h = hash(x, h)
  end
  h
end


# Expression{T} where T <: Value
#  - Constant{T}
#    - Constant{T}
#    - Zero{T}
#  - Variable{T}
#  - Linear{T}
#  - Affine{T}
#  - InnerProduct{Scalar}

# +(x1::Expression{T}, x2::Expression{T}) where {T} = +(promote(x1,x2)...)
# +(x1::Expression{T}, x2::T) where {T} = +(promote(x1,x2)...)
# +(x1::T, x2::Expression{T}) where {T} = +(promote(x1,x2)...)
# +(x1::Expression{Scalar}, x2::Number) = +(promote(x1,x2)...)
# +(x1::Number, x2::Expression{Scalar}) = +(promote(x1,x2)...)
# +(x1::Expression{Point}, x2::Vector) = +(promote(x1,x2)...)
# +(x1::Vector, x2::Expression{Point}) = +(promote(x1,x2)...)


###############################################################################
# Conversion and promotion

# Variable, InnerProduct -> Linear
# Linear, Constant -> Affine
# Number -> Scalar, Expression{Number}
# Vector -> Point, Expression{Point}

# promote_rule(::Type{Linear{T}}, ::Type{Variable{T}}) where {T} = Linear{T}
# promote_rule(::Type{Linear{Scalar}}, ::Type{InnerProduct}) = Linear{Scalar}
# promote_rule(::Type{Affine{T}}, ::Type{Linear{T}}) where {T} = Affine{T}
# promote_rule(::Type{Affine{T}}, ::Type{Constant{T}}) where {T} = Affine{T}
# promote_rule(::Type{Scalar}, ::Type{<:Number}) = Scalar
# promote_rule(::Type{Point}, ::Type{<:Vector}) = Point
# promote_rule(::Type{Linear{T}}, ::Type{<:Constant{T}}) where {T} = Affine{T}
# promote_rule(::Type{Variable{T}}, ::Type{T}) where {T} = Variable{T}

# convert(::Type{Linear{T}}, x::Variable{T}) where {T} = Linear(x)
# convert(::Type{Affine{T}}, x::Linear{T}) where {T} = Affine(x)
# convert(::Type{Affine{T}}, x::Constant{T}) where {T} = Affine(x)
# convert(::Type{Scalar}, x::Number) = Scalar(x)
# convert(::Type{Point}, x::Vector) = Point(x)
# convert(::Type{Variable{T}}, x::T) where {T} = Variable(x)