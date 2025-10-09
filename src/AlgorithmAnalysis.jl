
module AlgorithmAnalysis


############################################################################################
# Export

# abstract types
export Constraint, Constraints, ConstraintSet
export Variable, Variables, Expression, Expressions, Field, Reals
export AbstractVectorSpace, VectorSpace, NormedVectorSpace, InnerProductSpace
export ScalarValue, VectorValue, Object, Objects
export R, Rⁿ, Rᵐ

# expression
export linear, constant, weights, evaluate, constraints, variables, ⊗, Zero
export label, label!, getlabel, value, value!, decomposition, selfdecomp, hasvalue, defaultlabel
export isvariable, hasdecomposition, previous, previous!, next, next!, update, update!
export @field, @vectorspace, @normedvectorspace, @innerproductspace, @algorithm

# constraint
export expression, set, add_constraint!
export Cone, PositiveSemidefiniteCone, PositiveOrthant, ZeroSet, Positive, Semidefinite, Equality
export ConeConstraint, Satisfied, Unsatisfied, prune!, check, dual, cone
export ⪯, ⪰, ⊂, ⊆
export Gram, evaluate, gram_to_constraint

# relation
export Relation, Relations, SingleValuedRelation, MultiValuedRelation, ConstantRelation
export domain, codomain, inputs, outputs, inputs_outputs

# oracle
export Oracle, Oracles, DualOracle, FunctionOracle, OperatorOracle, Functional
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
export Functional, SubdifferentiableFunctional, DifferentiableFunctional, DualInputFunctional
export TwiceDifferentiableFunctional, QuadraticFunctional, ConstantMap
export LinearFunctional, ZeroFunctional

export get_oracle_input

# wrappers
export Wrapper, unwrap
export Dual
export Transpose, AbstractDifferential, AbstractSubdifferential, TransposeOf
export Subdifferential, Gradient, Hessian, GradientOf

# decompositions
export Decomposition, EmptyDecomposition, LinearDecomposition

# interpolation
export FunctionClass, OperatorClass
export Convex, SmoothStronglyConvex, ConvexIndicator, StronglyConvex, Smooth
export QuadraticGrowth, Lipschitz
export LinearOperator, Monotone, Symmetric, Eigenvalues, SkewSymmetric, Cocoercive
export StronglyMonotone, MaxSingularValue
export triplets, Triplets, interpolate, allvecs, gram

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

# primitives
export first_order_stationary_point

# analysis
export maximize, certify, rate
export stateupdate, getmatrix, getparams, solve, eye, grams
export quadraticform, linearform, tr, optvar, optcon
export variable_dictionary, optimization_variable_dictionary, isimplementable, multiplier
export get_states_inputs, get_formulas, lift, neighbors, nodes

# Stochastic 
export GaussianRV, expectation, variance

############################################################################################
# Import

import JuMP
import SCS
import MosekTools
import LinearAlgebra as la
import InteractiveUtils
import AbstractTrees
import Zeros: Zero
import MathOptInterface as MOI

import Base: +, -, *, /, ^, ==, ≤, ≥, ∈, ∘, ∩, ⊆
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
include("reals.jl")
include("label.jl")
include("primitives.jl")
include("algorithms.jl")
include("hash.jl")
include("algebra.jl")
include("analysis.jl")
include("stochastic.jl")
include("show.jl")

end
