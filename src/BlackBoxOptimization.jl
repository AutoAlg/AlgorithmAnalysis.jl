


# TODO
# - constraints with ±Inf
# - clean up show methods
# - more interpolation conditions
# - interpolation conditions inherent to function classes (e.g., linear, quadratic)
# - algorithms
# - performance measures
# - PEP
# - Lyapunov analysis
# - benchmarking
# - CI/CD
# - documentation

"""
    BlackBoxOptimization
    
    Optimization Algorithm Analysis (OptAlg.jl)
    Automated Algorithm Analysis (AutoAlg.jl)
    Systematic Algorithm Analysis (SysAlg.jl)
    Disciplined Algorithm Analysis (DAA.jl)
"""
module BlackBoxOptimization

export BlackBoxOptimization

import Convex as cvx
import SCS
import LinearAlgebra
import InteractiveUtils
import AbstractTrees
import Zeros: Zero


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
include("hash.jl")


end
