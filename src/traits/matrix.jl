########################################################
# MATRIX
########################################################

export MatrixTrait, Mat, as_array, as_object

struct MatrixTrait <: Trait
    eltype::Space
    rows::Int
    cols::Int
    elements::Bijection{Object, Matrix{Object}}

    function MatrixTrait(S::Space, rows::Int, cols::Int)
        new(S, rows, cols, Bijection{Object, Matrix{Object}}())
    end
end

space(t::MatrixTrait) = t.eltype

show(io::IO, t::MatrixTrait) = print(io, "Matrix($(space(t)), $(t.rows) × $(t.cols))")

Mat(s::Space, rows::Int, cols::Int) = Space(Symbol(label(s), superscript(rows), "ˣ", superscript(cols)), trait = MatrixTrait(s, rows, cols))

function as_array(x::Object)
    t = get(x, MatrixTrait)
    if isnothing(t)
        error("Object $x is not a matrix.")
    end
    get!(t.elements, x) do
        X = Matrix{Object}(undef, t.rows, t.cols)
        for i = 1:t.rows
            for j = 1:i
                idx = sym_linear_index(i,j,t.rows)
                id = Symbol(label(x), subscript(idx))
                X[i,j] = sample(t.eltype, id)
            end
        end
        for j = 1:t.cols
            for i = 1:j-1
                X[i,j] = X[j,i]
            end
        end
        X
    end
end

function as_object(x::Matrix{Object}, label::Symbol = gensym())
    S = space(x[1,1])
    t = get(Mat(S, size(x)...), MatrixTrait)
    if isnothing(t)
        error("Object $x is not a matrix.")
    end
    if x ∈ values(t.elements)
        return t.elements(x)
    end
    y = sample(Mat(S, size(x)...), label)
    t.elements[y] = x
    return y
end

getindex(x::Object, i::Int, j::Int) = getindex(get(x, MatrixTrait), x, i, j)
getindex(::MatrixTrait, x::Object, i::Int, j::Int) = as_array(x)[i,j]

promote_rule(::Type{Matrix{Object}}, ::Type{Object}) = Object

convert(::Type{Object}, x::Matrix{T}) where T = as_object(convert.(Object, x))
convert(::Type{Object}, x::Matrix{Object}) = as_object(x)
