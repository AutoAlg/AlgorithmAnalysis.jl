export Expression, Field, VectorSpace, NormedVectorSpace, InnerProductSpace, GramMatrix
export Decomposition, LinearDecomposition, AffineDecomposition, Scalars, InnerProduct, VectorDecomposition, ScalarDecomposition
export linear, constant, weights, evaluate, constraints, variables, ⊗, Zero
export label, label!, value, decomposition, selfdecomp, hasvalue, isvariable
export @field, @vectorspace, @normedvectorspace, @innerproductspace, @autolabel

import Base: +, -, *, /, ^, ==, isempty, iszero, promote_rule, convert, show, isequal, zero, adjoint, size

import Zeros: Zero


###############################################################################
# Abstract types

"An abstract expression. Each expression can be a constant (nonzero or zero), a variable (with known or unknown value), or a decomposition (function) of other expressions."
abstract type Expression end

"An abstract field. An element of a field is a scalar. A scalar is an expression that can be an affine function of other scalars and inner products of points in an inner product space over the field."
abstract type Field <: Expression end

"An abstract vector space. A vector is an expression that can be a linear function of other vectors."
abstract type VectorSpace{F<:Field} <: Expression end

"An abstract normed vector space. The squared norm of a vector produces a scalar."
abstract type NormedVectorSpace{F<:Field} <: VectorSpace{F} end

"An abstract inner product space. The inner product of two vectors produces a scalar, and the squared norm is the inner product of a vector with itself."
abstract type InnerProductSpace{F<:Field} <: NormedVectorSpace{F} end

"A Gram matrix over a field."
struct GramMatrix{V<:InnerProductSpace} <: Expression
  label::String
  value::Union{Matrix{Number},Missing}
  decomposition::Matrix
end

