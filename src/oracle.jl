export Oracle, Dual, DualOracle, FunctionOracle, OperatorOracle, Functional
export ConvexFunction, DifferentiableFunction
export Operator, ContinuousOperator, LinearOperator
export samples, relation, get_oracle

import Base.adjoint, Base.∈, Base.*, Base.push!


# Oracle (o,o',o'',...)
#  - AbstractOperator: o: X → Y
#    - Operator*
#    - AbstractFunction
#      - Map*
#      - ConstantMap*
#      - AbstractLinearMap: tranpose o': Y → X (Map)
#        - LinearMap*
#        - AbstractSymmetricLinearMap: o' = o: X → X
#          - SymmetricLinearMap*
#        - AbstractSkewSymmetricLinearMap: o' = -o: X → X
#          - SkewSymmetricLinearMap*
#      - AbstractFunctional: o: X → R
#        - Functional*
#        - AbstractSubdifferentiableFunctional: subdifferential o': X ⇉ X (Operator)
#          - SubdifferentiableFunctional*
#          - AbstractDifferentiableFunctional: gradient o': X → X (Map)
#            - DifferentiableFunctional*
#            - AbstractTwiceDifferentiableFunctional: hessian o'': X → X ⊗ X (Map)
#              - TwiceDifferentiableFunctional*
#              - QuadraticFunctional*

# some constraint properties dictate what dual operators are available (e.g., linear implies that o' is the adjoint)
# some constraint properties simplify the structure of the oracle (e.g., symmetric implies o' = o)
# other properties don't do either (e.g., monotone)

# Relations
#  - MultiValuedRelation
#  - SingleValuedRelation
#  - ConstantRelation


export hierarchy
import InteractiveUtils, AbstractTrees
AbstractTrees.children(d::Union{DataType,UnionAll}) = InteractiveUtils.subtypes(d)

hierarchy(d::DataType) = AbstractTrees.print_tree(d; maxdepth=10)




###############################################################################
# Associations

export Transpose, AbstractDifferential, AbstractSubdifferential
export Subdifferential, Gradient, Hessian, LinearFunctionOfOracles

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

"Generic wrapper for a linear combination of oracles."
struct LinearFunctionOfOracles{T<:Oracle} <: Association
  dict::Dict{T,Number}
end

