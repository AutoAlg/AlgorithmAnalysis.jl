###############################################################################
# Class
abstract type Class end
abstract type FunctionClass <: Class end
abstract type ConstraintClass <: Class end

###############################################################################
# Oracle
# const NodeSpace = Union{Node, Tuple{Node,Node}, Tuple{Node,Node,Node}}
abstract type Oracle{InputSpace, OutputSpace} end

abstract type SetValuedOracle{InputSpace<:Union{Node, Vector{Node}}, OutputSpace<:Union{Set{Node}, Set{Vector{Node,Node}}}} <: Oracle{InputSpace, OutputSpace} end

abstract type SingleValuedOracle{InputSpace<:Union{Node, Vector{Node}}, OutputSpace<:Union{Node, Vector{Node}}} <: Oracle{InputSpace, OutputSpace} end

###############################################################################
# Function class
struct ConvexFunction <: FunctionClass end

abstract type FunctionClassOracle{InputSpace, OutputSpace, F<:FunctionClass} <: Oracle{InputSpace, OutputSpace} end

###############################################################################
# Constraint class
struct ConvexSet <: ConstraintClass end

abstract type ConstraintClassOracle{InputSpace, OutputSpace, X<:ConstraintClass} <: Oracle{InputSpace, OutputSpace} end



struct FirstOrderFunctionClassOracle{F<:FunctionClass} <: FunctionClassOracle{Point, Tuple{Scalar,Point}, F}
  samples::Dict{Point, Set{Tuple{Scalar, Point}}}
  setvalued::Bool

  FirstOrderFunctionClassOracle{F}() where {F<:FunctionClass} = new(Dict())
end

const FirstOrderConvexOracle = FirstOrderFunctionClassOracle{ConvexFunction}

# Default tuple constructors
Tuple{X,Y}() where {X,Y} = (X(),Y())
Tuple{X,Y,Z}() where {X,Y,Z} = (X(),Y(),Z())

# abstract type ZerothOrderFunctionClassOracle <: FunctionClassOracle end
# abstract type FirstOrderFunctionClassOracle <: FunctionClassOracle end
# abstract type SecondOrderFunctionClassOracle <: FunctionClassOracle end


###############################################################################
# Methods

setvalued(oracle::Oracle) = false
function setvalued(oracle::Oracle, b::Bool)
  oracle.setvalued = b
end

"Sample an oracle at a point in the input space."
function sample(oracle::Oracle{InputSpace, OutputSpace}, x::InputSpace)::OutputSpace where {InputSpace, OutputSpace}
  
  if !haskey(oracle.samples, x)
    oracle.samples[x] = Set()
  end
  if setvalued(oracle)
    y = OutputSpace()
    push!(oracle.samples[x], y)
  else
    y = collect(take(b,oracle.samples[x]))[1]
  end
  
  return y
end

"Get the input-output pairs at which the oracle has been sampled."
function getsamples(oracle::Oracle)
  oracle.samples
end

"Determine whether or not the set of inputs and outputs of the oracle are interpolable (check if they satisfy the interpolation conditions)."
function isinterpolable(oracle::Oracle{InputSpace, OutputSpace}, inputs::Vector{InputSpace}, outputs::Vector{OutputSpace})::Bool where {InputSpace, OutputSpace}
  
end

"Construct the set of multipliers associated with a sequence of ℓ input-output pairs."
function multipliers(oracle::Oracle{InputSpace, OutputSpace})::Bool where {InputSpace, OutputSpace}
  
end

"Set the lifting dimension associated with the oracle."
function setLiftingDimension(oracle::Oracle, ℓ::Integer)
  
end

