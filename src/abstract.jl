############################################################################################
# ABSTRACT TYPES
############################################################################################

"""
    Component

An algorithmic component.
"""
abstract type Component end

"""
    Space

A set of mathematical objects with a (possibly empty) set of structures.
"""
abstract type Space <: Component end

"""
    Object{T}

An object in space `T`.

A subtype is [`AbstractVectorSpace`](@ref).
"""
abstract type Object{T<:Space} <: Component end

"""
    Property{T}

A property of objects in `T`. Properties can be associated with objects to describe actions that can be applied to them.
"""
abstract type Property{T} <: Component end

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
abstract type Constraint <: Component end

"""
    ConstraintSet

An abstract set for use in a [`Constraint`](@ref).
"""
abstract type ConstraintSet <: Component end


############################################################################################
# CONSTANTS
############################################################################################

const Components = Set{Union{Component, Type{<:Space}}}
const Objects{T} = Set{Object{T}}
const Properties{T} = Set{Property{T}}
const Constraints = Set{Constraint}
const Label = Union{Symbol, Missing}


############################################################################################
# UTILS
############################################################################################

function subscript(i::Integer)
    i<0 ? error("$i is negative") : join('₀'+d for d in reverse(digits(i)))
end

function superscript(i::Integer)
    if i<0
        error("$i is negative")
    end
    join(
        if d == 1
            '\u00B9'
        elseif d == 2
            '\u00B2'
        elseif d == 3
            '\u00B3'
        else
            '⁰'+d
        end
        for d in reverse(digits(i))
    )
end