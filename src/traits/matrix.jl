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
        register!(new(S, rows, cols, Bijection{Object, Matrix{Object}}()))
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
        [ sample(t.eltype, Symbol(label(x), subscript(i), ",", subscript(j))) for i ∈ 1:t.rows, j ∈ 1:t.cols ]
    end
end

function as_object(x::Matrix{Object}, label::Label = missing)
    S = space(x[1,1])
    t = get(Mat(S, size(x)...), MatrixTrait)
    if isnothing(t)
        error("Object $x is not a matrix.")
    end
    if x ∈ values(t.elements)
        return t.elements(x)
    end
    # @warn "Matrix space $t contains no arrays for object $x, so sampling the space."
    if all( isequal(x[i,j], x[j,i]) for i ∈ 1:size(x,1), j ∈ 1:size(x,2) )
        y = sample(Sym(S, size(x,1)), label)
    else
        y = sample(Mat(S, size(x)...), label)
    end
    active_inv(t.elements)[x] = y
    return y
end

getindex(x::Object, i::Int, j::Int) = getindex(get(x, MatrixTrait), x, i, j)
getindex(::MatrixTrait, x::Object, i::Int, j::Int) = as_array(x)[i,j]

promote_rule(::Type{Matrix{Object}}, ::Type{Object}) = Object

convert(::Type{Object}, x::Matrix{T}) where T = as_object(convert.(Object, x))
convert(::Type{Object}, x::Matrix{Object}) = as_object(x)