"Constructor."
GramMatrix{V}(m::Matrix{F}) where {F<:Field, V<:InnerProductSpace{F}} = GramMatrix{V}( "", missing, (m+m')/2 )

"Inner products over a field."
const InnerProduct{F<:Field} = Tuple{X,X} where {X<:InnerProductSpace{F}}

"The scalars in a field are either elements of the field or the inner product of two vectors over the field."
const Scalars{F} = Union{F,InnerProduct{F}}

zero(x::Tuple{X,X}) where {X<:InnerProductSpace} = (X(Zero()), X(Zero()))
zero(::F) where {F<:Field} = F(0)
zero(::V) where {V<:VectorSpace} = V(Zero())

==(x1::Tuple{X,X}, x2::Tuple{X,X}) where {X<:InnerProductSpace} = iszero(x1[1]-x2[1]) && iszero(x1[2] - x2[2])

adjoint(a::F) where {F<:Field} = a
adjoint(G::GramMatrix) = G

###############################################################################

export Oracle, AbstractOperator, AbstractFunction, AbstractLinearMap
export AbstractSymmetricLinearMap, AbstractSkewSymmetricLinearMap
export AbstractFunctional, AbstractSubdifferentiableFunctional
export AbstractDifferentiableFunctional, AbstractTwiceDifferentiableFunctional
export AbstractInfinitelyDifferentiableFunctional, AbstractLinearFunctional

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


###############################################################################
# Primitive decompositions

"Decomposition of an expression in terms of other expressions."
abstract type Decomposition end

"A linear decomposition."
struct LinearDecomposition{T} <: Decomposition
  weights::Dict{T,Number}

  LinearDecomposition{T}(weights::Dict{<:T,<:Number}) where {T} = new{T}(Dict{T,Number}(weights))
end

"An affine decomposition."
struct AffineDecomposition{T} <: Decomposition
  linear::LinearDecomposition{T}
  constant::Any
end

"Default constructors."
LinearDecomposition{T}() where {T} = LinearDecomposition{T}(Dict{T,Number}())
AffineDecomposition{T}() where {T} = AffineDecomposition{T}(LinearDecomposition{T}(), 0)
AffineDecomposition{T}(x::LinearDecomposition{<:T}) where {T} = AffineDecomposition{T}( LinearDecomposition{T}(x.weights), 0)
AffineDecomposition{T}(weights::Dict{<:T,<:Number}) where {T} = AffineDecomposition{T}( LinearDecomposition{T}(weights), 0)
AffineDecomposition{T}(a::Number) where {T} = AffineDecomposition{T}( LinearDecomposition{T}(), a )

"LinearDecomposition part of a decomposition."
linear(x::LinearDecomposition) = x
linear(x::AffineDecomposition) = x.linear

"Constant part of a decomposition."
constant(x::LinearDecomposition) = error("A linear expression has no constant term.")
constant(x::AffineDecomposition) = x.constant

"Check if a decomposition is empty."
isempty(x::LinearDecomposition) = isempty(x.weights)
isempty(x::AffineDecomposition) = isempty(linear(x)) && iszero(constant(x))

"Weights of the linear part of a decomposition."
weights(x::Decomposition) = linear(x).weights

"Sum two decompositions."
function +(x1::LinearDecomposition{T}, x2::LinearDecomposition{T}) where {T}
  dict = mergewith(+, weights(x1), weights(x2))
  for (key,value) ∈ dict
    if iszero(key) || iszero(value)
      # @show key, value, iszero(key), iszero(value)
      delete!(dict, key)
    end
  end
  LinearDecomposition{T}(dict)
end
+(x1::AffineDecomposition{T}, x2::AffineDecomposition{T}) where {T} = AffineDecomposition{T}( linear(x1) + linear(x2), constant(x1) + constant(x2) )
+(x::AffineDecomposition{T}, a::Number) where {T} = AffineDecomposition{T}( linear(x), constant(x) + a )
+(a::Number, x::AffineDecomposition{T}) where {T} = x + a

"Subtract two decompositions."
-(x1::T, x2::T) where {T<:Decomposition} = x1 + (-x2)

"Scale a decomposition."
*(a::Number, x::LinearDecomposition{T}) where {T} = LinearDecomposition{T}( Dict{T,Number}(keys(weights(x)) .=> map(x->a*x, values(weights(x)))) )
*(a::Number, x::AffineDecomposition{T}) where {T} = AffineDecomposition{T}( a*linear(x), a*constant(x) )
*(x::Decomposition, a::Number) = a*x
/(x::Decomposition, a::Number) = (1/a)*x

"Negate a decomposition."
-(x::Decomposition) = -1*x

"Variables in a decomposition."
variables(x::Decomposition) = Set(keys(weights(x)))


###############################################################################
# Scalar and vector decompositions

mutable struct ScalarDecomposition{F<:Field} <: Decomposition
  scalars::AffineDecomposition{F}
  innerproducts::LinearDecomposition{InnerProduct{F}}
end

mutable struct VectorDecomposition{V<:VectorSpace} <: Decomposition
  vectors::LinearDecomposition{V}
end

"Default constructors."
ScalarDecomposition{F}(a::Number = 0) where {F<:Field} = ScalarDecomposition{F}( AffineDecomposition{F}(a), LinearDecomposition{InnerProduct{F}}() )
VectorDecomposition{V}() where {V<:VectorSpace} = VectorDecomposition{V}( LinearDecomposition{V}() )
VectorDecomposition{V}(weights::Dict{<:V,<:Number}) where {V<:VectorSpace} = VectorDecomposition{V}( LinearDecomposition{V}(weights) )

"LinearDecomposition part of a decomposition."
# linear(x::LinearDecomposition) = x
# linear(x::AffineDecomposition) = x.linear

"Constant part of a decomposition."
constant(x::VectorDecomposition) = error("A vector decomposition does not have a constant term.")
constant(x::ScalarDecomposition) = constant(x.scalars)

"Check if a decomposition is empty."
isempty(x::VectorDecomposition) = isempty(x.vectors)
isempty(x::ScalarDecomposition) = isempty(x.scalars) && isempty(x.innerproducts)

"Weights of the linear part of a decomposition."
weights(x::VectorDecomposition) = weights(x.vectors)

"Sum two decompositions."
+(x1::T, x2::T) where {T<:VectorDecomposition} = T( x1.vectors + x2.vectors )
+(x1::T, x2::T) where {T<:ScalarDecomposition} = T( x1.scalars + x2.scalars, x1.innerproducts + x2.innerproducts )
+(x1::T, x2::Number) where {T<:ScalarDecomposition} = T( x1.scalars + x2, x1.innerproducts )
+(x1::Number, x2::T) where {T<:ScalarDecomposition} = x2 + x1

"Subtract two decompositions."
-(x1::T, x2::Number) where {T<:ScalarDecomposition} = x1 + (-x2)
-(x1::Number, x2::T) where {T<:ScalarDecomposition} = x1 + (-x2)

"Scale a decomposition."
*(a::Number, x::T) where {T<:VectorDecomposition} = T( a*x.vectors )
*(a::Number, x::T) where {T<:ScalarDecomposition} = T( a*x.scalars, a*x.innerproducts )

"Variables in a decomposition."
variables(x::VectorDecomposition) = variables(x.vectors)
variables(x::ScalarDecomposition) = variables(x.scalars) ∪ variables(x.innerproducts)


###############################################################################
# Macro definitions of concrete expression types

"Define a field."
macro field(s::Symbol)
  quote
    mutable struct $(esc(s)) <: Field
      label::String
      value::Union{Number,Missing}
      decomposition::ScalarDecomposition{$(esc(s))}
      constraints::Constraints
    end
  end
end

"Define a vector space over a field."
macro vectorspace(ex::Expr)
  if !(ex.head == :tuple && length(ex.args) == 2 && ex.args[1] isa Symbol && ex.args[2] isa Symbol)
    throw(ArgumentError("@vectorspace: `$(ex)` must be of the form: `V, F` where `V` is a vector space over a field `F`."))
  end
  quote
    mutable struct $(esc(ex.args[1])) <: VectorSpace{$(esc(ex.args[2]))}
      label::String
      value::Union{Vector,Missing,Zero}
      decomposition::VectorDecomposition{$(esc(ex.args[1]))}
      constraints::Constraints
    end
  end
end

"Define a normed vector space over a field."
macro normedvectorspace(ex::Expr)
  if !(ex.head == :tuple && length(ex.args) == 2 && ex.args[1] isa Symbol && ex.args[2] isa Symbol)
    throw(ArgumentError("@normedvectorspace: `$(ex)` must be of the form: `V, F` where `V` is a normed vector space over a field `F`."))
  end
  quote
    mutable struct $(esc(ex.args[1])) <: NormedVectorSpace{$(esc(ex.args[2]))}
      label::String
      value::Union{Vector,Missing,Zero}
      decomposition::VectorDecomposition{$(esc(ex.args[1]))}
      constraints::Constraints
    end
  end
end

"Define an inner product space over a field."
macro innerproductspace(ex::Expr)
  if !(ex.head == :tuple && length(ex.args) == 2 && ex.args[1] isa Symbol && ex.args[2] isa Symbol)
    throw(ArgumentError("@innerproductspace: `$(ex)` must be of the form: `V, F` where `V` is an inner product space over a field `F`."))
  end
  quote
    mutable struct $(esc(ex.args[1])) <: InnerProductSpace{$(esc(ex.args[2]))}
      label::String
      value::Union{Vector,Missing,Zero}
      decomposition::VectorDecomposition{$(esc(ex.args[1]))}
      constraints::Constraints
      dual::LinearFunctional{$(esc(ex.args[1]))}

      function $(esc(ex.args[1]))(label::String, value::Union{Vector,Missing,Zero}, decomposition::VectorDecomposition{$(esc(ex.args[1]))}, constraints::Constraints)
        x = new(label, value, decomposition, constraints, LinearFunctional{$(esc(ex.args[1]))}())
        x.dual.dual = x
        x
      end
    end
  end
end


###############################################################################
# Automatic labeling of values

"Automatic labeling of values."
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
# Methods

label!(e::Expression, label::String) = (e.label = label; nothing)
label(e::Expression) = e.label
value(e::Expression) = e.value
decomposition(e::Expression) = e.decomposition
constraints(e::Expression) = e.constraints
constraints(x::InnerProduct) = constraints(x[1]) ∪ constraints(x[2])
variables(e::Expression) = variables(decomposition(e))
variables(m::Matrix{F}) where {F<:Field} = mapreduce(variables, ∪, m)

# decomposition that defaults to self => 1 if empty
selfdecomp(a::F) where {F<:Field} = isempty(decomposition(a)) ? ScalarDecomposition{F}( AffineDecomposition{F}(Dict(a => 1)), LinearDecomposition{InnerProduct{F}}() ) : decomposition(a)
selfdecomp(v::V) where {V<:VectorSpace} = isempty(decomposition(v)) ? VectorDecomposition{V}(Dict(v => 1)) : decomposition(v)

# types of expressions
iszero(e::Expression) = hasvalue(e) && iszero(value(e))
hasvalue(e::Expression) = !ismissing(value(e))
isvariable(e::Expression) = !hasvalue(e) && isempty(decomposition(e))


###############################################################################
# Constructors

# variable
(::Type{F})(label::String = "") where {F<:Field} = F(label, missing, ScalarDecomposition{F}(), Constraints())
(::Type{V})(label::String = "") where {V<:VectorSpace} = V(label, missing, VectorDecomposition{V}(), Constraints())

# constant
(::Type{F})(value::Number) where {F<:Field} = F("", value, ScalarDecomposition{F}(), Constraints())
(::Type{V})(value::Union{Vector,Zero}) where {V<:VectorSpace} = V("", value, VectorDecomposition{V}(), Constraints())

# decomposition (if the decomposition is empty, set the value to zero)
(::Type{F})(decomposition::ScalarDecomposition{<:F}) where {F<:Field} = isempty(decomposition) ? F(0) : F("", missing, decomposition, Constraints())
(::Type{V})(decomposition::VectorDecomposition{<:V}) where {V<:VectorSpace} = isempty(decomposition) ? V(Zero()) : V("", missing, decomposition, Constraints())

# value and decomposition (if the decomposition is empty, set the value to zero)
(::Type{F})(value::Union{Number,Missing}, decomposition::ScalarDecomposition{<:F}) where {F<:Field} = isempty(decomposition) ? F(0) : F("", value, decomposition, Constraints())
(::Type{V})(value::Union{Vector,Missing,Zero}, decomposition::VectorDecomposition{<:V}) where {V<:VectorSpace} = isempty(decomposition) ? V(Zero()) : V("", value, decomposition, Constraints())


###############################################################################
# Algebra

# Expressions
+(e1::E, e2::E) where {E<:Expression} = E( value(e1) + value(e2), selfdecomp(e1) + selfdecomp(e2) )
+(e1::Expression, e2::Expression) = +(promote(e1,e2)...)
-(e1::Expression, e2::Expression) = e1 + (-e2)
-(e::Expression) = -1*e
*(a::Number, e::E) where {E<:Expression} = E( a*value(e), a*selfdecomp(e) )
*(e::Expression, a::Number) = a*e
/(e::Expression, a::Number) = (1/a)*e

# Scalars with numbers
+(a1::F, a2::Number) where {F<:Field} = F( value(a1) + a2, selfdecomp(a1) + a2 )
+(a1::Number, a2::Field) = +(promote(a1,a2)...)
-(a1::Field, a2::Number) = a1 + (-a2)
-(a1::Number, a2::Field) = a1 + (-a2)

"Convert and promote numbers to scalars."
promote_rule(::Type{F}, ::Type{<:Number}) where {F<:Field} = F
convert(::Type{F}, a::Number) where {F<:Field} = F(a)

"Inner product of two vectors."
function *(v1::V, v2::V) where {F<:Field, V<:InnerProductSpace{F}}
  w = Dict{InnerProduct{F}, Number}()
  for (key1, value1) ∈ weights(selfdecomp(v1))
    for (key2, value2) ∈ weights(selfdecomp(v2))
      mergewith!(+, w, Dict( (key1,key2) => value1*value2 ))
    end
  end
  F( ScalarDecomposition{F}( AffineDecomposition{F}(), LinearDecomposition{InnerProduct{F}}(w) ) )
end

*(v1::InnerProductSpace, v2::InnerProductSpace) = *(promote(v1,v2)...)

"Squared norm of a vector in a normed vector space."
^(v::NormedVectorSpace, n::Int) = (n == 2 ? v*v : error("Can only take inner product of points."))

"Outer product (Gram matrix) of two vectors whose elements are themselves vectors in the same inner product space."
⊗(x1::Vector{V}, x2::Vector{V}) where {V<:InnerProductSpace} = GramMatrix{V}([ x*y for x ∈ x1, y ∈ x2 ])

function +(G::GramMatrix{V}, a::Number) where {V<:InnerProductSpace}
  m = copy(decomposition(G))
  for i = 1:size(G,1)
    m[i,i] += a
  end
  GramMatrix{V}( label(G), value(G), m )
end
+(a::Number, G::GramMatrix) = G + a
-(G::GramMatrix, a::Number) = G + (-a)
-(a::Number, G::GramMatrix) = a + (-G)

function *(a::Number, G::GramMatrix{V}) where {V<:InnerProductSpace}
  m = copy(decomposition(G))
  for i = 1:size(G,1)
    for j = 1:size(G,2)
      m[i,j] *= a
    end
  end
  GramMatrix{V}( label(G), value(G), m )
end
*(G::GramMatrix, a::Number) = a*G

size(G::GramMatrix, n::Int) = size(decomposition(G), n)

###############################################################################
# Evaluate

function evaluate(e::Expression)
  if hasvalue(e)
    return iszero(e) ? 0 : value(e)
  end
  isvariable(e) ? missing : evaluate(decomposition(e))
end
evaluate(x::LinearDecomposition) = mapreduce( pair -> pair.second*evaluate(pair.first), +, weights(x); init=0 )
evaluate(x::AffineDecomposition) = evaluate(linear(x)) + constant(x)
evaluate(p::Tuple{X,X}) where {X<:InnerProductSpace} = evaluate(p[1])'*evaluate(p[2])

evaluate(t::Tuple{LinearDecomposition{F},AffineDecomposition{InnerProduct{F}}}) where {F<:Field} = evaluate(t[1]) + evaluate(t[2])


###############################################################################
# Show

show(io::IO, x::VectorDecomposition{V}) where {V<:VectorSpace} = print(io, x.vectors)
show(io::IO, mime::MIME"text/plain", x::VectorDecomposition{V}) where {V<:VectorSpace} = show(io, mime, x.vectors)

function show(io::IO, x::ScalarDecomposition{F}) where {F<:Field}
  print(io, x.scalars)
  isempty(x.scalars) ? nothing : print(io, " + ")
  print(io, x.innerproducts)
end

function show(io::IO, mime::MIME"text/plain", x::ScalarDecomposition{F}) where {F<:Field}
  show(io, mime, linear(x.scalars))
  show(io, mime, x.innerproducts)
  !iszero(constant(x)) && print(io, "  "^get(io, :indent, 0), constant(x))
end

function show(io::IO, x::LinearDecomposition)
  first = true
  for (key, value) ∈ weights(x)
    k = (key isa Tuple ? "⟨$(key[1]),$(key[2])⟩" : key)
    if first
      first = false
      if value == 1
        print(io, k)
      elseif value == -1
        print(io, "-", k)
      else
        print(io, value, " ", k)
      end
    else
      if value == 1
        print(io, " + ", k)
      elseif value == -1
        print(io, " - ", k)
      elseif value ≥ 0
        print(io, " + ", value, " ", k)
      else
        print(io, " - ", -value, " ", k)
      end
    end
  end
end

function show(io::IO, mime::MIME"text/plain", x::LinearDecomposition)
  isempty(x) && return println(io, "  "^get(io, :indent, 0), "(empty)")
  map( p -> println(io, "  "^get(io, :indent, 0), p.first, " => ", p.second), collect(x.weights))
end

function show(io::IO, x::AffineDecomposition)
  print(io, linear(x))
  !iszero(constant(x)) && print(io, " + ", constant(x))
end

function show(io::IO, mime::MIME"text/plain", x::AffineDecomposition)
  show(io, mime, linear(x))
  !iszero(constant(x)) && print(io, "  "^get(io, :indent, 0), constant(x))
end

function show(io::IO, e::Expression)
  if hasvalue(e)
    if iszero(e)
      print(io, 0)
    else
      print(io, value(e))
    end
  elseif !isempty(label(e))
    print(io, label(e))
  elseif !isempty(decomposition(e))
    print(io, decomposition(e))
  else
    print(io, "Variable{$(typeof(e))}")
  end
end

show(io::IO, G::GramMatrix) = print(io, decomposition(G))

function show(io::IO, mime::MIME"text/plain", v::VectorSpace)
  println(io, "\nVector in $(typeof(v))")
  println(io, "  Value: ", iszero(v) ? "zero" : value(v))
  println(io, "  Decomposition:")
  show(IOContext(io, :indent => get(io,:indent,0)+2), mime, decomposition(v))
end

function show(io::IO, mime::MIME"text/plain", a::Field)
  println(io, "\nScalar in $(typeof(a))")
  println(io, "  Value: ", value(a))
  println(io, "  Decomposition:")
  show(IOContext(io, :indent => get(io,:indent,0)+2), mime, decomposition(a))
end

function show(io::IO, mime::MIME"text/plain", G::GramMatrix{V}) where {V<:InnerProductSpace}
  # println("Gram matrix in $(typeof(G))")
  # display(G.decomposition)
  println(io, "\nGram matrix of vectors in $V")
  println(io, "  Value: ", value(G))
  println(io, "  Decomposition:\n")
  show(IOContext(io, :indent => get(io,:indent,0)+2), mime, decomposition(G))
end


###############################################################################
# IsEqual

isequal(x1::Expression, x2::Expression) = false
isequal(x1::LinearDecomposition{T}, x2::LinearDecomposition{T}) where {T} = isequal(weights(x1), weights(x2))
isequal(x1::AffineDecomposition{T}, x2::AffineDecomposition{T}) where {T} = isequal(linear(x1), linear(x2)) && isequal(constant(x1), constant(x2))
isequal(x1::AbstractArray{<:Expression}, x2::Expression) = false
isequal(x1::Expression, x2::AbstractArray{<:Expression}) = false
isequal(a1::AbstractArray{E}, a2::AbstractArray{E}) where {E<:Expression} = size(a1) == size(a2) && all( isequal(a1[i],a2[i]) for i ∈ eachindex(a1) )

function isequal(x1::T, x2::T) where {T<:Expression}
  isvariable(x1) && isvariable(x2) && return isequal(objectid(x1), objectid(x2))
  !isvariable(x1) && !isvariable(x2) && return isequal(value(x1), value(x2)) && isequal(decomposition(x1), decomposition(x2))
  false
end