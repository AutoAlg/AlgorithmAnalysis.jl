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

export Value, Expression, Variable, Variables
export Field, VectorSpace, NormedVectorSpace, InnerProductSpace
export AbstractConstant, Constant, Zero
export AbstractLinear, Linear, AbstractAffine, Affine, InnerProduct
export type, label, label!, evaluate, variables, constraints, weights, hasvalue
export ⊗, linear, constant, ⪯, ⪰
export @field, @innerproductspace, @autolabel

import Base: show, isequal, +, -, *, /, ^, promote_rule, convert, zero, iszero

const Label = Union{String, Symbol}


abstract type Field <: Value{Number} end
abstract type VectorSpace{F<:Field} <: Value{AbstractVector} end
abstract type NormedVectorSpace{F<:Field} <: VectorSpace{F} end
abstract type InnerProductSpace{F<:Field} <: NormedVectorSpace{F} end


###############################################################################
# Macro definitions of value types

"Define a field."
macro field(s::Symbol)
  quote
    mutable struct $(esc(s)) <: Field
      value::Union{Number, Missing}
    end
  end
end

"Define an inner product space."
macro innerproductspace(ex::Expr)
  if !(ex.head == :tuple && length(ex.args) == 2 && ex.args[1] isa Symbol && ex.args[2] isa Symbol)
    throw(ArgumentError("@innerproductspace: `$(ex)` must be of the form: `V, F` where `V` is an inner product space over a field `F`."))
  end
  quote
    mutable struct $(esc(ex.args[1])) <: InnerProductSpace{$(esc(ex.args[2]))}
      value::Union{Vector, Missing}
    end
  end
end


###############################################################################
# Automatic labeling

"Automatic labeling of assignment expressions."
macro autolabel(ex::Expr)
  if ex.head ≠ :(=)
    throw(ArgumentError("@autolabel: `$ex` is not an assigment expression."))
  end
  if ex.args[1] isa Symbol
    quote
      local var = $(esc(ex.args[2]))
      label!(var, $(string(ex.args[1])))
      $(esc(ex.args[1])) = var
    end
  elseif ex.args[1] isa Expr && ex.args[1].head == :tuple
    quote
      local var = $(esc(ex.args[2]))
      label!.(var, $([string(x) for x ∈ ex.args[1].args]))
      $(esc(ex.args[1])) = var
    end
  else
    throw(ArgumentError("@autolabel: `$ex` does not have the correct left-hand side."))
  end
end


###############################################################################
# Value types

+(x1::V, x2::V) where {V<:Value} = V(x1.value + x2.value)

*(a::Number, x::V) where {V<:Value} = V(a*x.value)

"Default constructor for any subtype of `Value`."
(::Type{V})() where {V<:Value} = V(missing)

"Construct any subtype of Expression from its value."
(::Type{E})(x::T) where {T,V<:Value{T},E<:Expression{V}} = E(V(x))


###############################################################################
# Outer product (Gram matrix)

# function ⊗(x1::Vector{<:Expression{V}}, x2::Vector{<:Expression{V}}) where {F<:Field, V<:InnerProductSpace{F}}
#   Expression{F}[ x*y for x ∈ x1, y ∈ x2 ]
# end

⊗(x1::Vector, x2::Vector) = [ x*y for x ∈ x1, y ∈ x2 ]


###############################################################################
# Positive semidefinite

⪰(a::Matrix, b::Matrix) = all(LinearAlgebra.eigvals(a-b) .≥ 0)
⪰(a::Matrix, b::Number) = all(LinearAlgebra.eigvals(a-b*LinearAlgebra.I) .≥ 0)
⪰(a::Number, b::Matrix) = all(LinearAlgebra.eigvals(a*LinearAlgebra.I-b) .≥ 0)
⪯(a::Matrix, b::Matrix) = all(LinearAlgebra.eigvals(a-b) .≤ 0)
⪯(a::Matrix, b::Number) = all(LinearAlgebra.eigvals(a-b*LinearAlgebra.I) .≤ 0)
⪯(a::Number, b::Matrix) = all(LinearAlgebra.eigvals(a*LinearAlgebra.I-b) .≤ 0)


###############################################################################
# Expression
#  .label
#  evaluate, variables, isequal, +, *(::Number, ::Expression)

"Data type that an expression evaluates to."
type(::Expression{T}) where {T} = T

"Set the label of an expression."
label!(x::Expression, label::Label) = (x.label = label; missing)

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
  value::T
  label::Label
  constraints::Constraints
  oracles::Oracles
  
  Variable{T}(label::Label = "") where {T<:Value} = new(T(), label, Constraints(), Oracles())
end

