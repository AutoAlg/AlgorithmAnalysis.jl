########################################################
# SYMMETRIC
########################################################

export Symmetric, Sym

struct Symmetric <: Trait
    eltype::Space
    dim::Int

    function Symmetric(S::Space, dim::Int)
        register!(new(S, dim))
    end
end

space(t::Symmetric) = t.eltype

show(io::IO, t::Symmetric) = print(io, "Symmetric($(space(t)), $(t.dim))")

# Sym(s::Space, dim::Int) = Space(Symbol("Sym(", label(s), ", ", dim, ")"), traits = Traits([Symmetric(s, dim), Subset(Mat(s, dim, dim))]))

Sym(s::Space, dim::Int) = Space(Symbol("Sym(", label(s), ", ", dim, ")"), traits = Traits([Symmetric(s, dim), MatrixTrait(s, dim, dim)]))
