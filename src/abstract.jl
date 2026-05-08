#########################################################
# ABSTRACT TYPES
#########################################################

export Term, AbstractSpace, AbstractObject, Trait
export Terms, Spaces, Objects, Traits, Label
export label, isequal

abstract type Term end

"""
    AbstractSpace <: Term

A set of mathematical objects with a (possibly empty) set of structures.
"""
abstract type AbstractSpace <: Term end

"""
    AbstractObject <: Term

An object in space `T`.

A subtype is [`AbstractVectorSpace`](@ref).
"""
abstract type AbstractObject <: Term end

"""
    Trait <: Term

An abstract trait.
"""
abstract type Trait <: Term end


#########################################################
# CONSTANTS
#########################################################

const Terms = Set{Term}
const Traits = Set{Trait}
const Label = Union{Symbol, Missing}


#########################################################
# GENERIC METHODS
#########################################################

label(::Term) = missing
isequal(a::Term, b::Term) = a === b
