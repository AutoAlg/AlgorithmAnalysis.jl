############################################################################################
# CARTESIAN PRODUCT
############################################################################################

struct CartesianProduct{T<:Tuple{Vararg{Space}}} <: Space
    elements::Objects{CartesianProduct{T}}
    dict::Dict{Object{CartesianProduct{T}}, Tuple{Vararg{Object}}}

    function CartesianProduct{T}() where {T<:Tuple{Vararg{Space}}}
        get!(_CACHE, CartesianProduct{T}) do
            new{T}(
                Objects{CartesianProduct{T}}(),
                Dict{Object{CartesianProduct{T}}, Tuple{Vararg{Object}}}()
            )
        end
    end
end

function convert(::Type{Object{CartesianProduct}}, xs::Tuple{Vararg{Object}})
    T = CartesianProduct{Tuple{(space(x) for x ∈ xs)...}}
    y = Atom{T}(missing, false)
    T().dict[y] = xs
    push!(T, y)
    y
end

as_tuple(x::Object{T}) where {T<:CartesianProduct} = T().dict[x]
elements(x::Object{<:CartesianProduct}, ind::Int) = as_tuple(x)[ind]
getindex(x::Object{<:CartesianProduct}, ind::Int) = as_tuple(x)[ind]

spaces(::Type{CartesianProduct{T}}) where T = T

function ×(T1::Type{<:Space}, T2::Type{<:Space})
    t1 = T1 <: CartesianProduct ? spaces(T1) : Tuple{T1}
    t2 = T2 <: CartesianProduct ? spaces(T2) : Tuple{T2}
    T = Tuple{fieldtypes(t1)...,fieldtypes(t2)...}
    CartesianProduct{T}
end

elements(T::Type{<:CartesianProduct}, ind::Int) = Set{T}( x[ind] for x ∈ elements(T) )
elements(S::Subset{<:CartesianProduct}, ind::Int) = elements.(elements(S), ind)

function sample(::Type{CartesianProduct{T}}, label::Symbol) where T
    x = Tuple( sample(t, Symbol(label, subscript(i))) for (i,t) ∈ enumerate(fieldtypes(T)) )
    y = Atom{CartesianProduct{T}}(label, false)
    CartesianProduct{T}().dict[y] = x
    push!(CartesianProduct{T}, y)
    y
end

push!(T::Type{<:CartesianProduct}, x::Tuple{Vararg{Object}}) = push!(elements(T), x)