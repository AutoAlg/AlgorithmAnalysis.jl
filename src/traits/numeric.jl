########################################################
# NUMERIC
########################################################

export Numeric, datatype, numeric

struct Numeric <: Trait
    S::Space
    T::DataType

    function Numeric(S::Space, T::DataType = Float64)
        @eval begin
            Base.convert(::Type{Object}, val::$T) = Object($S, Symbol(val), value = val)
            Base.promote_rule(::Type{Object}, ::Type{<:$T}) = Object
        end
        register!(new(S, T))
    end
end

space(t::Numeric) = t.S
datatype(t::Numeric) = t.T

show(io::IO, t::Numeric) = print(io, "Numeric($(t.T))")

numeric(universe::Universe = get_universe()) = filter(S -> hastrait(S, Numeric), spaces(universe))
