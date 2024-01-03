export Oracle, FunctionOracle, OperatorOracle
export ConvexFunction, DifferentiableFunction
export Operator, ContinuousOperator, LinearOperator

import Base.adjoint, Base.∈

# ConvexFunction{X,Y}
#  - f  : X -> Y (unique)
#  - ∂f : X -> X
# 
# DifferentiableFunction
#  - f  : X -> Y (unique)
#  - ∇f : X -> X (unique)
# 
# Operator
#  - f : X -> Y
# 
# ContinuousOperator
#  - MultiRelation{X,Y}
#    - f : 1 -> 2 (unique)
# 
# LinearOperator
#  - MultiRelation{X,Y,Y,X}
#    - A  : 1 -> 2 (unique)
#    - Aᵀ : 3 -> 4 (unique)


###############################################################################
# Oracle

"An oracle is a relation that can be constrained (through interpolation conditions) to be in a class."
abstract type Oracle{R<:Relation} end

"Stationary point of an oracle."
function stationary_point end

"Get the label of an oracle."
label(o::Oracle) = o.label


###############################################################################
# Adjoint oracle

"An adjoint oracle is an oracle that also has an adjoint relation. The semantics of the adjoint depend on the specific type of oracle. For instance, the adjoint of a real linear operator is its transpose, while the adjoint of a convex function is its subdifferential."
abstract type AdjointOracle{Val<:Relation,Adj<:Relation} <: Oracle{Val} end

"Adjoint of an oracle."
struct Adjoint{T<:AdjointOracle}
  parent::T
end

adjoint(o::T) where {T<:AdjointOracle} = Adjoint{T}(o)


###############################################################################
# Sample

"Sample an oracle at a point in the domain of its relation."
(o::Oracle{R})(x::X, label::String = "") where {X,Y,R<:Relation{X,Y}} = o.val(x, label)

"Sample the adjoint of an oracle in the domain of its adjoint relation."
(o::Adjoint{<:AdjointOracle{Val,Adj}})(x::X, label::String = "") where {X,Y,Val,Adj<:Relation{X,Y}} = o.parent.adj(x, label)


###############################################################################
# Show

function show(io::IO, o::Oracle{<:Relation{X,Y}}) where {X,Y}
  println(io, "\n$(label(o)) from $X to $Y")
  println(io, classes(o.val))
  map(p -> println(io, "    ", p), collect(samples(o.val)))
end

function show(io::IO, o::AdjointOracle{<:Relation{X,Y},Adj}) where {X,Y,Adj}
  println(io, "\n$(label(o)) from $X to $Y")
  println(io, "\n$(label(o.val)): ", classes(o.val))
  map(p -> println(io, "    ", p), collect(samples(o.val)))
  println(io, "\n$(label(o.adj)): ", classes(o.adj))
  map(p -> println(io, "    ", p), collect(samples(o.adj)))
end

###############################################################################
# Relation classes

"Specify that an oracle (or its adjoint) belongs to a relation class."
∈(o::AdjointOracle, c::RelationClass) = o.val ∈ c
∈(o::AdjointOracle, c::RelationClasses) = o.val ∈ c
∈(a::Adjoint{<:AdjointOracle}, c::RelationClass) = a.parent.adj ∈ c
∈(a::Adjoint{<:AdjointOracle}, c::RelationClasses) = a.parent.adj ∈ c


###############################################################################
# Concrete oracles

struct ConvexFunction{X,Y} <: AdjointOracle{SingleValued{X,Y},MultiValued{X,X}}
  label::String
  val::SingleValued{X,Y}
  adj::MultiValued{X,X}
  
  ConvexFunction{X,Y}() where {X,Y} = new{X,Y}("Convex function", SingleValued{X,Y}("Function"), MultiValued{X,X}("Subdifferential"))
end

struct DifferentiableFunction{X,Y} <: AdjointOracle{SingleValued{X,Y},SingleValued{X,X}}
  label::String
  val::SingleValued{X,Y}
  adj::SingleValued{X,X}
  
  DifferentiableFunction{X,Y}() where {X,Y} = new{X,Y}("Differentiable function", SingleValued{X,Y}("Function"), SingleValued{X,X}("Gradient"))
end

struct Operator{X,Y} <: Oracle{MultiValued{X,Y}}
  label::String
  val::MultiValued{X,Y}
  
  Operator{X,Y}() where {X,Y} = new{X,Y}("Operator", MultiValued{X,Y}())
end

struct SingleValuedOperator{X,Y} <: Oracle{SingleValued{X,Y}}
  label::String
  val::SingleValued{X,Y}
  
  SingleValuedOperator{X,Y}() where {X,Y} = new{X,Y}("Single-valued operator", SingleValued{X,Y}())
end

struct LinearOperator{X,Y} <: AdjointOracle{SingleValued{X,Y},SingleValued{Y,X}}
  label::String
  val::SingleValued{X,Y}
  adj::SingleValued{Y,X}
  
  LinearOperator{X,Y}() where {X,Y} = new{X,Y}("Linear operator", SingleValued{X,Y}("Operator"), SingleValued{Y,X}("Adjoint"))
end


###############################################################################
# Stationary points

function stationary_point(o::ConvexFunction{X,Y}, xlabel="", flabel="", glabel="") where {X,Y}
  x, f, g = X(xlabel), Y(flabel), zero(X, glabel)
  push!(samples(o.val), x => f)
  push!(samples(o.adj), x => g)
  x, f, g
end

# function stationary_point(o::OperatorOracle)
#   x = Variable{Point}()
#   y = Zero{Point}()
#   push!(samples(o), x, y)
#   x, y
# end






