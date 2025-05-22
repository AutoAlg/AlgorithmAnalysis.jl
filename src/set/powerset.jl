############################################################################################
"""
    Powerset <: Space

The powerset of a set of objects.
"""
struct Powerset{T<:Space} <: Space end

base(::Powerset{T}) where T = T