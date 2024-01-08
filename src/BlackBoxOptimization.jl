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

include("relation.jl")    # no dependencies

"The types of values for an expression."
abstract type Value{T} end

"An abstract expression that evaluates to a value of type `T`."
abstract type Expression{T<:Value} end

"An abstract constraint that consists of an expression belonging to a set."
abstract type Constraint end

"A set of constraints."
const Constraints = Set{Constraint}

# "An oracle is a set of related operators. Each operator can be sampled at a point in its domain, and its relation can be constrained to be in a class. Furthermore, the set of operators can also be constrained to be in a class."
# abstract type Oracle{X,Y} end

# const Oracles = Set{Oracle}




# Oracle (o,o',o'',...)
#  - Operator: o: X → Y
#    - Linear: adjoint o': Y → X
#      - Symmetric: o' = o: X → X
#      - Skew-symmetric: o' = -o: X → X
#    - Functional: o: X → R
#      - Convex: subdifferential o': X ⇉ X
#        - ConvexIndicator (f = 0)
#      - Differentiable: gradient o': X → X
#        - TwiceDifferentiable: hessian o'': X → X ⊗ X

###############################################################################
abstract type Oracle end
abstract type Operator{X,Y} <: Oracle end
abstract type LinearOperator{X,Y} <: Operator{X,Y} end
abstract type SymmetricLinearOperator{X} <: LinearOperator{X,X} end
abstract type SkewSymmetricLinearOperator{X} <: LinearOperator{X,X} end
abstract type Functional{X} <: Oracle end
abstract type ConvexFunction{X} <: Functional{X} end
abstract type DifferentiableFunction{X} <: Functional{X} end
abstract type TwiceDifferentiableFunction{X} <: DifferentiableFunction{X} end

abstract type Class end
abstract type OperatorClass <: Class end
abstract type FunctionClass <: Class end

# operator class primitives
struct Monotone <: OperatorClass end
struct Eigenvalues{μ,L} <: OperatorClass end
struct MaxSingularValue{L} <: OperatorClass end
struct Cocoercive{β} <: OperatorClass end
struct StronglyMonotone{μ} <: OperatorClass end
struct Nonexpansive{v} <: OperatorClass end
struct NegativelyComonotone{ρ} <: OperatorClass end
struct Lipschitz{L} <: OperatorClass end
struct ZeroOperator <: OperatorClass end
struct BoundedDomain{D} <: OperatorClass end

# function class primitives
struct Curvature{μ,L} <: FunctionClass end
struct QuadraticGrowth{μ} <: FunctionClass end

"Generic wrapper for the dual of an object."
struct Dual{T}
  primal::T
end

struct Transformation{T}
  parent::T
  transformation::Function
end

# some constraint classes dictate what dual operators are available (e.g., linear implies that o' is the adjoint)
# some constraint classes simplify the structure of the oracle (e.g., symmetric implies o' = o)
# other classes don't do either (e.g., monotone)
adjoint(o::Oracle) = error("Dual not specified for oracle $o.")
adjoint(o::Operator) = error("A nonlinear operator does not have an adjoint.")
adjoint(o::LinearOperator) = Dual{LinearOperator}(o)
adjoint(o::SymmetricLinearOperator) = o
adjoint(o::SkewSymmetricLinearOperator) = Transformation{SkewSymmetricLinearOperator}(o, (x,y) -> (x,-y))
adjoint(o::Functional) = error("Dual not specified for functional $o.")
adjoint(o::ConvexFunction) = Dual{ConvexFunction}(o)
adjoint(o::Dual{ConvexFunction}) = error("Higher-order derivatives undefined for the convex function $(o.parent).")
adjoint(o::DifferentiableFunction) = Dual{DifferentiableFunction}(o)
adjoint(o::Dual{DifferentiableFunction}) = error("Second derivative not implemented.")
adjoint(o::TwiceDifferentiableFunction) = Dual{TwiceDifferentiableFunction}(o)
adjoint(o::Dual{TwiceDifferentiableFunction}) = Dual{Dual{TwiceDifferentiableFunction}}(o)
adjoint(o::Dual{Dual{TwiceDifferentiableFunction}}) = error("Higher-order derivatives undefined for the twice-differentiable function $(o.parent.parent).")

constraints(o::LinearOperator) = Constraints( X ⊗ V == Y ⊗ U )

function ∈(o::Union{ConvexFunction,DifferentiableFunction}, ::Type{Curvature{μ,L}}) where {μ,L}
  if o isa ConvexFunction && L < Inf
    @warn "Convex function $o is constrained to be L-smooth implying that it is differentiable. Use `DifferentiableFunction` instead."
  end
  Constraints( f2 ≥ f1 + g1*(x2-x1) for (x1,f1,g1) ∈ triplets(o), (x2,f2,_) ∈ triplets(o) )
end



include("constraint.jl")  # requires Expression
include("expression.jl")
include("solve.jl")
include("oracle.jl")
include("interpolation.jl")
include("primitives.jl")
include("algorithms.jl")

end
