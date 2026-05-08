#########################################################
# INTERSECTION
#########################################################

struct SetIntersection{T<:Tuple{Vararg{Space}}} <: Space
    elements::Objects{SetIntersection{T}}

    SetIntersection{T}() where {T<:Tuple{Vararg{Space}}} = get!(_CACHE, SetIntersection{T}) do
        new{T}( Objects{SetIntersection{T}}() )
    end
end

spaces(::Type{SetIntersection{T}}) where T = T

function ∩(T1::Type{<:Space}, T2::Type{<:Space})
    t1 = T1 <: SetIntersection ? spaces(T1) : Tuple{T1}
    t2 = T2 <: SetIntersection ? spaces(T2) : Tuple{T2}
    T = sort(unique(collect(t1 ∪ t2)), by = x -> string(x))
    SetIntersection{Tuple{T...}}
end

elements(::Type{SetIntersection{T}}) where T = mapreduce(elements, ∩, T)

export ∧

∧(::Type{T1}, ::Type{T2}) where {T1<:Space, T2<:Space} = T1 ∩ T2