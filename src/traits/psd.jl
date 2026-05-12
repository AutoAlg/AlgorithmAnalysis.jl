########################################################
# POSITIVE SEMIDEFINITE (PSD)
########################################################

export PositiveSemidefinite, PSD

struct PositiveSemidefinite <: Trait
    eltype::Space
    dim::Int

    function PositiveSemidefinite(S::Space, dim::Int)
        register!(new(S, dim))
    end
end

space(t::PositiveSemidefinite) = t.eltype

show(io::IO, t::PositiveSemidefinite) = print(io, "PSD($(space(t)), $(t.dim))")

PSD(s::Space, dim::Int) = Space(Symbol(label(s), "₊", superscript(dim)), trait = PositiveSemidefinite(s, dim))
