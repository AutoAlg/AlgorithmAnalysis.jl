export Oracle, Dual, DualOracle, FunctionOracle, OperatorOracle, Functional
export ConvexFunction, DifferentiableFunction
export Operator, ContinuousOperator, LinearOperator
export samples, relation, get_oracle

import Base.adjoint, Base.∈, Base.*, Base.push!


# Oracle (o,o',o'',...)
#  - AbstractOperator: o: X → Y
#    - MultiValuedOperator*
#    - AbstractFunction
#      - SingleValuedOperator*
#      - AbstractLinearMap: tranpose o': Y → X (Function)
#        - LinearMap*
#        - AbstractSymmetricLinearMap: o' = o: X → X
#          - SymmetricLinearMap*
#        - AbstractSkewSymmetricLinearMap: o' = -o: X → X
#          - SkewSymmetricLinearMap*
#      - AbstractFunctional: o: X → R
#        - Functional*
#        - AbstractSubdifferentiableFunctional: subdifferential o': X ⇉ X (Operator)
#          - SubdifferentiableFunctional*
#          - AbstractDifferentiableFunctional: gradient o': X → X (Function)
#            - DifferentiableFunctional*
#            - AbstractTwiceDifferentiableFunctional: hessian o'': X → X ⊗ X (Function)
#              - TwiceDifferentiableFunctional*
#              - QuadraticFunctional*

# some constraint classes dictate what dual operators are available (e.g., linear implies that o' is the adjoint)
# some constraint classes simplify the structure of the oracle (e.g., symmetric implies o' = o)
# other classes don't do either (e.g., monotone)


###############################################################################

export Oracle, AbstractOperator, AbstractFunction, AbstractLinearMap
export AbstractSymmetricLinearMap, AbstractSkewSymmetricLinearMap
export AbstractFunctional, AbstractSubdifferentiableFunctional
export AbstractDifferentiableFunctional, AbstractTwiceDifferentiableFunctional

abstract type AbstractOperator{X,Y} <: Oracle end
abstract type AbstractFunction{X,Y} <: AbstractOperator{X,Y} end
abstract type AbstractLinearMap{X,Y} <: AbstractFunction{X,Y} end
abstract type AbstractSymmetricLinearMap{X} <: AbstractLinearMap{X,X} end
abstract type AbstractSkewSymmetricLinearMap{X} <: AbstractLinearMap{X,X} end
abstract type AbstractFunctional{X,F} <: AbstractFunction{X,F} end
abstract type AbstractSubdifferentiableFunctional{X,F} <: AbstractFunctional{X,F} end
abstract type AbstractDifferentiableFunctional{X,F} <: AbstractSubdifferentiableFunctional{X,F} end
abstract type AbstractTwiceDifferentiableFunctional{X,F} <: AbstractDifferentiableFunctional{X,F} end


###############################################################################
# Associations

export Transpose, AbstractDifferential, AbstractSubdifferential
export Subdifferential, Gradient, Hessian

abstract type Association end

"Generic wrapper for the transpose of a linear function."
struct Transpose{T<:AbstractLinearMap} <: Association
  parent::T
end

abstract type AbstractDifferential <: Association end
abstract type AbstractSubdifferential <: AbstractDifferential end

"Generic wrapper for the subdifferential of a subdifferentiable functional."
struct Subdifferential{T<:AbstractSubdifferentiableFunctional} <: AbstractSubdifferential
  parent::T
end

"Generic wrapper for the gradient of a differentiable functional."
struct Gradient{T<:AbstractDifferentiableFunctional} <: AbstractSubdifferential
  parent::T
end

"Generic wrapper for the Hessian of a twice-differentiable functional."
struct Hessian{T<:AbstractTwiceDifferentiableFunctional} <: AbstractDifferential
  parent::T
end

import Base.adjoint

