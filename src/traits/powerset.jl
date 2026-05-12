########################################################
# POWERSET
########################################################
"""
    Powerset{T} <: Space

The powerset of a set of objects. Each element of the powerset of `T` is a subset of `T`.
"""
mutable struct Powerset{T<:Space} <: Space
    elements::Objects{Subset{T}}

    function Powerset{T}() where {T<:Space}
        get!(_CACHE, Powerset{T}) do
            new{T}( Objects{Subset{T}}() )
        end
    end
end

base(::Powerset{T}) where T = T

sample(::Type{Powerset{T}}, label::Label) where T = Atom{Subset{T}}(label)

push!(::Type{Powerset{T}}, x::Object{Subset{T}}) where T = push!(Powerset{T}().elements, x)
