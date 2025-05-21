############################################################################################
# ABSTRACT TYPES
############################################################################################

"""
    Space

A set of mathematical objects with a (possibly empty) set of structures.
"""
abstract type Space end

"""
    Object

An object.

A subtype is [`AbstractVectorSpace`](@ref).
"""
abstract type Object{T<:Space} end

"""
    Decomposition{T}

An object in space `T` that is a decomposition of other objects.
"""
abstract type Decomposition{T<:Space} <: Object{T} end

"""
    Constraint

An abstract constraint that consists of an [`Object`](@ref) belonging to a [`ConstraintSet`](@ref).

Concrete subtypes should provide methods for `object`, `set`, `∈`, `isequal`, and `check`.
"""
abstract type Constraint end

"""
    ConstraintSet

An abstract set for use in a [`Constraint`](@ref).
"""
abstract type ConstraintSet end

# """
#     Operator

# An operator is a relation between pairs of objects. Operators may be sampled at objects in their domain to produce output objects in their codomain. Operators may also have other associated operators; for instance, a linear operator has an associated adjoint. Each operator can be sampled at a point in its domain, and it can have a set of properties.

# Any concrete subtype of `Operator` must have the following fields:
#     label::String
#     properties::Properties

# Some concrete operators are [`LinearMap`](@ref), [`Functional`](@ref), etc.
# """
# abstract type Operator{X<:Space, Y<:Space} <: Space end

"""
    Relation{X,Y}

A relation is a subset of the product space Element{X} × Element{Y}.
"""
abstract type Relation{X,Y} <: Space end


############################################################################################
# OPERATOR PROPERTIES
############################################################################################

"""
    Property{T}

Property of objects of type `T`.
"""
abstract type Property end

struct RightUnique <: Property end
struct LeftUnique <: Property end

export RightUnique, LeftUnique

# abstract type OnePointProperty <: Property end
# abstract type TwoPointProperty <: Property end
# abstract type AllPointProperty <: Property end

# abstract type OperatorProperty <: Property end
# abstract type FunctionProperty <: Property end

# abstract type InnerProductSpaceProperty <: OperatorProperty end
# abstract type NormedVectorSpaceProperty <: OperatorProperty end
# abstract type Monotonicity <: InnerProductSpaceProperty end
# abstract type RelativeBoundedness <: NormedVectorSpaceProperty end
# abstract type Boundedness <: NormedVectorSpaceProperty end
# abstract type LinearMapProperty <: Property end
# abstract type SquareLinearMapProperty <: Property end
# abstract type FunctionalProperty <: Property end

############################################################################################
# CONSTANTS
############################################################################################

const Objects{T} = Set{Object{T}}
# const Operators = Set{Object{<:Operator}}
# const Operators = Set{Object}
const Constraints = Set{Constraint}
const Properties = Set{Property}
const Relations = Set{Relation}
const Spaces = Set{Space}
const Label = Union{Symbol, Missing}