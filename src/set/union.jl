############################################################################################
# UNION
############################################################################################

struct SetUnion{T<:Tuple{Vararg{Space}}} <: Space
    elements::Objects{SetUnion{T}}

    SetUnion{T}() where {T<:Tuple{Vararg{Space}}} = get!(_CACHE, SetUnion{T}) do
        new{T}( Objects{SetUnion{T}}() )
    end
end

spaces(::Type{SetUnion{T}}) where T = T

function ∪(T1::Type{<:Space}, T2::Type{<:Space})
    t1 = T1 <: SetUnion ? spaces(T1) : Tuple{T1}
    t2 = T2 <: SetUnion ? spaces(T2) : Tuple{T2}
    T = sort(unique(collect(t1 ∪ t2)), by = x -> string(x))
    SetUnion{Tuple{T...}}
end
