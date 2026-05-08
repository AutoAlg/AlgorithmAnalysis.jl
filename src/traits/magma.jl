#########################################################
# MAGMA
#########################################################

export Magma

struct Magma <: Trait
    op::Object

    function Magma(S::Space, op::Symbol)
        register!(new(Object(S × S → S, label = op)))
    end
end

space(t::Magma) = domain(t.op)[1]

show(io::IO, t::Magma) = print(io, "Magma($(space(t)), $(t.op))")

trait_objects(t::Magma) = Objects([t.op])
