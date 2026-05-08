#########################################################
# ORDER
#########################################################

export Order

struct Order <: Trait
    space::Space
    Prop::Space
    ordering::Object
    min::Object
    max::Object

    function Order(S::Space, Prop::Space, ordering::Symbol = :≤, min::Symbol = :min, max::Symbol = :max)
        register!(new(S, Prop,
            Object(S × S → Prop, label = ordering),
            Object(S × Prop → S, label = min),
            Object(S × Prop → S, label = max)
        ))
    end
end

space(t::Order) = domain(t.ordering)[1]

show(io::IO, t::Order) = print(io, "Order($(space(t)), $(t.ordering), $(t.min), $(t.max))")

trait_objects(t::Order) = Objects([t.ordering, t.min, t.max])
