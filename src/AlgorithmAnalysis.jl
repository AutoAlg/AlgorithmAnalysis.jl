
module AlgorithmAnalysis


# ############################################################################################
# # Export

# # abstract types
# export Constraint, Constraints, ConstraintSet
# export Variable, Variables, Expression, Expressions, Field, Reals
# export AbstractVectorSpace, VectorSpace, NormedVectorSpace, InnerProductSpace
# export ScalarValue, VectorValue, Object, Objects
# export R, Rⁿ, Rᵐ

# # expression
# export linear, constant, weights, evaluate, constraints, variables, ⊗, Zero
# export label, label!, getlabel, value, value!, decomposition, selfdecomp
# export hasvalue, defaultlabel, vecs1, vec2
# export isvariable, hasdecomposition, previous, previous!, next, next!, update, update!
# export @field, @vectorspace, @normedvectorspace, @innerproductspace, @algorithm

# # constraint
# export AbstractConstraint, expression, set, add_constraint!, Equality
# export Cone, PositiveSemidefiniteCone, PositiveOrthant, ZeroSet, Positive, Semidefinite
# export Constraint, Satisfied, Unsatisfied, prune!, check, dual, cone, UnrestrictedCone
# export ⪯, ⪰, ⊆
# export Gram, evaluate, gram_to_constraint

# # relation
# export Relation, Relations, SingleValuedRelation, MultiValuedRelation, ConstantRelation
# export domain, codomain, inputs, outputs, inputs_outputs

# # oracle
# export Oracle, Oracles, DualOracle, FunctionOracle, OperatorOracle, Functional
# export ConvexFunction, DifferentiableFunction
# export Operator, ContinuousOperator, LinearOperator, get_oracle
# export oracle, oracles, superoracle, suboracle, suboracles, sample, samples, relation
# export associations, description, relation

# export AbstractOperator, AbstractFunction, AbstractLinearMap
# export AbstractLocallyLipschitzFunctional
# export AbstractSymmetricLinearMap, AbstractSkewSymmetricLinearMap
# export AbstractFunctional, AbstractSubdifferentiableFunctional
# export AbstractDifferentiableFunctional, AbstractTwiceDifferentiableFunctional
# export AbstractInfinitelyDifferentiableFunctional, AbstractLinearFunctional

# export Operator, Map, LinearMap, SymmetricLinearMap, SkewSymmetricLinearMap
# export Functional, SubdifferentiableFunctional, DifferentiableFunctional
# export TwiceDifferentiableFunctional, QuadraticFunctional, ConstantMap
# export LinearFunctional, ZeroFunctional, DualInputFunctional
# export SmoothStronglyConvexFunction
# export get_oracle_input

# # decompositions
# export Decomposition, EmptyDecomposition, LinearDecomposition

# # interpolation
# export FunctionClass, OperatorClass
# export Convex, SmoothStronglyConvex, ConvexIndicator, StronglyConvex, Smooth
# export QuadraticGrowth, Lipschitz
# export LinearOperator, Monotone, Symmetric, Eigenvalues, SkewSymmetric, Cocoercive
# export StronglyMonotone, MaxSingularValue
# export triplets, Triplets, interpolate, allvecs, gram

# # properties
# export Property, Properties
# export OperatorClass, FunctionClass, OnePointOperatorClass, TwoPointOperatorClass
# export Monotone, Comonotone, WeaklyMonotone, WeaklyComonotone
# export AbstractQuadraticConstraint, AbstractPointwiseQuadraticConstraint
# export AbstractIncrementalQuadraticConstraint
# export PointwiseQuadraticConstraint, IncrementalQuadraticConstraint
# export AbstractLinearQuadraticConstraint, AbstractTwoPointLinearQuadraticConstraint
# export TwoPointLinearQuadraticConstraint
# export SlopeRestricted, SectorBounded
# export reference, quadraticform, linearquadraticform
# export RelativelyBounded, RelativelyCobounded, WeaklyRelativelyBounded
# export WeaklyRelativelyCobounded
# export Bounded, Cobounded, WeaklyBounded, WeaklyCobounded, Convex
# export Linear, Symmetric, SkewSymmetric, Eigenvalues, MaxSingularValue
# export Monotonicity, RelativeBoundedness, Boundedness
# export propertyof, properties
# export Co, Weakly

# # solve
# export lift, project, variables, constraints, variables_constraints

# # primitives
# export first_order_stationary_point

# # analysis
# export maximize, certify, rate
# export stateupdate, getmatrix, getparams, solve, eye, grams
# export quadraticform, linearform, tr, optvar, optcon
# export optimization_variable_dictionary, isimplementable, multiplier
# export get_states_inputs, get_formulas, lift, neighbors, negative!, connected_components

# export bsmin, get_element

# export Association, Dual, DualOf, Transpose, Subdifferential, Gradient, GradientOf, Hessian

# ############################################################################################
# # Import

# import JuMP
# import SCS
# import MosekTools
# import LinearAlgebra as la
# import InteractiveUtils
# import Zeros: Zero
# import MathOptInterface as MOI
# import HTTP
# import JSON
# import CodeTracking
# import UUIDs
# import Random

# import Base: +, -, *, /, ^, ==, ≤, ≥, ∈, ∘, ∩, ⊆
# import Base: isempty, iszero, isequal, getindex
# import Base: promote_rule, convert, show, zero, zeros, adjoint
# import Base: length, Generator, iterate, size, push!, inv, pairs

# import LinearAlgebra: dot, ⋅

############################################################################################
# Include

# include("abstract.jl")
# include("decomposition.jl")
# include("expression.jl")
# include("constraint.jl")
# include("relation.jl")
# include("oracle.jl")
# include("adjoint.jl")
# include("interpolation.jl")
# include("show.jl")
# include("label.jl")
# include("primitives.jl")
# include("performance.jl")
# include("algorithms.jl")
# include("hash.jl")
# include("algebra.jl")
# include("reals.jl")
# include("analysis.jl")
# include("results.jl")
# include("new_algorithm_state.jl")


export ExpressionID, NewExpression, AlgorithmContext, allocate_id, is_bound_to
export ensure_expressions_are_bound_to_current_context
export ==, hash, try_get_algorithm_context, get_algorithm_context, with_context
export register!, set_alias!, try_get_name, deepcopy_internal, clone

include("new/algorithm_context.jl")


export AbstractSpace, RealSpace, RealVectorSpace, AbstractVariable, NewOracle
export ConcretelyValuedVariable, Variable, NewR, NewRⁿ

include("new/variables.jl")

export LinearDecomposition

include("new/linear_decomposition.jl")

export SSC, SSCFunction, SSCGradientOf, SSCGradient

include("new/ssc.jl")

include("new/algebra.jl")

export StateTransition

include("new/state_transition.jl")


export dependencies

include("new/dependencies.jl")

export compute_forward_edges, compute_reachable_expressions, eliminate_unreachable_expressions

include("new/algorithm_context_pruning.jl")


include("new/show.jl")

end
