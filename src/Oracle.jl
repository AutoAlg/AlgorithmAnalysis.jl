export Oracle, Oracles, domain, codomain, FunctionClass, ConvexFunction, SmoothStronglyConvexFunction, FirstOrder, ConvexOracle, MonotoneOperator, SmoothStronglyConvexOracle, sample_input, sample_output, stationary, samples

"A oracle consists of a field `samples` of type `r<:Relation` and a field `interpolation_class` of type `R<:RelationClass`, both of which must have the same domain and codomain. The oracle samples points in the domain and returns information in the codomain."
mutable struct Oracle{r,R}
  samples::r
  interpolation_class::R
  singlevalued::Bool

  "Construct an oracle from its input and output spaces."
  Oracle{r,R}(singlevalued=true) where {r<:AbstractRelation,R<:AbstractRelationClass} = new(r(),R(),singlevalued)
end

const Oracles = Vector{Oracle}

samples(o::Oracle) = o.samples
interpolation_class(o::Oracle) = o.interpolation_class
singlevalued(o::Oracle) = o.singlevalued

# zero(::Type{X}) where {X} = zero(X)
zero(::Type{Tuple{X,Y}}) where {X, Y} = (zero(X),zero(Y))

"Custom display of an oracle."
function Base.show(io::IO, o::Oracle)
  println(io, "\nOracle on $(domain(o)) x $(codomain(o))")
  for (x,y) ∈ o.samples
    print(io, "\n($x, $y)")
  end
  println()
  @show o.interpolation_class
  println()
  @show o.singlevalued
end

###############################################################################
# Derived methods.

"Domain of an oracle."
domain(o::Oracle) = domain(samples(o))

"Codomain of an oracle."
codomain(o::Oracle) = codomain(samples(o))

"Interpolation conditions for an oracle's interpolation class and samples."
interpolation_conditions(o::Oracle) = (samples(o) ∈ interpolation_class(o))

"Zeros of an oracle."
zeros(o::Oracle) = zeros(samples(o))

"Stationary point of an oracle."
function stationary(o::Oracle)
  x = domain(o)()
  y = zero(codomain(o))
  push!(samples(o), x, y)
  x
end

"Sample an oracle at a point in its domain."
function sample_input(o::Oracle,x)
  if !isa(x,domain(o))
    error("The point $x must be in the domain $(domain(o)) of the oracle $o.")
  end
  if singlevalued(o) && x ∈ preimage(samples(o))
    y = samples(o)(x)[1]
  else
    y = codomain(samples(o))()
    push!(samples(o), x, y)
  end
  y
end
(o::Oracle)(x) = sample_input(o,x)

"Sample an oracle at a point in its output space."
function sample_output(o::Oracle,y)
  if !isa(y,codomain(o))
    error("The point $y must be in the codomain $(codomain(o)) of the oracle $o.")
  end
  if y ∈ image(samples(o))
    x = inv(samples(o))(y)[1]
  else
    x = domain(samples(o))()
    push!(samples(o), x, y)
  end
  x
end

###############################################################################
# Relations

const Functional = Relation{Point, Scalar}
# const FirstOrder = Relation{Point, Tuple{Scalar, Point}}
const Operator   = Relation{Point, Point}

const FirstOrder{T1,T2} = Relation{T1, Tuple{T2, T1}}

###############################################################################
# Relation classes

abstract type FunctionClass <: AbstractRelationClass end
struct ConvexFunction <: FunctionClass end
struct Monotone <: FunctionClass end
struct SmoothStronglyConvexFunction{μ,L} <: FunctionClass end

###############################################################################
# Concrete oracles

# const ConvexOracle = Oracle{FirstOrder, ConvexFunction}
# const MonotoneOperator = Oracle{Operator, Monotone}
const SmoothStronglyConvexOracle{T1,T2,μ,L} = Oracle{FirstOrder{T1,T2}, SmoothStronglyConvexFunction{μ,L}}


###############################################################################
# Interpolation conditions

function Base.:∈(r::FirstOrder, ::ConvexFunction)
  c = []
  for (x1,(f1,g1)) ∈ r, (x2,(f2,_)) ∈ r
    append!(c, f2 ≥ f1 + g1*(x2-x1))
  end
  c
end

function Base.:∈(r::FirstOrder, ::SmoothStronglyConvexFunction{μ,L}) where {μ,L}
  c = []
  for (x1,(f1,g1)) ∈ r, (x2,(f2,g2)) ∈ r
    append!(c, f2-f1-g1*(x2-x1) ≥ 1/(2*(1-μ/L))*(1/L*(g2-g1)^2 + μ*(x2-x1)^2 - 2μ/L*(g2-g1)*(x2-x1)))
  end
  c
end



# abstract type Class end
# abstract type FunctionClass <: Class end
# struct ConvexFunction <: FunctionClass end

# abstract type FirstOrderOracle{F<:FunctionClass} <: Oracle{Point, Tuple{Scalar, Point}} end

