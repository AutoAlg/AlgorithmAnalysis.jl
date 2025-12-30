############################################################################################
# CARTESIAN PRODUCT
############################################################################################

struct CartesianProduct{T<:Tuple{Vararg{Space}}} <: Space
    dict::Dict{Tuple{Vararg{Object}}, Object{CartesianProduct{T}}}

    function CartesianProduct{T}() where {T<:Tuple{Vararg{Space}}}
        get!(_CACHE, CartesianProduct{T}) do
            new{T}(
                Dict{Tuple{Vararg{Object}}, Object{CartesianProduct{T}}}()
            )
        end
    end
end

function convert(::Type{<:CartesianProduct}, T::Tuple{Vararg{<:Space}})
    T = CartesianProduct{T}
end

function convert(::Type{Tuple{Vararg{Space}}}, ::CartesianProduct{T}) where T
    T
end

function convert(::Type{<:Object{<:CartesianProduct}}, xs::Tuple{Vararg{<:Object}})
    T = CartesianProduct{Tuple{(space(x) for x ∈ xs)...}}
    get!(T().dict, xs) do
        y = Atom{T}(missing, false)
        T().dict[xs] = y
        y
    end
end

function convert(::Type{Tuple{Vararg{<:Object}}}, x::Object{<:CartesianProduct})
    T = space(x)
    vals = filter( t -> t[2] === x, space(x)().dict)
    if isempty(vals)
        error("Cannot convert")
    else
        first(vals)[1]
    end
end

elements(S::CartesianProduct{T}) where T = Objects{CartesianProduct{T}}(values(S.dict))

as_tuple(x::Object{T}) where {T<:CartesianProduct} = convert(Tuple{Vararg{Object}}, x)
as_tuple(::Type{<:CartesianProduct{T}}) where T = tuple(T.parameters...)
as_tuple(::Type{<:Object{<:CartesianProduct{T}}}) where T = Tuple(Object{t} for t ∈ T)
as_space(x::Tuple{Vararg{<:Object}}) = convert(Object{CartesianProduct}, x)
as_space(x::Vararg{<:Object}) = as_space( tuple(x...) )
elements(x::Object{<:CartesianProduct}, ind::Int) = as_tuple(x)[ind]
getindex(x::Object{<:CartesianProduct}, ind::Int) = as_tuple(x)[ind]
getindex(::Type{T}, ind::Int) where {T<:CartesianProduct} = as_tuple(T)[ind]

length(::Type{T}) where {T<:CartesianProduct} = length(as_tuple(T))

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
    CartesianProduct{T}().dict[x] = y
    # push!(CartesianProduct{T}, y)
    y
end

properties(::CartesianProduct{T}) where T = Properties{T}()

# push!(T::Type{<:CartesianProduct}, x::Tuple{Vararg{<:Object}}) = push!(elements(T), x)
# push!(objs::Object{<:CartesianProduct}, x::Tuple{Vararg{Object}}) = push!(objs, convert(Object{CartesianProduct}, x ))