"A set of variables."
const Variables = Set{Variable}

"Initialize an expression as a variable (used when sampling an oracle)."
Expression{T}(label::Label = "") where {T} = Variable{T}(label)

"Add an oracle to all variables in an expression or tuple of expressions."
add_oracle!(x::Expression, o::Oracle) = map(v -> push!(v.oracles, o), collect(variables(x)))
add_oracle!(X::NTuple{N,Expression}, o::Oracle) where {N} = map(x -> add_oracle!(x, o), X)


###############################################################################
# Constant / Linear / Affine

abstract type AbstractAffine{T} <: Expression{T} end
abstract type AbstractLinear{T} <: AbstractAffine{T} end
abstract type AbstractConstant{T} <: AbstractAffine{T} end

"The zero expression."
mutable struct Zero{T} <: AbstractConstant{T}
  label::Label

  Zero{T}(label::Label = "") where {T} = new(label)
end

"A nonzero constant expression."
mutable struct Constant{T} <: AbstractConstant{T}
  value::T
  label::Label
  
  Constant(value::T, label::Label = "") where {T<:Value} = new{T}(value, label)
end

"Check whether or not a constant expression is zero."
iszero(x::Expression) = false
iszero(x::AbstractConstant) = isa(x, Zero)

"A linear expression."
mutable struct Linear{T} <: AbstractLinear{T}
  weights::Dict{Expression{T}, Number}
  label::Label

  Linear{T}(weights::Dict, label::Label = "") where {T} = new(weights, label)
  Linear{T}(label::Label = "") where {T} = new(Dict(), label)
  Linear(x::Expression{T}) where {T} = new{T}(Dict(x => 1), x.label)
end

"An affine expression."
mutable struct Affine{T} <: AbstractAffine{T}
  linear::AbstractLinear{T}
  constant::AbstractConstant{T}
  label::Label

  Affine(linear::AbstractLinear{T}, constant::AbstractConstant{T} = Zero{T}(), label::Label = "") where {T} = new{T}(linear, constant, label)
  Affine(constant::AbstractConstant{T}) where {T} = new{T}(Linear{T}(), constant, "")
  Affine{T}(label::Label = "") where {T} = new(Dict(), Zero{T}(), label)
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

"Construct the zero expression of a given type."
zero(::E, label::Label = "") where {T,E<:Expression{T}} = Zero{T}(label)
zero(::Type{E}, label::Label = "") where {T,E<:Expression{T}} = Zero{T}(label)


###############################################################################
# InnerProduct

"An inner product of two points."
struct InnerProduct{F<:Field, V<:InnerProductSpace{F}} <: Expression{F}
  left::Expression{V}
  right::Expression{V}
  label::Label

  InnerProduct(left::Expression{V}, right::Expression{V}, label::Label = "") where {F<:Field, V<:InnerProductSpace{F}} = hash(left) < hash(right) ? new{F,V}(left, right, label) : new{F,V}(right, left, label)
end

"Inner product of two points."
function *(x1::AbstractLinear{V}, x2::AbstractLinear{V}) where {F<:Field, V<:InnerProductSpace{F}}
  w = Dict{InnerProduct, Number}()
  for (key1, value1) ∈ weights(x1)
    for (key2, value2) ∈ weights(x2)
      mergewith!(+, w, Dict( InnerProduct(key1,key2) => value1*value2 ))
    end
  end
  Linear{F}(w)
end

# convert variables to linear expressions to compute inner products
*(x1::Variable{V}, x2::Variable{V}) where {V<:InnerProductSpace} = Linear(x1)*Linear(x2)
*(x1::Variable{V}, x2::AbstractLinear{V}) where {V<:InnerProductSpace} = Linear(x1)*x2
*(x1::AbstractLinear{V}, x2::Variable{V}) where {V<:InnerProductSpace} = x1*Linear(x2)

# inner product with the zero vector
*(x1::Zero{V}, x2::Zero{V}) where {F<:Field, V<:InnerProductSpace{F}} = Zero{F}()
*(x1::Zero{V}, x2::Expression{V}) where {F<:Field, V<:InnerProductSpace{F}} = Zero{F}()
*(x1::Expression{V}, x2::Zero{V}) where {F<:Field, V<:InnerProductSpace{F}} = Zero{F}()

# inner product of vectors
*(x1::V, x2::V) where {V<:InnerProductSpace}= x1.value'*x2.value

^(x::AbstractLinear{<:InnerProductSpace}, n::Int) = (n == 2 ? x*x : error("Can only square point weights."))
^(x::Variable{<:InnerProductSpace}, n::Int) = (n == 2 ? x*x : error("Can only square point variables."))
^(x::Zero{V}, n::Int) where {F<:Field, V<:InnerProductSpace{F}} = (n == 2 ? Zero{F}() : error("Can only square zero points."))