"For an oracle o, the notation o', o'', ... is used to access its related operators. The available operators and their properties depend on the type of oracle. For instance, o' of a linear operator is its transpose, while o' of a differentiable operator is its gradient."
adjoint(o::Oracle) = error("Oracle $o does not have an associated operator o'. To specify a related operator, specialize `adjoint` for this oracle type.")
adjoint(o::AbstractDifferential) = error("Differential $o does not have an associated operator o'. To specify a related operator, specialize `adjoint' for this differential type.")
adjoint(o::AbstractLinearMap) = Transpose{typeof(o)}(o)
adjoint(o::Transpose{<:AbstractLinearMap}) = o.parent
adjoint(o::AbstractSymmetricLinearMap) = o
adjoint(o::AbstractSkewSymmetricLinearMap) = -o
adjoint(o::AbstractSubdifferentiableFunctional) = Subdifferential{typeof(o)}(o)
adjoint(o::AbstractDifferentiableFunctional) = Gradient{typeof(o)}(o)
adjoint(o::Gradient{<:AbstractTwiceDifferentiableFunctional}) = Hessian{typeof(o.parent)}(o.parent)


###############################################################################
# Class

export Class, Classes

abstract type Class end
const Classes = Set{Class}


###############################################################################
# Concrete oracles
# 
# Every oracle has the following fields:
#  - label::String
#  - class::Classes

export MultiValuedOperator, SingleValuedOperator, LinearMap, SymmetricLinearMap, SkewSymmetricLinearMap
export Functional, SubdifferentiableFunctional, DifferentiableFunctional
export TwiceDifferentiableFunctional, QuadraticFunctional

struct MultiValuedOperator{X,Y} <: AbstractOperator{X,Y}
  label::String
  classes::Classes
  value::Set{Pair{X,Y}}
  
  MultiValuedOperator{X,Y}() where {X,Y} = new{Expression{X},Expression{Y}}("", Classes(), Set{Pair{X,Y}}())
end

struct SingleValuedOperator{X,Y} <: AbstractFunction{X,Y}
  label::String
  classes::Classes
  value::Dict{X,Y}
  
  SingleValuedOperator{X,Y}() where {X,Y} = new{Expression{X},Expression{Y}}("", Classes(), Dict{X,Y}())
end

struct LinearMap{X,Y} <: AbstractLinearMap{X,Y}
  label::String
  classes::Classes
  value::SingleValuedOperator{X,Y}
  transpose::SingleValuedOperator{Y,X}
  
  LinearMap{X,Y}() where {X,Y} = new{Expression{X},Expression{Y}}("", Classes(), SingleValuedOperator{X,Y}(), SingleValuedOperator{Y,X}())
end

struct SymmetricLinearMap{X} <: AbstractSymmetricLinearMap{X}
  label::String
  classes::Classes
  value::SingleValuedOperator{X,X}
  
  SymmetricLinearMap{X}() where {X} = new{Expression{X}}("", Classes(), SingleValuedOperator{X,X}())
end

struct SkewSymmetricLinearMap{X} <: AbstractSkewSymmetricLinearMap{X}
  label::String
  classes::Classes
  value::SingleValuedOperator{X,X}
  
  SkewSymmetricLinearMap{X}() where {X} = new{Expression{X}}("", Classes(), SingleValuedOperator{X,X}())
end

struct Functional{X,F} <: AbstractFunctional{X,F}
  label::String
  classes::Classes
  value::SingleValuedOperator{X,F}
  
  Functional{X}() where {F<:Field, X<:VectorSpace{F}} = new{Expression{X},Expression{F}}("", Classes(), SingleValuedOperator{X,F}())
end

struct SubdifferentiableFunctional{X,F} <: AbstractSubdifferentiableFunctional{X,F}
  label::String
  classes::Classes
  value::SingleValuedOperator{X,F}
  subdifferential::MultiValuedOperator{X,X}
  
  SubdifferentiableFunctional{X}() where {F<:Field, X<:VectorSpace{F}} = new{Expression{X},Expression{F}}("", Classes(), SingleValuedOperator{X,F}(), MultiValuedOperator{X,X}())
end

struct DifferentiableFunctional{X,F} <: AbstractDifferentiableFunctional{X,F}
  label::String
  classes::Classes
  value::SingleValuedOperator{X,F}
  gradient::SingleValuedOperator{X,X}
  
  DifferentiableFunctional{X}() where {F<:Field, X<:VectorSpace{F}} = new{Expression{X},Expression{F}}("", Classes(), SingleValuedOperator{X,F}(), SingleValuedOperator{X,X}())