*(a::Number, o::T) where {T<:Oracle} = LinearFunctionOfOracles{T}(Dict(o => a))
*(a::Number, o::LinearFunctionOfOracles{T}) where {T<:Oracle} = LinearFunctionOfOracles{T}(Dict(p.first => a*p.second for p ∈ o.dict))
+(o1::T, o2::T) where {T<:Oracle} = LinearFunctionOfOracles{T}(Dict(o1=>1, o2=>1))
+(o1::T, o2::T) where {T<:LinearFunctionOfOracles} = T(mergewith(+, o1.dict, o2.dict))
+(o1::T, o2::LinearFunctionOfOracles{T}) where {T<:Oracle} = LinearFunctionOfOracles{T}(Dict(o1=>1)) + o2
+(o1::LinearFunctionOfOracles{T}, o2::T) where {T<:Oracle} = o1 + LinearFunctionOfOracles{T}(Dict(o2=>1))

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
adjoint(o::LinearFunctionOfOracles) = mapreduce( p -> p.second * p.first', +, o.dict )


###############################################################################
# Property

export Property, Properties

abstract type Property end
const Properties = Set{Property}


###############################################################################
# Concrete oracles
# 
# Every oracle has the following fields:
#  - label::String
#  - class::Properties

export Operator, Map, LinearMap, SymmetricLinearMap, SkewSymmetricLinearMap
export Functional, SubdifferentiableFunctional, DifferentiableFunctional
export TwiceDifferentiableFunctional, QuadraticFunctional, ConstantMap
export LinearFunctional

struct Operator{X,Y} <: AbstractOperator{X,Y}
  label::String
  properties::Properties
  value::Set{Pair{X,Y}}
  
  Operator{X,Y}() where {X,Y} = new{X,Y}("", Properties(), Set{Pair{X,Y}}())
end

struct Map{X,Y} <: AbstractFunction{X,Y}
  label::String
  properties::Properties
  value::Dict{X,Y}
  
  Map{X,Y}() where {X,Y} = new{X,Y}("", Properties(), Dict{X,Y}())
end

struct ConstantMap{X,Y} <: AbstractFunction{X,Y}
  label::String
  properties::Properties
  value::Y
  
  ConstantMap{X,Y}() where {X,Y} = new{X,Y}("", Properties(), Y())
end

struct LinearMap{X,Y} <: AbstractLinearMap{X,Y}
  label::String
  properties::Properties
  value::Map{X,Y}
  transpose::Map{Y,X}
  
  LinearMap{X,Y}() where {X,Y} = new{X,Y}("", Properties(), Map{X,Y}(), Map{Y,X}())
end

struct SymmetricLinearMap{X} <: AbstractSymmetricLinearMap{X}
  label::String
  properties::Properties
  value::Map{X,X}
  
  SymmetricLinearMap{X}() where {X} = new{X}("", Properties(), Map{X,X}())
end

struct SkewSymmetricLinearMap{X} <: AbstractSkewSymmetricLinearMap{X}
  label::String
  properties::Properties
  value::Map{X,X}
  
  SkewSymmetricLinearMap{X}() where {X} = new{X}("", Properties(), Map{X,X}())
end

struct Functional{X} <: AbstractFunctional{X}
  label::String
  properties::Properties
  value::Map
  
  Functional{X}() where {F<:Field, X<:VectorSpace{F}} = new{X}("", Properties(), Map{X,F}())
end

struct SubdifferentiableFunctional{X} <: AbstractSubdifferentiableFunctional{X}
  label::String
  properties::Properties
  value::Functional{X}
  subdifferential::Operator{X,X}
  
  SubdifferentiableFunctional{X}() where {X} = new{X}("", Properties(), Functional{X}(), Operator{X,X}())
end

struct DifferentiableFunctional{X} <: AbstractDifferentiableFunctional{X}
  label::String
  properties::Properties
  value::Functional{X}
  gradient::Map{X,X}
  
  DifferentiableFunctional{X}() where {X} = new{X}("", Properties(), Functional{X}(), Map{X,X}())
end

struct TwiceDifferentiableFunctional{X} <: AbstractTwiceDifferentiableFunctional{X}
  label::String
  properties::Properties
  value::Functional{X}
  gradient::Map{X,X}
  hessian::Map{X,SymmetricLinearMap{X}}
  
  TwiceDifferentiableFunctional{X}() where {X} = new{X}("", Properties(), Functional{X}(), Map{X,X}(), Map{X,SymmetricLinearMap{X}}())
end

struct QuadraticFunctional{X} <: AbstractTwiceDifferentiableFunctional{X}
  label::String
  properties::Properties
  value::Functional{X}
  gradient::LinearMap{X,X} # Affine
  hessian::SymmetricLinearMap{X} # ConstantMap{X,SymmetricLinearMap{X}}
  
  QuadraticFunctional{X}() where {X} = new{X}("", Properties(), Functional{X}(), LinearMap{X,X}(), SymmetricLinearMap{X}())
end

mutable struct LinearFunctional{X} <: AbstractLinearFunctional{X}
  label::String
  properties::Properties
  value::Functional{X}
  dual::Union{X,Missing}
  
  # linear functionals are always the dual of a vector
  LinearFunctional{X}() where {X} = new{X}("", Properties(), Functional{X}(), missing)
  LinearFunctional{X}(x::X) where {X} = new{X}("", Properties(), Functional{X}(), x)
end


function (::Type{T})(p::Pair) where {T<:Oracle}
  if T <: AbstractFunctional
    if p.second <: Scalar && p.first <: Point{p.second}
      T{Expression{p.first}}()
    else
      error("A functional must be a map from a vector space to its underlying field.")
    end
  else
    T{p.first,p.second}()
  end
end

(::Type{T})(X) where {T<:AbstractFunctional} = T{X}()


###############################################################################
# Methods

export oracle, get_root_oracle, samples, operator

"Get the oracle corresponding to an association."
oracle(o::Oracle) = o.value
oracle(o::Union{Map,Operator}) = o
oracle(o::Transpose{<:AbstractLinearMap}) = o.parent.transpose
oracle(o::Subdifferential{<:AbstractSubdifferentiableFunctional}) = o.parent.subdifferential
oracle(o::Gradient{<:AbstractDifferentiableFunctional}) = o.parent.gradient
oracle(o::Hessian{<:AbstractTwiceDifferentiableFunctional}) = o.parent.hessian

"Get the root oracle from its association."
get_root_oracle(o::Oracle) = o
get_root_oracle(o::Association) = get_root_oracle(o.parent)

"Get the operator associated with an oracle or its association."
operator(o::Union{Map,Operator}) = o
operator(o::Oracle) = operator(o.value)
operator(a::Association) = operator(oracle(a))

"Get the samples associated with an oracle or its association."
samples(o::Union{Oracle,Association}) = operator(o).value


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

function (o::Operator{<:X,Y})(x::X) where {X,Y}
  y = Y()
  push!(samples(o), x => y)
  y
end

function (o::Map{<:X,Y})(x::X) where {X,Y}
  if x ∈ keys(samples(o))
    samples(o)[x]
  else
    y = Y()
    push!(samples(o), x => y)
    y
  end
end

(o::ConstantMap{<:X,Y})(::X) where {X,Y} = o.value

"For linear maps, also use * to denote sampling."
*(o::Union{AbstractLinearMap,AbstractLinearFunctional,Association}, x) = o(x)

"Sample a linear function of linear functionals by taking a linear combination of samples of each functional."
function (o::LinearFunctionOfOracles{T})(x::X) where {F<:Field,X<:VectorSpace{F},T<:AbstractLinearFunctional{X}}
  mapreduce( p -> (y=F(); push!(samples(p.first), x=>y); p.second*y), +, o.dict )
end


###############################################################################
# Methods

export label, label!, properties

import Base.∈

label(o::Oracle) = o.label
label!(o::Oracle, label::String) = (o.label = label)

properties(o::Union{Oracle,Association}) = operator(o).properties

∈(o::Union{Oracle,Association}, class::Property) = push!(properties(o), class)
∈(o::Union{Oracle,Association}, properties::Properties) = map(class -> o ∈ class, properties)


###############################################################################
# Inputs / outputs

export inputs, outputs, domain, codomain, inputs_outputs

inputs(o::Union{Oracle,Association}) = Set(p.first for p ∈ oracle(o))
outputs(o::Union{Oracle,Association}) = Set(p.second for p ∈ oracle(o))

domain(::AbstractOperator{X,Y}) where {X,Y} = X
codomain(::AbstractOperator{X,Y}) where {X,Y} = Y

inputs_outputs(o::Union{Oracle,Association}) = (pairs=collect(samples(o)); ([first(p) for p ∈ pairs], [last(p) for p ∈ pairs]))

domain(a::Association) = domain(oracle(a))
codomain(a::Association) = codomain(oracle(a))

###############################################################################
# Show

import Base.show

show(io::IO, a::Association) = show(io, oracle(a))

function show(io::IO, c::Properties)
  first = true
  for c ∈ collect(c)
    first ? (print(io, typeof(c)); first = false) : print(io, ", ", typeof(c))
  end
end

function show(io::IO, o::AbstractOperator{X,Y}) where {X,Y}
  println(io, "\nOperator from $X to $Y: $(properties(o))")
  map(p -> println(io, "  ", p), collect(samples(o)))
end

function show(io::IO, o::AbstractLinearMap{X,Y}) where {X,Y}
  println(io, "\nLinear map from $X to $Y: $(properties(o))")
  map(p -> println(io, "  ", p), collect(samples(o)))
  println(io, "\nAdjoint operator from $Y to $X: $(properties(o'))")
  map(p -> println(io, "  ", p), collect(samples(o')))
end

function show(io::IO, o::AbstractSymmetricLinearMap{X}) where {X}
  println(io, "\nSymmetric linear map on $X: $(properties(o))")
  map(p -> println(io, "  ", p), collect(samples(o)))
end

function show(io::IO, o::ConstantMap{X,Y}) where {X,Y}
  println(io, "\nConstant map from $X to $Y with value:\n$(o.value)")
end

function show(io::IO, o::AbstractFunctional{X}) where {X}
  println(io, "\nFunctional on $X: $(properties(o))")
  map(p -> println(io, "  ", p), collect(samples(o)))
end

function show(io::IO, o::QuadraticFunctional{X}) where {X}
  print(io, "\nQuadratic functional on $X: $(properties(o))")
  map(p -> print(io, "\n  ", p), collect(samples(o)))
  print(io, "\n\nGradient: $(properties(o'))")
  map(p -> print(io, "\n  ", p), collect(samples(o')))
  print(io, "\n\nHessian: $(properties(o''))")
  map(p -> print(io, "\n  ", p), collect(samples(o'')))
end

function show(io::IO, o::LinearFunctionOfOracles{T}) where {T<:Oracle}
  println(io, "\nLinear function of oracles of type $T")
end


###############################################################################
# Dual

adjoint(o::AbstractLinearFunctional) = o.dual

function adjoint(v::X) where {X<:InnerProductSpace}
  if isvariable(v)
    v.dual
  else
    # for vectors that are linear combinations of variables, construct its dual
    # linear functional as the same linear combination of the duals of the vectors
    mapreduce( p -> p.second * p.first', +, weights(decomposition(v)) )
  end
end


# ###############################################################################
# # Oracle

# "Stationary point of an oracle."
# function stationary_point end

# "Get the label of an oracle."
# label(o::Oracle) = o.label

# properties(o::Oracle) = o.properties

# ∈(o::Oracle, class::RelationProperty) = push!(properties(o), class)
# ∈(o::Oracle, properties::RelationProperties) = map(class -> o ∈ class, properties)


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
#   println(io, "\n$(label(o)) from $(type(X())) to $(type(Y())): $(properties(o))")
#   println(io, properties(relation(o)))
#   map(p -> println(io, "    ", p), collect(samples(relation(o))))
# end

# function show(io::IO, o::DualOracle{X,Y,U,V}) where {X,Y,U,V}
#   println(io, "\n$(label(o)) from $(type(X())) to $(type(Y())): $(properties(o))")
#   println(io, "\n$(label(relation(o))): ", properties(relation(o)))
#   map(p -> println(io, "    ", p), collect(samples(relation(o))))
#   println(io, "\n$(label(relation(o'))): ", properties(relation(o')))
#   map(p -> println(io, "    ", p), collect(samples(o')))
# end
