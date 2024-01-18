############################################################################################
# Abstract types

"An abstract constraint that consists of an expression belonging to a set."
abstract type Constraint end

abstract type ConstraintSet end

"An oracle is a set of operators and the ways in which they are related. For instance, an oracle may consist of the operators A and Aᵀ where A is linear and Aᵀ is its tranpose. Each operator can be sampled at a point in its domain, and its relation can be constrained to be in a class. Furthermore, the set of operators can also be constrained to be in a class."
abstract type Oracle end

"An abstract expression. Each expression can be a constant (nonzero or zero), a variable (with known or unknown value), or a decomposition (function) of other expressions."
abstract type Expression end

"An abstract field. An element of a field is a scalar. A scalar is an expression that can be an affine function of other scalars and inner products of points in an inner product space over the field."
abstract type Field <: Expression end

"An abstract vector space. A vector is an expression that can be a linear function of other vectors."
abstract type VectorSpace{F<:Field} <: Expression end

"An abstract normed vector space. The squared norm of a vector produces a scalar."
abstract type NormedVectorSpace{F<:Field} <: VectorSpace{F} end

"An abstract inner product space. The inner product of two vectors produces a scalar, and the squared norm is the inner product of a vector with itself."
abstract type InnerProductSpace{F<:Field} <: NormedVectorSpace{F} end


############################################################################################
# Constants

"A set of oracles."
const Oracles = Set{Oracle}

"A set of constraints."
const Constraints = Set{Constraint}


############################################################################################
# Oracles

abstract type AbstractOperator{X,Y} <: Oracle end
abstract type AbstractFunction{X,Y} <: AbstractOperator{X,Y} end
abstract type AbstractLinearMap{X,Y} <: AbstractFunction{X,Y} end
abstract type AbstractSymmetricLinearMap{X} <: AbstractLinearMap{X,X} end
abstract type AbstractSkewSymmetricLinearMap{X} <: AbstractLinearMap{X,X} end
abstract type AbstractFunctional{X} <: AbstractFunction{X,F where F} end
abstract type AbstractSubdifferentiableFunctional{X} <: AbstractFunctional{X} end
abstract type AbstractDifferentiableFunctional{X} <: AbstractSubdifferentiableFunctional{X} end
abstract type AbstractTwiceDifferentiableFunctional{X} <: AbstractDifferentiableFunctional{X} end
abstract type AbstractInfinitelyDifferentiableFunctional{X} <: AbstractTwiceDifferentiableFunctional{X} end
abstract type AbstractLinearFunctional{X} <: AbstractInfinitelyDifferentiableFunctional{X} end


############################################################################################
# Properties

############################################################################################
# Property

abstract type Property end

const Properties = Set{Property}

abstract type OperatorClass <: Property end
abstract type FunctionClass <: Property end

abstract type InnerProductSpaceProperty <: OperatorClass end
abstract type NormedVectorSpaceProperty <: OperatorClass end
abstract type Monotonicity <: InnerProductSpaceProperty end
abstract type RelativeBoundedness <: NormedVectorSpaceProperty end
abstract type Boundedness <: NormedVectorSpaceProperty end
abstract type LinearMapProperty <: Property end
abstract type SquareLinearMapProperty <: Property end
abstract type FunctionalProperty <: Property end
