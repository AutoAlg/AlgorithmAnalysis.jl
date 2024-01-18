# Automated Algorithm Analysis and Design (AutoAlg.jl)
# Systematic Algorithm Analysis (SysAlg.jl)
# Disciplined Algorithm Analysis (DAA.jl)
# Optimization Algorithm Analysis (OptAlg.jl)
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
export Expression, Field, VectorSpace, NormedVectorSpace, InnerProductSpace

# expression
export GramMatrix
export linear, constant, weights, evaluate, constraints, variables, ⊗, Zero
export label, label!, value, decomposition, selfdecomp, hasvalue, isvariable
export @field, @vectorspace, @normedvectorspace, @innerproductspace, @autolabel

# constraint
export expression, set, add_constraint!
export Cone, PositiveSemidefiniteCone, PositiveOrthant, ZeroSet, Positive, Semidefinite, Equality
export ConeConstraint, Satisfied, Unsatisfied, prune!, check
export ⪯, ⪰

# relation
export Relation, Relations, RelationClass, RelationClasses
export domain, codomain, inputs, outputs, inputs_outputs

# oracle
export Oracle, Oracles, Dual, DualOracle, FunctionOracle, OperatorOracle, Functional
export ConvexFunction, DifferentiableFunction
export Operator, ContinuousOperator, LinearOperator
export oracle, suboracle, sample, samples, relation, get_oracle

export AbstractOperator, AbstractFunction, AbstractLinearMap
export AbstractSymmetricLinearMap, AbstractSkewSymmetricLinearMap
export AbstractFunctional, AbstractSubdifferentiableFunctional
export AbstractDifferentiableFunctional, AbstractTwiceDifferentiableFunctional
export AbstractInfinitelyDifferentiableFunctional, AbstractLinearFunctional

export Operator, Map, LinearMap, SymmetricLinearMap, SkewSymmetricLinearMap
export Functional, SubdifferentiableFunctional, DifferentiableFunctional
export TwiceDifferentiableFunctional, QuadraticFunctional, ConstantMap
export LinearFunctional

# wrappers
export Wrapper, LinearDecomposition, AffineDecomposition
export Transpose, AbstractDifferential, AbstractSubdifferential
export Subdifferential, Gradient, Hessian
export unwrap

# interpolation
export FunctionClass, OperatorClass
export Convex, Curvature, ConvexIndicator, StronglyConvex, Smooth, QuadraticGrowth
export LinearOperator, Monotone, Symmetric, Eigenvalues, SkewSymmetric, Cocoercive, Lipschitz
export StronglyMonotone, MaxSingularValue
export interpolation_conditions, triplets, Triplets

# properties
export Property, Properties
export OperatorClass, FunctionClass, OnePointOperatorClass, TwoPointOperatorClass
export Monotone, Comonotone, WeaklyMonotone, WeaklyComonotone
export RelativelyBounded, RelativelyCobounded, WeaklyRelativelyBounded, WeaklyRelativelyCobounded
export Bounded, Cobounded, WeaklyBounded, WeaklyCobounded
export Linear, Symmetric, SkewSymmetric, Eigenvalues, MaxSingularValue
export Monotonicity, RelativeBoundedness, Boundedness
export propertyof, properties, allproperties

# solve
export maximize, lift, project, variables, constraints, variables_constraints

# other
export hierarchy


############################################################################################
# Import

import Convex as cvx
import SCS
import LinearAlgebra
import InteractiveUtils
import AbstractTrees
import Zeros: Zero

import Base: +, -, *, /, ^, ==, ≤, ≥, ∈, ∘, ∩
import Base: isempty, iszero, isequal
import Base: promote_rule, convert, show, zero, zeros, adjoint
import Base: length, Generator, iterate, size, push!, inv


############################################################################################
# Include

include("abstract.jl")
include("wrapper.jl")
include("expression.jl")
include("constraint.jl")
include("relation.jl")
include("oracle.jl")
include("adjoint.jl")
include("interpolation.jl")
include("show.jl")
# include("solve.jl")
# include("primitives.jl")
# include("algorithms.jl")
include("hash.jl")

end
