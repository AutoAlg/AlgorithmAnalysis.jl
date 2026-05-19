########################################################
# SYMMETRIC MATRIX
########################################################

export Symmetric, Sym, dim, as_array, as_object

struct Symmetric <: Trait
    eltype::Space
    dim::Int
    elements::Bijection{Object, Matrix{Object}}

    function Symmetric(S::Space, dim::Int)
        new(S, dim, Bijection{Object, Matrix{Object}}())
    end
end

space(t::Symmetric) = t.eltype
dim(t::Symmetric) = t.dim

show(io::IO, t::Symmetric) = print(io, "Symmetric($(space(t)), $(t.dim))")

function Sym(s::Space, dim::Int)
    S = Space(Symbol("Sym(", label(s), ", ", dim, ")"), trait = Symmetric(s, dim))
    if isnothing(get(S, Group))
        @trait S, Group(:id, :*, :inv)
        value!(id(S), Diagonal(ones(s, dim)))
    end
    if isnothing(get(S, InnerProductSpace))
        @trait S, InnerProductSpace(R, :zero, :+, :-, :⋅, :adjoint)
        value!(zero(S), zeros(s, dim, dim))
    end
    if isnothing(get(S, Order))
        @trait S, Order(Prop, :⪯)
    end
    if isnothing(get(S, Numeric)) && !isnothing(get(s, Numeric))
        T = datatype(get(s, Numeric))
        @trait S, Numeric(Matrix{T})
    end
    return S
end

function as_array(x::Object)
    t = get(x, Symmetric)
    if isnothing(t)
        error("Object $x is not a matrix.")
    end
    get!(t.elements, x) do
        X = Matrix{Object}(undef, t.dim, t.dim)
        for i = 1:t.dim
            for j = 1:i
                idx = sym_linear_index(i,j,t.dim)
                id = Symbol(label(x), subscript(idx))
                X[i,j] = sample(t.eltype, id)
            end
        end
        for j = 1:t.dim
            for i = 1:j-1
                X[i,j] = X[j,i]
            end
        end
        X
    end
end

function as_object(x::Matrix{Object}, label::Symbol = gensym())
    if size(x,1) ≠ size(x,2)
        error("Non-square matrices not implemented")
    end
    n = size(x,1)
    if !all(x[i,j] === x[j,i] for i ∈ 1:n, j ∈ 1:n)
        error("Non-symmetric matrices not implemented")
    end
    if size(x,1) == 0
        return nothing
    end
    S = space(x[1,1])
    t = get(Sym(S, n), Symmetric)
    if isnothing(t)
        error("Object $x is not a matrix.")
    end
    if x ∈ values(t.elements)
        return t.elements(x)
    end
    y = sample(Sym(S, n), label)
    t.elements[y] = x
    return y
end

getindex(x::Object, i::Int, j::Int) = getindex(get(x, Symmetric), x, i, j)
getindex(::Symmetric, x::Object, i::Int, j::Int) = as_array(x)[i,j]

promote_rule(::Type{Matrix{Object}}, ::Type{Object}) = Object

convert(::Type{Object}, x::Matrix{T}) where T = as_object(convert.(Object, x))
convert(::Type{Object}, x::Matrix{Object}) = as_object(x)
