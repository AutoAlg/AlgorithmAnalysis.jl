########################################################
# RING
########################################################

export Ring

struct Ring <: Trait
    additive_group::Group
    multiplicative_group::Group

    function Ring(S::Space, zero::Symbol = :zero, one::Symbol = :one, add::Symbol = :+, mult::Symbol = :*, neg::Symbol = :-, inv::Symbol = :/)
        register!(new(
            Group(S, zero, add, neg),
            Group(S, one, mult, inv)
        ))
    end
end

space(t::Ring) = space(t.additive_group)

show(io::IO, t::Ring) = print(io, "Ring($(space(t)), $(t.additive_group.id), $(t.multiplicative_group.id), $(t.additive_group.op), $(t.multiplicative_group.op), $(t.additive_group.inv), $(t.multiplicative_group.inv))")

trait_objects(t::Ring) = trait_objects(t.additive_group) ∪ trait_objects(t.multiplicative_group)
