########################################################
# MONOID
########################################################

export Monoid

struct Monoid <: Trait
    id::Object
    op::Object

    function Monoid(S::Space, id::Symbol, op::Symbol)
        register!(new(
            Object(S, label = id),
            Object(S × S → S, label = op)
        ))
    end
end

space(t::Monoid) = space(t.id)

show(io::IO, t::Monoid) = print(io, "Monoid($(space(t)), $(t.id), $(t.op))")

trait_objects(t::Monoid) = Objects([t.id, t.op])
