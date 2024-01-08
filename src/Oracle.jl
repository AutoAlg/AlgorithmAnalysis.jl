export Oracle, Dual, DualOracle, FunctionOracle, OperatorOracle, Functional
export ConvexFunction, DifferentiableFunction
export Operator, ContinuousOperator, LinearOperator
export samples, relation, get_oracle

import Base.adjoint, Base.∈, Base.*, Base.push!


###############################################################################
# Oracle

"Stationary point of an oracle."
function stationary_point end

"Get the label of an oracle."
label(o::Oracle) = o.label

classes(o::Oracle) = o.classes

∈(o::Oracle, class::RelationClass) = push!(classes(o), class)
∈(o::Oracle, classes::RelationClasses) = map(class -> o ∈ class, classes)


###############################################################################
# Dual oracle

"A dual oracle is an oracle that also has a dual relation. The semantics of the dual depend on the specific type of oracle. For instance, the dual of a linear operator is its adjoint (conjugate transpose), while the dual of a convex function is its subdifferential. The dual of an oracle `o` can be accessed by `o'`."
abstract type DualOracle{X,Y,U,V} <: Oracle{X,Y} end

"Generic wrapper for the dual of an object."
struct Dual{T}
  primal::T
end

adjoint(o::T) where {T<:DualOracle} = Dual{T}(o)

"A primal or dual oracle on X × Y."
const PrimalOrDual{X,Y} = Union{Oracle{X,Y}, Dual{<:DualOracle{x,y,X,Y}}}

"Get the relation corresponding to an oracle."
relation(o::PrimalOrDual) = error("relation not implemented for oracle $o")

"Get the oracle from either an oracle or its dual."
get_oracle(o::Oracle) = o
get_oracle(o::Dual{<:DualOracle}) = o.primal

"Sample an oracle (or its dual) at a point in the domain of its relation (or dual relation)."
function (o::PrimalOrDual{X,Y})(x::X) where {X,Y}
  y = relation(o)(x)
  add_oracle!(x, get_oracle(o))
  add_oracle!(y, get_oracle(o))
  y
end

# Can use o(x) or o*x to sample an oracle (or its dual) at a point
*(o::PrimalOrDual{X,Y}, x::X) where {X,Y} = o(x)

samples(o::PrimalOrDual) = samples(relation(o))

# evaluate(o::PrimalOrDual{X,Y}, x::X) where {X,Y} = evaluate(relation(o), x)

"Push a single sample onto either the primal or dual oracle."
push!(o::PrimalOrDual{X,Y}, p::Pair{<:X,<:Y}) where {X,Y} = push!(samples(o), p)
push!(o::PrimalOrDual{X,Y}, x::X, y::Y) where {X,Y} = push!(samples(o), x => y)

"Push a primal-dual pair onto an oracle."
function push!(o::DualOracle{X,Y,U,V}, p1::Pair{<:X,<:Y}, p2::Pair{<:U,<:V}) where {X,Y,U,V}
  push!(o,  p1)
  push!(o', p2)
end
push!(o::DualOracle{X,Y,U,V}, x::X, y::Y, u::U, v::V) where {X,Y,U,V} = push!(o, x => y, u => v)


###############################################################################
# Inputs / outputs

inputs(o::PrimalOrDual) = iinputs(relation(o))
outputs(o::PrimalOrDual) = outputs(relation(o))

inputs(p::Oracle, d::Dual{<:DualOracle}) = inputs(p) ∪ inputs(d)
outputs(p::Oracle, d::Dual{<:DualOracle}) = outputs(p) ∪ outputs(d)


###############################################################################
# Iterate

length(o::PrimalOrDual) = length(samples(o))

"Iterate over the samples of an oracle."
iterate(o::PrimalOrDual) = iterate(o,1)
iterate(o::PrimalOrDual, state::Int) = (state > length(o) ? nothing : ( collect(samples(o))[state], state+1))


###############################################################################
# Show

function show(io::IO, o::Oracle{X,Y}) where {X,Y}
  println(io, "\n$(label(o)) from $(type(X())) to $(type(Y())): $(classes(o))")
  println(io, classes(relation(o)))
  map(p -> println(io, "    ", p), collect(samples(relation(o))))
end

function show(io::IO, o::DualOracle{X,Y,U,V}) where {X,Y,U,V}
  println(io, "\n$(label(o)) from $(type(X())) to $(type(Y())): $(classes(o))")
  println(io, "\n$(label(relation(o))): ", classes(relation(o)))
  map(p -> println(io, "    ", p), collect(samples(relation(o))))
  println(io, "\n$(label(relation(o'))): ", classes(relation(o')))
  map(p -> println(io, "    ", p), collect(samples(o')))
end





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