###############################################################################
# Evaluate

evaluate(x::Expression) = error("Evaluate not implemented for $(typeof(x)).")
evaluate(x::Constant) = evaluate(x.value)
evaluate(x::Zero) = x
evaluate(x::Zero{<:Field}) = 0
evaluate(x::Linear{T}) where {T} = mapreduce( pair -> pair.second * evaluate(pair.first), +, weights(x); init=Zero{T}() )
evaluate(x::Variable) = evaluate(x.value)
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
+(x1::InnerProduct{F,V}, x2::Constant{F}) where {F<:Field, V<:VectorSpace{F}} = Linear(x1) + x2
+(x1::Constant{F}, x2::InnerProduct{F,V}) where {F<:Field, V<:VectorSpace{F}} = Linear(x2) + x1

+(x1::Variable{T}, x2::Variable{T}) where {T} = Linear(x1) + Linear(x2)
+(x1::Variable{T}, x2::Linear{T}) where {T} = Linear(x1) + x2
+(x1::Linear{T}, x2::Variable{T}) where {T} = x1 + Linear(x2)
+(x1::Variable{T}, x2::Affine{T}) where {T} = Linear(x1) + x2
+(x1::Affine{T}, x2::Variable{T}) where {T} = x1 + Linear(x2)
+(x1::Variable{F}, x2::InnerProduct{F,V}) where {F<:Field, V<:VectorSpace{F}} = Linear(x1) + Linear(x2)
+(x1::InnerProduct{F,V}, x2::Variable{F}) where {F<:Field, V<:VectorSpace{F}} = Linear(x1) + Linear(x2)

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
+(x1::Linear{F}, x2::InnerProduct{F,V}) where {F<:Field, V<:VectorSpace{F}} = x1 + Linear(x2)
+(x1::InnerProduct{F,V}, x2::Linear{F}) where {F<:Field, V<:VectorSpace{F}} = x2 + Linear(x1)

+(x1::Affine{F}, x2::InnerProduct{F,V}) where {F<:Field, V<:VectorSpace{F}} = x1 + Linear(x2)
+(x1::InnerProduct{F,V}, x2::Affine{F}) where {F<:Field, V<:VectorSpace{F}} = x2 + Linear(x1)

+(x1::InnerProduct{F,V}, x2::InnerProduct{F,V}) where {F<:Field, V<:VectorSpace{F}} = Linear(x1) + Linear(x2)

+(x1::Expression{T}, x2::T) where {T} = x1 + Constant(x2)
+(x1::T, x2::Expression{T}) where {T} = Constant(x1) + x2

+(x1::Expression{F}, x2::Number) where {F<:Field} = x1 + Constant(F(x2))
+(x1::Number, x2::Expression{F}) where {F<:Field} = Constant(F(x1)) + x2

+(::Expression, ::Missing) = missing
+(::Missing, ::Expression) = missing
+(::Value, ::Missing) = missing
+(::Missing, ::Value) = missing

###############################################################################
# Scaling

*(a::Number, x::Constant{T}) where {T} = Constant(a*x.value, "")
*(a::Number, x::Zero) = x
*(a::Number, x::Variable{T}) where {T} = Linear{T}(Dict(x => a))
*(a::Number, x::Linear{T}) where {T} = Linear{T}(Dict(keys(x.weights) .=> map(v->a*v, values(x.weights))))
*(a::Number, x::Affine{T}) where {T} = Affine{T}(a*x.linear, a*x.constant)
*(a::Number, x::InnerProduct{F,V}) where {F<:Field, V<:VectorSpace{F}} = Linear{F}(Dict(x => a))

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

show(io::IO, x::Zero{T}) where {T} = isempty(x.label) ? print(io, "Zero{$T}") : print(io, x.label)

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
      elseif value == -1
        print(io, " - ", key)
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

function show(io::IO, x::InnerProduct)
  if hasvalue(x)
    print(io, evaluate(x))
  else
    if isequal(x.left,x.right)
      print(io, "$(x.left)²")
    else
      print(io, "⟨$(x.left),$(x.right)⟩")
    end
  end
end

show(io::IO, x::Value) = print(io, x.value)

show(io::IO, p::Pair{<:Expression, <:Expression}) = print(io, p.first, " => ", p.second)


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
hash(c::ConeConstraint, h::UInt) = hash(set(c), hash(expression(c), h))
hash(c::Satisfied, h::UInt) = objectid(c)
hash(c::Unsatisfied, h::UInt) = objectid(c)
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
