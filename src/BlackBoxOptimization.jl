# Organizations: Mathematics > JuliaOptAlg - Automated and assisted analysis of optimization algorithms in Julia
#   - VectorSpaces.jl (see VectorInterface.jl)
#   - BlackBoxOracles.jl
#   - OptimizationAlgorithms.jl
#   - PerformanceEstimation.jl
#   - LyapunovAnalysis.jl
module BlackBoxOptimization

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
# - documentation


############################################################################################
# Export

# abstract types
export Constraint, Constraints, ConstraintSet
export Variable, Variables, Expression, Expressions, Field, Reals, Subset
export AbstractVectorSpace, VectorSpace, NormedVectorSpace, InnerProductSpace
export ScalarValue, VectorValue
export R, Rⁿ, Rᵐ

# expression
export linear, constant, weights, evaluate, constraints, variables, ⊗, Zero
export label, label!, getlabel, value, value!, decomposition, selfdecomp, hasvalue
export isvariable, previous, previous!, next, next!, update
export @field, @vectorspace, @normedvectorspace, @innerproductspace, @algorithm

# constraint
export expression, set, add_constraint!
export Cone, PositiveSemidefiniteCone, PositiveOrthant, ZeroSet, Positive, Semidefinite, Equality
export ConeConstraint, Satisfied, Unsatisfied, prune!, check, dual
export ⪯, ⪰

# relation
export Relation, Relations, SingleValuedRelation, MultiValuedRelation, ConstantRelation
export domain, codomain, inputs, outputs, inputs_outputs

# oracle
export Oracle, Oracles, Dual, DualOracle, FunctionOracle, OperatorOracle, Functional
export ConvexFunction, DifferentiableFunction
export Operator, ContinuousOperator, LinearOperator
export oracle, oracles, superoracle, suboracle, suboracles, sample, samples, relation, get_oracle
export associations, description, relation

export AbstractOperator, AbstractFunction, AbstractLinearMap, AbstractLocallyLipschitzFunctional
export AbstractSymmetricLinearMap, AbstractSkewSymmetricLinearMap
export AbstractFunctional, AbstractSubdifferentiableFunctional
export AbstractDifferentiableFunctional, AbstractTwiceDifferentiableFunctional
export AbstractInfinitelyDifferentiableFunctional, AbstractLinearFunctional

export Operator, Map, LinearMap, SymmetricLinearMap, SkewSymmetricLinearMap
export Functional, SubdifferentiableFunctional, DifferentiableFunctional
export TwiceDifferentiableFunctional, QuadraticFunctional, ConstantMap
export LinearFunctional, ZeroFunctional

# wrappers
export Wrapper, unwrap
export Transpose, AbstractDifferential, AbstractSubdifferential
export Subdifferential, Gradient, Hessian

# decompositions
export Decomposition, EmptyDecomposition, LinearDecomposition

# interpolation
export FunctionClass, OperatorClass
export Convex, SmoothStronglyConvex, ConvexIndicator, StronglyConvex, Smooth
export QuadraticGrowth, Lipschitz
export LinearOperator, Monotone, Symmetric, Eigenvalues, SkewSymmetric, Cocoercive
export StronglyMonotone, MaxSingularValue
export interpolation_conditions, triplets, Triplets

# properties
export Property, Properties
export OperatorClass, FunctionClass, OnePointOperatorClass, TwoPointOperatorClass
export Monotone, Comonotone, WeaklyMonotone, WeaklyComonotone
export AbstractQuadraticConstraint, AbstractPointwiseQuadraticConstraint, AbstractIncrementalQuadraticConstraint
export PointwiseQuadraticConstraint, IncrementalQuadraticConstraint
export AbstractLinearQuadraticConstraint, AbstractTwoPointLinearQuadraticConstraint, TwoPointLinearQuadraticConstraint
export SlopeRestricted, SectorBounded
export reference, quadraticform, linearquadraticform
export RelativelyBounded, RelativelyCobounded, WeaklyRelativelyBounded, WeaklyRelativelyCobounded
export Bounded, Cobounded, WeaklyBounded, WeaklyCobounded, Convex
export Linear, Symmetric, SkewSymmetric, Eigenvalues, MaxSingularValue
export Monotonicity, RelativeBoundedness, Boundedness
export propertyof, properties
export Co, Weakly, PropertyOrWrapper

# solve
export maximize, lift, project, variables, constraints, variables_constraints_oracles
export transform!

# primitives
export first_order_stationary_point

# other
export hierarchy

# analysis
export stateupdate, getmatrix, getparams, solve, bsmin, rate, eye, certify
export quadraticform, linearform, tr, optvar, optcon, maximize
export variable_dictionary

############################################################################################
# Import

# import Convex as cvx
import JuMP
import SCS
import LinearAlgebra as la
import InteractiveUtils
import AbstractTrees
import Zeros: Zero
import MathOptInterface as MOI

import Base: +, -, *, /, ^, ==, ≤, ≥, ∈, ∘, ∩
import Base: isempty, iszero, isequal
import Base: promote_rule, convert, show, zero, zeros, adjoint
import Base: length, Generator, iterate, size, push!, inv, pairs


############################################################################################
# Include

include("abstract.jl")
include("wrapper.jl")
include("decomposition.jl")
include("expression.jl")
include("constraint.jl")
include("relation.jl")
include("oracle.jl")
include("adjoint.jl")
include("interpolation.jl")
include("show.jl")
include("label.jl")
include("primitives.jl")
include("algorithms.jl")
include("hash.jl")
include("algebra.jl")
include("reals.jl")
include("analysis.jl")

end
