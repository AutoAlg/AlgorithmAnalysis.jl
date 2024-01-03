# cd("C:\\Users\\vanscob\\.julia\\dev\\BlackBoxOptimization")
# cd("C:\\Users\\Bryan\\.julia\\dev\\BlackBoxOptimization")
# ] activate .
# using Revise
# using BlackBoxOptimization
# using SCS
# using LinearAlgebra
# import Convex

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

include("relation.jl")    # no dependencies
include("constraint.jl")  # requires Expression
include("expression.jl")
include("solve.jl")
include("interpolation.jl")
include("oracle.jl")      # requires interpolation.jl

end
