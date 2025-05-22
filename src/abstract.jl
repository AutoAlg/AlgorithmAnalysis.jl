############################################################################################
# ABSTRACT TYPES
############################################################################################

"""
    Space

A set of mathematical objects with a (possibly empty) set of structures.
"""
abstract type Space end

"""
    Object{T}

An object in space `T`.

A subtype is [`AbstractVectorSpace`](@ref).
"""
abstract type Object{T<:Space} end

"""
    Property{T}

A property of objects in space `T`. Properties can be associated with objects to describe actions that can be applied to them.
"""
abstract type Property{T<:Space} end

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


############################################################################################
# CONSTANTS
############################################################################################

const Objects{T} = Set{Object{T}}
const Properties = Set{Property}
const Constraints = Set{Constraint}
const Label = Union{Symbol, Missing}