end

struct TwiceDifferentiableFunctional{X,F} <: AbstractTwiceDifferentiableFunctional{X,F}
  label::String
  classes::Classes
  value::SingleValuedOperator{X,F}
  gradient::SingleValuedOperator{X,X}
  hessian::SingleValuedOperator{X,SingleValuedOperator{X,X}}
  
  TwiceDifferentiableFunctional{X}() where {F<:Field, X<:VectorSpace{F}} = new{Expression{X},Expression{F}}("", Classes(), SingleValuedOperator{X,F}(), SingleValuedOperator{X,X}(), SingleValuedOperator{X,SingleValuedOperator{X,X}}())
end

struct QuadraticFunctional{X,F} <: AbstractTwiceDifferentiableFunctional{X,F}
  label::String
  classes::Classes
  value::SingleValuedOperator{X,F}
  gradient::Functional{X,F}
  hessian::SymmetricLinearMap{X}
  
  QuadraticFunctional{X}() where {F<:Field, X<:VectorSpace{F}} = new{Expression{X},Expression{F}}("", Classes(), SingleValuedOperator{X,F}(), Functional{X,F}(), SymmetricLinearMap{X}())
end


###############################################################################
# Methods

export get_root_oracle, samples, operator

"Get the root oracle from its association."
get_root_oracle(o::Oracle) = o
get_root_oracle(o::Association) = get_root_oracle(o.parent)

"Get the samples associated with an oracle or its association."
samples(o::Oracle) = samples(o.value)
samples(o::Union{SingleValuedOperator,MultiValuedOperator}) = o.value
samples(o::Transpose{<:AbstractLinearMap}) = samples(get_root_oracle(o).transpose)
samples(o::Subdifferential{<:AbstractSubdifferentiableFunctional}) = samples(get_root_oracle(o).subdifferential)
samples(o::Gradient{<:AbstractDifferentiableFunctional}) = samples(get_root_oracle(o).gradient)
samples(o::Hessian{<:AbstractTwiceDifferentiableFunctional}) = samples(get_root_oracle(o).hessian)

"Get the operator associated with an oracle or its association."
operator(o::Oracle) = operator(o.value)
operator(o::Union{SingleValuedOperator,MultiValuedOperator}) = o
operator(o::Transpose{<:AbstractLinearMap}) = operator(get_root_oracle(o).transpose)
operator(o::Subdifferential{<:AbstractSubdifferentiableFunctional}) = operator(get_root_oracle(o).subdifferential)
operator(o::Gradient{<:AbstractDifferentiableFunctional}) = operator(get_root_oracle(o).gradient)
operator(o::Hessian{<:AbstractTwiceDifferentiableFunctional}) = operator(get_root_oracle(o).hessian)


###############################################################################
# Iterate

import Base.length, Base.iterate

length(o::Union{Oracle,Association}) = length(samples(o))

"Iterate over the samples of an oracle."
iterate(o::Union{Oracle,Association}) = iterate(samples(o))
iterate(o::Union{Oracle,Association}, state::Int) = iterate(samples(o), state)


###############################################################################
# Sample

import Base.*

"Sample an oracle at a point in its domain."
(o::Union{Oracle,Association})(x) = operator(o)(x)

function (o::MultiValuedOperator{<:X,Y})(x::X) where {X,Y}
  y = Y()
  push!(samples(o), x => y)
  y
end

function (o::SingleValuedOperator{<:X,Y})(x::X) where {X, Y}
  if x ∈ keys(samples(o))
    samples(o)[x]
  else
    y = Y()
    push!(samples(o), x => y)
    y
  end
end

"For linear maps, also use * to denote sampling."
*(o::Union{AbstractLinearMap,Association}, x) = o(x)
*(o::MultiValuedOperator{<:X,Y}, x::X) where {X,Y} = o(x)
*(o::SingleValuedOperator{<:X,Y}, x::X) where {X,Y} = o(x)


