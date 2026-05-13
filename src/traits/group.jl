########################################################
# GROUP
########################################################

export Group

struct Group <: Trait
    id::Object
    op::Object
    inv::Object
    invop::Object # a - b = a + (-b)

    function Group(S::Space, id::Symbol, op::Symbol, inv::Symbol)
        register!(new(
            Object(S, id),
            Object(S × S → S, op),
            Object(S → S, inv),
            Object(S × S → S, inv)
        ))
    end
end

space(t::Group) = space(t.id)

show(io::IO, t::Group) = print(io, "Group($(space(t)), $(t.id), $(t.op), $(t.inv))")

trait_objects(t::Group) = Objects([t.id, t.op, t.inv, t.invop])
