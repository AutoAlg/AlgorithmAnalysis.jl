export Oracle, FunctionOracle, OperatorOracle
export ConvexFunction, DifferentiableFunction
export Operator, ContinuousOperator, LinearOperator
export ∂, ∇

import Base.adjoint, Base.∈

# ConvexFunction
#  - MultiRelation{X,Y,X}
#    - f  : 1 -> 2 (unique)
#    - ∂f : 1 -> 3
# 
# DifferentiableFunction
#  - MultiRelation{X,Y,X}
#    - f  : 1 -> 2 (unique)
#    - ∇f : 1 -> 3 (unique)
# 
# Operator
#  - MultiRelation{X,Y}
#    - f : 1 -> 2
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

"An oracle is a set of relations whose interpolation conditions are connected."
abstract type Oracle end

"Adjoint of an oracle. The semantics of the adjoint depend on the specific oracle. For instance, the adjoint of a linear operator is the standard adjoint (transpose), while the adjoint of a convex function is its subdifferential."
struct Adjoint{T<:Oracle}
  parent::T

  Adjoint(parent::T) where {T} = new{T}(parent)
end

adjoint(o::Oracle) = Adjoint(o)

"Stationary point of an oracle."
function stationary_point end



###############################################################################
# Function oracle

"An abstract function oracle with domain `X` and codomain `Y`."
abstract type FunctionOracle{X,Y} <: Oracle end

"Sample a function at a point in its domain."
(f::FunctionOracle)(x) = f.value(x)

mutable struct ConvexFunction{X,Y} <: FunctionOracle{X,Y}
  value::SingleValued{X,Y}
  subdifferential::MultiValued{X,X}

  ConvexFunction{X,Y}() where {X,Y} = new(SingleValued{X,Y}(), MultiValued{X,X}())
end

(f::ConvexFunction{X,Y})(x::X) where {X,Y} = f.value(x)
(f::Adjoint{ConvexFunction{X,Y}})(x::X) where {X,Y} = f.parent.subdifferential(x)



mutable struct DifferentiableFunction{X,Y} <: FunctionOracle{X,Y}
  value::SingleValued{X,Y}
  gradient::SingleValued{X,X}

  DifferentiableFunction{X,Y}() where {X,Y} = new(SingleValued{X,Y}(), SingleValued{X,X}())
end

(f::DifferentiableFunction{X,Y})(x::X) where {X,Y} = f.value(x)
(f::Adjoint{DifferentiableFunction{X,Y}})(x::X) where {X,Y} = f.parent.gradient(x)


###############################################################################
# Operator oracle

"An abstract operator oracle with domain `X` and codomain `Y`."
abstract type OperatorOracle{X,Y} <: Oracle end

"Sample an operator at a point in its domain."
(f::OperatorOracle)(x) = f.op(x)

mutable struct Operator{X,Y} <: OperatorOracle{X,Y}
  op::MultiValued{X,Y}

  Operator{X,Y}() where {X,Y} = new(MultiValued{X,Y}())
end

mutable struct ContinuousOperator{X,Y} <: OperatorOracle{X,Y}
  op::SingleValued{X,Y}

  ContinuousOperator{X,Y}() where {X,Y} = new(SingleValued{X,Y}())
end

mutable struct LinearOperator{X,Y} <: OperatorOracle{X,Y}
  op::SingleValued{X,Y}
  adj::SingleValued{Y,X}

  LinearOperator{X,Y}() where {X,Y} = new(SingleValued{X,Y}(), SingleValued{Y,X}())
end

adjoint(A::LinearOperator) = A.adj


###############################################################################
# Stationary points

function stationary_point(o::ConvexFunction{X,Y}) where {X,Y}
  x = X()
  f = Y()
  g = zero(X) # Zero{Point}()
  push!(samples(o.value), x => f)
  push!(samples(o.subdifferential), x => g)
  x, f, g
end

function stationary_point(o::OperatorOracle)
  x = Variable{Point}()
  y = Zero{Point}()
  push!(samples(o), x, y)
  x, y
end


###############################################################################
# Relation classes

"Specify that an oracle (or its adjoint) belongs to a relation class."
∈(o::FunctionOracle, c::RelationClass) = o.value ∈ c
∈(o::FunctionOracle, c::RelationClasses) = o.value ∈ c
∈(o::OperatorOracle, c::RelationClass) = o.op ∈ c
∈(o::OperatorOracle, c::RelationClasses) = o.value ∈ c
∈(a::Adjoint{<:ConvexFunction}, c::RelationClass) = a.parent.subdifferential ∈ c
∈(a::Adjoint{<:ConvexFunction}, c::RelationClasses) = a.parent.subdifferential ∈ c
∈(a::Adjoint{<:DifferentiableFunction}, c::RelationClass) = a.parent.gradient ∈ c
∈(a::Adjoint{<:DifferentiableFunction}, c::RelationClasses) = a.parent.gradient ∈ c