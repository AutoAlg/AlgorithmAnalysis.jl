############################################################################################
# SUBSET
############################################################################################
abstract type AbstractSubset{T<:Space} <: Space end

parent(::AbstractSubset{T}) where T = T

"""
    Subset{T} <: Space

A subset of a space of objects.
"""
mutable struct Subset{T<:Space} <: AbstractSubset{T}
    label::Label
    elements::Objects{T}

    function Subset{T}(label::Label = missing) where {T<:Space}
        s = new{T}( label, Objects{T}() )
        # push!(Powerset{T}, s)
        # s
    end
end

sample(s::Subset, label::Symbol) = (a = sample(parent(s), label); push!(s, a); a)

push!(s::Subset, x) = push!(elements(s), x)