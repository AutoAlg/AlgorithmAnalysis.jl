# cd("C:\\Users\\vanscob\\.julia\\dev\\BlackBoxOptimization")
# cd("C:\\Users\\Bryan\\.julia\\dev\\BlackBoxOptimization")
# ] activate .
# using Revise
# using BlackBoxOptimization
# using SCS
# using LinearAlgebra
# import Convex as cvx

# ] test BlackBoxOptimization

module BlackBoxOptimization

export BlackBoxOptimization

import Convex as cvx
import SCS
import LinearAlgebra

"The types of values for an expression."
abstract type Value{T} end

"An abstract expression that evaluates to a value of type `T`."
abstract type Expression{T<:Value} end

"An abstract constraint that consists of an expression belonging to a set."
abstract type Constraint end

"A set of constraints."
const Constraints = Set{Constraint}

"An oracle is a set of operators and the ways in which they are related. For instance, an oracle may consist of the operators A and Aᵀ where A is linear and Aᵀ is its tranpose. Each operator can be sampled at a point in its domain, and its relation can be constrained to be in a class. Furthermore, the set of operators can also be constrained to be in a class."
abstract type Oracle end

"A set of oracles."
const Oracles = Set{Oracle}

# include("relation.jl")    # no dependencies
include("constraint.jl")  # requires Expression
include("expression.jl")
include("oracle.jl")
include("interpolation.jl")
# include("solve.jl")
# include("primitives.jl")
# include("algorithms.jl")

end