# struct FirstOrderConvexOracle <: FirstOrderOracle{ConvexFunction}
#   samples::Relation{Point, Tuple{Scalar, Point}}

#   FirstOrderConvexOracle() = new(Dict())
# end

# "Get the input-output pairs at which the relation has been sampled."
# getsamples(o::Oracle) = o.samples



# ###############################################################################
# # Each `Oracle` must specialize the following methods.

# "Construct the set of multipliers associated with a sequence of ℓ input-output pairs."
# function multipliers(o::Oracle{X, Y}) where {X, Y} end

# "Set the lifting dimension of an oracle."
# function lifting_dimension(o::Oracle, ℓ::Integer) end

# "Determine whether or not the oracle is single-valued (affects sampling)."
# function singlevalued(o::Oracle)::Bool end

# function push!(o::Oracle{X, Y}, samples::Tuple{X, Y}) where {X, Y} end

# # Each `Oracle` must have a field samples::Relation{SampleSpace, InformationSpace}.
# # Both `SampleSpace` and `InformationSpace` must have default constructors (for sampling).







# ###############################################################################
# # Class
# abstract type Class end
# abstract type FunctionClass <: Class end
# abstract type ConstraintClass <: Class end

# ###############################################################################
# # Oracle
# # const NodeSpace = Union{Node, Tuple{Node,Node}, Tuple{Node,Node,Node}}
# abstract type Oracle{InputSpace<:Nodes, OutputSpace<:Set{Nodes}} end

# # abstract type SetValuedOracle{InputSpace<:Union{Node, Vector{Node}}, OutputSpace<:Union{Set{Node}, Set{Vector{Node,Node}}}} <: Oracle{InputSpace, OutputSpace} end

# # abstract type SingleValuedOracle{InputSpace<:Union{Node, Vector{Node}}, OutputSpace<:Union{Node, Vector{Node}}} <: Oracle{InputSpace, OutputSpace} end

# ###############################################################################
# # Function class
# struct ConvexFunction <: FunctionClass end

# abstract type FunctionClassOracle{InputSpace, OutputSpace, F<:FunctionClass} <: Oracle{InputSpace, OutputSpace} end

# ###############################################################################
# # Constraint class
# struct ConvexSet <: ConstraintClass end

# abstract type ConstraintClassOracle{InputSpace, OutputSpace, X<:ConstraintClass} <: Oracle{InputSpace, OutputSpace} end



# struct FirstOrderFunctionClassOracle{F<:FunctionClass} <: FunctionClassOracle{Point, Tuple{Scalar,Point}, F}
#   samples::Dict{Point, Set{Tuple{Scalar, Point}}}
#   setvalued::Bool

#   FirstOrderFunctionClassOracle{F}() where {F<:FunctionClass} = new(Dict())
# end

# const FirstOrderConvexOracle = FirstOrderFunctionClassOracle{ConvexFunction}

# # Default tuple constructors
# Tuple{X,Y}() where {X,Y} = (X(),Y())
# Tuple{X,Y,Z}() where {X,Y,Z} = (X(),Y(),Z())

# # abstract type ZerothOrderFunctionClassOracle <: FunctionClassOracle end
# # abstract type FirstOrderFunctionClassOracle <: FunctionClassOracle end
# # abstract type SecondOrderFunctionClassOracle <: FunctionClassOracle end


# ###############################################################################
# # Methods

# setvalued(oracle::Oracle) = false
# function setvalued(oracle::Oracle, b::Bool)
#   oracle.setvalued = b
# end

# "Sample an oracle at a point in the input space."
# function sample(oracle::Oracle{InputSpace, OutputSpace}, x::InputSpace)::OutputSpace where {InputSpace, OutputSpace}
  
#   if !haskey(oracle.samples, x)
#     oracle.samples[x] = Set()
#   end
#   if setvalued(oracle)
#     y = OutputSpace()
#     push!(oracle.samples[x], y)
#   else
#     y = collect(take(b,oracle.samples[x]))[1]
#   end
  
#   return y
# end

# "Get the input-output pairs at which the oracle has been sampled."
# function getsamples(oracle::Oracle)
#   oracle.samples
# end

# "Determine whether or not the set of inputs and outputs of the oracle are interpolable (check if they satisfy the interpolation conditions)."
# function isinterpolable(oracle::Oracle{InputSpace, OutputSpace}, inputs::Vector{InputSpace}, outputs::Vector{OutputSpace})::Bool where {InputSpace, OutputSpace}
  
# end

# "Construct the set of multipliers associated with a sequence of ℓ input-output pairs."
# function multipliers(oracle::Oracle{InputSpace, OutputSpace})::Bool where {InputSpace, OutputSpace}
  
# end

# "Set the lifting dimension associated with the oracle."
# function setLiftingDimension(oracle::Oracle, ℓ::Integer)
  
# end

