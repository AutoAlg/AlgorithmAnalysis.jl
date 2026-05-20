########################################################
# SYMMETRIC MATRIX
########################################################

export Symmetric, dim, as_array, as_object

struct Symmetric <: Trait
    eltype::Space
    dim::Int
    elements::Bijection{Object, Matrix{Object}}
    tr::Object

    function Symmetric(S::Space, eltype::Space, dim::Int, tr::Symbol = :tr)
        register!(new(eltype, dim, Bijection{Object, Matrix{Object}}(),
            Object(S → eltype, tr)
        ))
    end
end

space(t::Symmetric) = t.eltype
dim(t::Symmetric) = t.dim
dim(x::Object) = dim(get(x, Symmetric, err_msg = "Object $x is not a matrix"))

show(io::IO, t::Symmetric) = print(io, "Symmetric($(space(t)), $(t.dim))")

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
