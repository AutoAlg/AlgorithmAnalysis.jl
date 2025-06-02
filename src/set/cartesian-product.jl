
############################################################################################
# CARTESIAN PRODUCT
############################################################################################

struct CartesianProduct{T<:Tuple{Vararg{Space}}} <: Space
    elements::Objects{CartesianProduct{T}}
    dict::Dict{Object{CartesianProduct{T}}, Tuple{Vararg{Object}}}

    function CartesianProduct{T}() where {T<:Tuple{Vararg{Space}}}
        get!(_CACHE, CartesianProduct{T}) do
            new{T}(
                Set{TupleDecomposition{CartesianProduct{T}}}(),
                Dict{Object{CartesianProduct{T}}, Tuple{Vararg{Object}}}()
            )
        end
    end
end

"""
    TupleDecomposition{T} <: Decomposition{T}

A decomposition of an object as a tuple of objects in space `T`. This is the type of object to use for elements of a Cartesian product space.
"""
struct TupleDecomposition{T<:CartesianProduct} <: Decomposition{T}
    value::Tuple{Vararg{Object}}

    function TupleDecomposition(val::Vararg{Object})
        T = CartesianProduct{Tuple{(space(a) for a ∈ val)...}}
        new{T}(val)
    end
end

function convert(::Type{Object{CartesianProduct{T}}}, x::Tuple{Vararg{Object}}) where T
    TupleDecomposition(x...)
end

value(x::TupleDecomposition) = x.value
space(::TupleDecomposition{T}) where T = T
constraints(x::TupleDecomposition) = mapreduce(constraints, ∪, value(x))
next(x::TupleDecomposition) = next.(value(x))
elements(x::TupleDecomposition) = value(x)
elements(x::TupleDecomposition, ind::Int) = value(x)[ind]
getindex(x::TupleDecomposition, ind::Int) = value(x)[ind]

length(x::TupleDecomposition) = length(elements(x))
isempty(x::TupleDecomposition) = isempty(elements(x))
iterate(x::TupleDecomposition) = iterate(elements(x))
iterate(x::TupleDecomposition, state::Int) = iterate(elements(x), state)

spaces(::Type{CartesianProduct{T}}) where T = T

function ×(T1::Type{<:Space}, T2::Type{<:Space})
    t1 = T1 <: CartesianProduct ? spaces(T1) : Tuple{T1}
    t2 = T2 <: CartesianProduct ? spaces(T2) : Tuple{T2}
    T = Tuple{fieldtypes(t1)...,fieldtypes(t2)...}
    CartesianProduct{T}
end


" Convert Tuple{A, B} to Tuple{Object{A}, Object{B}} "
function cartesian_to_tuple(::Type{T}) where {T<:Tuple{Vararg{Space}}}
    Tuple{ ( Object{t} for t ∈ fieldtypes(T) )... }
end

" Convert Tuple{Object{A}, Object{B}} to Tuple{A, B} "
function tuple_to_cartesian(::Type{T}) where {T<:Tuple{Vararg{Object}}}
    Tuple{ ( space(t) for t ∈ fieldtypes(T) )... }
end

elements(T::Type{<:CartesianProduct}, ind::Int) = Set{T}( x[ind] for x ∈ elements(T) )
elements(S::Subset{<:CartesianProduct}, ind::Int) = elements.(elements(S), ind)


function sample(::Type{CartesianProduct{T}}, label::Symbol) where T
    x = Tuple( sample(t, Symbol(label, subscript(i))) for (i,t) ∈ enumerate(fieldtypes(T)) )
    y = TupleDecomposition(x...)
    push!(CartesianProduct{T}, y)
    y
end

push!(T::Type{<:CartesianProduct}, x::Tuple{Vararg{Object}}) = push!(elements(T), x)