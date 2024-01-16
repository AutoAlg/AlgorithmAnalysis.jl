# cd("C:\\Users\\vanscob\\.julia\\dev\\BlackBoxOptimization")
# cd("C:\\Users\\Bryan\\.julia\\dev\\BlackBoxOptimization")
# ] activate .
# using Revise
# using BlackBoxOptimization
# using SCS
# using LinearAlgebra
# import Convex as cvx

# ] test BlackBoxOptimization


# TODO
# - constraints with ±Inf
# - clean up show methods
# - linear combination of oracles
# - decomposition of scalars is affine in scalars (no inner products)


module BlackBoxOptimization

export BlackBoxOptimization

# import Convex as cvx
# import SCS
import LinearAlgebra

# "The types of values for an expression."
# abstract type Value{T} end

# "An abstract expression that evaluates to a value of type `T`."
# # abstract type Expression{T} <: Value{T where {T, V<:Value{T}}} end
# abstract type Expression{T<:Value} end

"An abstract constraint that consists of an expression belonging to a set."
abstract type Constraint end

"A set of constraints."
const Constraints = Set{Constraint}

"An oracle is a set of operators and the ways in which they are related. For instance, an oracle may consist of the operators A and Aᵀ where A is linear and Aᵀ is its tranpose. Each operator can be sampled at a point in its domain, and its relation can be constrained to be in a class. Furthermore, the set of operators can also be constrained to be in a class."
abstract type Oracle end

"A set of oracles."
const Oracles = Set{Oracle}

include("expression.jl")
# include("relation.jl")    # no dependencies
include("constraint.jl")  # requires Expression
include("oracle.jl")
include("interpolation.jl")
# include("solve.jl")
# include("primitives.jl")
# include("algorithms.jl")

###############################################################################
# Hash

# Override hash function because of
# https://github.com/JuliaLang/julia/issues/10267
import Base.hash

"Hash of an expression."
hash(e::Expression, h::UInt) = isvariable(e) ? objectid(e) : hash(value(e), hash(decomposition(e), h))
hash(x::LinearDecomposition, h::UInt) = hash(weights(x), h)
hash(x::AffineDecomposition, h::UInt) = hash(linear(x), hash(constant(x), h))
hash(c::Constraint, h::UInt) = hash(set(c), hash(expression(c), h))
hash(c::Satisfied, h::UInt) = objectid(c)
hash(c::Unsatisfied, h::UInt) = objectid(c)

function hash(a::AbstractArray{<:Expression}, h::UInt)
  h = hash(size(a), h)
  for x ∈ a
    h = hash(x, h)
  end
  h
end

end
