########################################################
# BINDER
########################################################

export Binder, Bind

struct Binder <: Trait
    space::Space

    function Binder(S::Space)
        register!(new(S))
    end
end

space(t::Binder) = t.space

show(io::IO, t::Binder) = print(io, "Binder($(space(t)))")

Bind(s::Space) = Space(Symbol("Binder($s)"), traits = Traits([Binder(s), SingleValued(s)]))
