#########################################################
# EQUALITY
#########################################################

export Equality

struct Equality <: Trait
    Prop::Space
    equality::Object

    function Equality(S::Space, Prop::Space, equality::Symbol = :(==))
        register!(new(Prop, Object(S × S → Prop, equality)))
    end
end

space(t::Equality) = domain(t.equality)[1]

show(io::IO, t::Equality) = print(io, "Equality($(space(t)), $(t.equality))")

trait_objects(t::Equality) = Objects([t.equality])
