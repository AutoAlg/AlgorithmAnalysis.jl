#########################################################
# INNER-PRODUCT SPACE
#########################################################

export InnerProductSpace

struct InnerProductSpace <: Trait
    group::Group
    scale::Object
    adjoint::Object

    function InnerProductSpace(V::Space, F::Space, zero::Symbol = :zero, add::Symbol = :+, neg::Symbol = :-, scale::Symbol = :⋅, adjoint::Symbol = :adjoint)
        register!(new(
            Group(V, zero, add, neg),
            Object(F × V → V, label = scale),
            Object(V → (V → F), label = adjoint)
        ))
    end
end

show(io::IO, t::InnerProductSpace) = print(io, "InnerProductSpace($(t.group.id), $(t.group.op), $(t.group.inv), $(t.scale), $(t.adjoint))")

trait_objects(t::InnerProductSpace) = Objects([t.scale, t.adjoint]) ∪ trait_objects(t.group)
