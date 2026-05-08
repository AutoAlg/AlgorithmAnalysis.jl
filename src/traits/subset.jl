#########################################################
# SUBSET
#########################################################
export Subset, ⊂, parent

struct Subset <: Trait
    parent::Space
end

⊂(X::Space, Y::Space) = push!(traits(X), Subset(Y))

parent(t::Subset) = t.parent
parent(s::Space) = hastrait(s, Subset) ? parent(get(s, Subset)) : s

show(io::IO, t::Subset) = print(io, "Subset of ", t.parent)

domain(s::Subset) = domain(parent(s))
codomain(s::Subset) = codomain(parent(s))

hastrait(s::Space, T::Type{<:Trait}) = !isnothing(get(s, T))
hastrait(x::Object, T::Type{<:Trait}) = hastrait(space(x), T)