###############################################################################
# Methods

export label, label!, classes

import Base.∈

label(o::Oracle) = o.label
label!(o::Oracle, label::String) = (o.label = label)

classes(o::Union{Oracle,Association}) = operator(o).classes

∈(o::Union{Oracle,Association}, class::Class) = push!(classes(o), class)
∈(o::Union{Oracle,Association}, classes::Classes) = map(class -> o ∈ class, classes)


###############################################################################
# Show

import Base.show

function show(io::IO, c::Classes)
  first = true
  for c ∈ collect(c)
    first ? (print(io, typeof(c)); first = false) : print(io, ", ", typeof(c))
  end
end

function show(io::IO, o::AbstractOperator{X,Y}) where {X,Y}
  println(io, "\nOperator from $(type(X())) to $(type(Y())): $(classes(o))")
  map(p -> println(io, "    ", p), collect(samples(o)))
end

function show(io::IO, o::AbstractLinearMap{X,Y}) where {X,Y}
  println(io, "\nOperator from $(type(X())) to $(type(Y())): $(classes(o))")
  map(p -> println(io, "    ", p), collect(samples(o)))
  println(io, "\nAdjoint operator from $(type(Y())) to $(type(X())): $(classes(o'))")
  map(p -> println(io, "    ", p), collect(samples(o')))
end



# ###############################################################################
# # Oracle

# "Stationary point of an oracle."
# function stationary_point end

# "Get the label of an oracle."
# label(o::Oracle) = o.label

# classes(o::Oracle) = o.classes

# ∈(o::Oracle, class::RelationClass) = push!(classes(o), class)
# ∈(o::Oracle, classes::RelationClasses) = map(class -> o ∈ class, classes)


# ###############################################################################
# # Dual oracle

# "A dual oracle is an oracle that also has a dual relation. The semantics of the dual depend on the specific type of oracle. For instance, the dual of a linear operator is its adjoint (conjugate transpose), while the dual of a convex function is its subdifferential. The dual of an oracle `o` can be accessed by `o'`."
# abstract type DualOracle{X,Y,U,V} <: Oracle{X,Y} end

# "Generic wrapper for the dual of an object."
# struct Dual{T}
#   primal::T
# end

# adjoint(o::T) where {T<:DualOracle} = Dual{T}(o)

# "A primal or dual oracle on X × Y."
# const PrimalOrDual{X,Y} = Union{Oracle{X,Y}, Dual{<:DualOracle{x,y,X,Y}}}

# "Get the relation corresponding to an oracle."
# relation(o::PrimalOrDual) = error("relation not implemented for oracle $o")

# "Get the oracle from either an oracle or its dual."
# get_oracle(o::Oracle) = o
# get_oracle(o::Dual{<:DualOracle}) = o.primal

# "Sample an oracle (or its dual) at a point in the domain of its relation (or dual relation)."
# function (o::PrimalOrDual{X,Y})(x::X) where {X,Y}
#   y = relation(o)(x)
#   add_oracle!(x, get_oracle(o))
#   add_oracle!(y, get_oracle(o))
#   y
# end

# # Can use o(x) or o*x to sample an oracle (or its dual) at a point
# *(o::PrimalOrDual{X,Y}, x::X) where {X,Y} = o(x)

# samples(o::PrimalOrDual) = samples(relation(o))

# # evaluate(o::PrimalOrDual{X,Y}, x::X) where {X,Y} = evaluate(relation(o), x)

# "Push a single sample onto either the primal or dual oracle."
# push!(o::PrimalOrDual{X,Y}, p::Pair{<:X,<:Y}) where {X,Y} = push!(samples(o), p)
# push!(o::PrimalOrDual{X,Y}, x::X, y::Y) where {X,Y} = push!(samples(o), x => y)

# "Push a primal-dual pair onto an oracle."
# function push!(o::DualOracle{X,Y,U,V}, p1::Pair{<:X,<:Y}, p2::Pair{<:U,<:V}) where {X,Y,U,V}
#   push!(o,  p1)
#   push!(o', p2)
# end
# push!(o::DualOracle{X,Y,U,V}, x::X, y::Y, u::U, v::V) where {X,Y,U,V} = push!(o, x => y, u => v)


# ###############################################################################
# # Inputs / outputs

# inputs(o::PrimalOrDual) = iinputs(relation(o))
# outputs(o::PrimalOrDual) = outputs(relation(o))

# inputs(p::Oracle, d::Dual{<:DualOracle}) = inputs(p) ∪ inputs(d)
# outputs(p::Oracle, d::Dual{<:DualOracle}) = outputs(p) ∪ outputs(d)


# ###############################################################################
# # Iterate

# length(o::PrimalOrDual) = length(samples(o))

# "Iterate over the samples of an oracle."
# iterate(o::PrimalOrDual) = iterate(o,1)
# iterate(o::PrimalOrDual, state::Int) = (state > length(o) ? nothing : ( collect(samples(o))[state], state+1))


# ###############################################################################
# # Show

# function show(io::IO, o::Oracle{X,Y}) where {X,Y}
#   println(io, "\n$(label(o)) from $(type(X())) to $(type(Y())): $(classes(o))")
#   println(io, classes(relation(o)))
#   map(p -> println(io, "    ", p), collect(samples(relation(o))))
# end

# function show(io::IO, o::DualOracle{X,Y,U,V}) where {X,Y,U,V}
#   println(io, "\n$(label(o)) from $(type(X())) to $(type(Y())): $(classes(o))")
#   println(io, "\n$(label(relation(o))): ", classes(relation(o)))
#   map(p -> println(io, "    ", p), collect(samples(relation(o))))
#   println(io, "\n$(label(relation(o'))): ", classes(relation(o')))
#   map(p -> println(io, "    ", p), collect(samples(o')))
# end










###############################################################################
# Relation classes

# "Specify that an oracle (or its adjoint) belongs to a relation class (or set of relation classes)."
# ∈(o::PrimalOrDual, c::RelationClass) = relation(o) ∈ c
# ∈(o::PrimalOrDual, c::RelationClasses) = relation(o) ∈ c


###############################################################################
# Concrete oracles



# "A functional is a function from an inner product space `X` to its underlying field `F`."
# struct Functional{X,F} <: DualOracle{Relation{X,F},Relation{X,X}}
#   primal::Relation{X,F}
#   dual::Relation{X,X}
#   classes::RelationClasses

#   function Functional{X}(classes::RelationClasses) where {F<:Field, X<:InnerProductSpace{F}}
#     new{X,F}(MultiValued{X,F}(), MultiValued{X,X}(), classes)
#   end
# end

# Functional{X}(class::RelationClass) where {F<:Field, X<:InnerProductSpace{F}} = Functional{X}(RelationClasses([class]))
# Functional{X}(classes::Vector{<:RelationClass}) where {F<:Field, X<:InnerProductSpace{F}} = Functional{X}(RelationClasses(classes))

# function show(io::IO, o::Functional{X,F}) where {X,F}
#   println(io, "\nFunctional from $X to $F")
#   # println(io, "\n$(label(relation(o))): ", classes(relation(o)))
#   # map(p -> println(io, "    ", p), collect(samples(relation(o))))
#   # println(io, "\n$(label(relation(o'))): ", classes(relation(o')))
#   # map(p -> println(io, "    ", p), collect(samples(o')))
# end

# label!(f::Functional, label::Label) = (f.label = label)


# ###############################################################################
# struct ConvexFunction{X,F} <: Functional{X}
#   label::String
#   value::SingleValued{X,F}
#   subdifferential::MultiValued{X,X}
#   classes::RelationClasses
  
#   function ConvexFunction{X}() where {F<:Field, X<:InnerProductSpace{F}}
#     label = "Convex function"
#     value = SingleValued{Expression{X},Expression{F}}("Function")
#     subdifferential = MultiValued{Expression{X},Expression{X}}("Subdifferential")
#     classes = RelationClasses()
#     new{Expression{X},Expression{F}}(label, value, subdifferential, classes)
#   end
# end

# relation(o::ConvexFunction) = get_oracle(o).value
# relation(o::Dual{<:ConvexFunction}) = get_oracle(o).subdifferential


# ###############################################################################
# struct DifferentiableFunction{X,F} <: Functional{X}
#   label::String
#   value::SingleValued{X,F}
#   gradient::SingleValued{X,X}
#   classes::RelationClasses
  
#   function DifferentiableFunction{X}() where {F<:Field, X<:InnerProductSpace{F}}
#     label = "Differentiable function"
#     value = SingleValued{Expression{X},Expression{F}}("Function")
#     gradient = SingleValued{Expression{X},Expression{X}}("Gradient")
#     classes = RelationClasses()
#     new{Expression{X},Expression{F}}(label, value, gradient, classes)
#   end
# end

# relation(o::DifferentiableFunction) = get_oracle(o).value
# relation(o::Dual{<:DifferentiableFunction}) = get_oracle(o).gradient


# DifferentiableFunction{X}(class::RelationClass) where {X} = (f = DifferentiableFunction{X}(); f ∈ class; f)
# DifferentiableFunction{X}(classes::RelationClasses) where {X} = (f = DifferentiableFunction{X}(); f ∈ classes; f)


# ###############################################################################
# struct Operator{X,Y} <: Oracle{MultiValued{X,Y}}
#   label::String
#   value::MultiValued{X,Y}
  
#   Operator{X,Y}() where {X,Y} = new{Expression{X},Expression{Y}}("Operator", MultiValued{Expression{X},Expression{Y}}())
# end

# relation(o::Operator) = o.value


# ###############################################################################
# struct SingleValuedOperator{X,Y} <: Oracle{SingleValued{X,Y}}
#   label::String
#   value::SingleValued{X,Y}
  
#   SingleValuedOperator{X,Y}() where {X,Y} = new{Expression{X},Expression{Y}}("Single-valued operator", SingleValued{Expression{X},Expression{Y}}())
# end

# relation(o::SingleValuedOperator) = o.value


# ###############################################################################
# struct LinearOperator{X,Y} <: DualOracle{SingleValued{X,Y},SingleValued{Y,X}}
#   label::String
#   value::SingleValued{X,Y}
#   adjoint::SingleValued{Y,X}
  
#   LinearOperator{X,Y}() where {X,Y} = new{Expression{X},Expression{Y}}("Linear operator", SingleValued{Expression{X},Expression{Y}}("Operator"), SingleValued{Expression{Y},Expression{X}}("Adjoint"))
# end

# relation(o::LinearOperator) = o.value
# relation(o::Dual{<:LinearOperator}) = o.primal.adjoint


# ###############################################################################
# struct SymmetricLinearOperator{X} <: Oracle{SingleValued{X,X}}
#   label::String
#   value::SingleValued{X,X}
  
#   SymmetricLinearOperator{X}() where {X} = new{Expression{X},Expression{X}}("Symmetric linear operator", SingleValued{Expression{X},Expression{X}}("Operator"))
# end

# relation(o::SymmetricLinearOperator) = o.value
# adjoint(o::SymmetricLinearOperator) = o


# ###############################################################################
# struct SkewSymmetricLinearOperator{X} <: Oracle{SingleValued{X,X}}
#   label::String
#   value::SingleValued{X,X}
  
#   SymmetricLinearOperator{X}() where {X} = new{Expression{X},Expression{X}}("Skew-symmetric linear operator", SingleValued{Expression{X},Expression{X}}("Operator"))
# end

# relation(o::SkewSymmetricLinearOperator) = o.value
# adjoint(o::SkewSymmetricLinearOperator) = -o


# ###############################################################################
# struct ConvexIndicatorFunction{X} <: Oracle{SingleValued{X,X}}
#   label::String
#   subdifferential::MultiValued{X,X}
  
#   SymmetricLinearOperator{X}() where {X} = new{Expression{X},Expression{X}}("Skew-symmetric linear operator", SingleValued{Expression{X},Expression{X}}("Operator"))
# end

# relation(o::ConvexIndicatorFunction) = o.value
# relation(o::Dual{<:LinearOperator}) = o.primal.subdifferential

