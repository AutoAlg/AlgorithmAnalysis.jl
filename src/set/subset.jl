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
    predicate::Function

    function Subset{T}(label::Label = missing) where {T<:Space}
        new{T}( label, Objects{T}(), () -> false )
    end
end

sample(S::Subset, label::Symbol) = (a = sample(parent(S), label); push!(S, a); a)

push!(S::Subset, x) = push!(elements(S), x)