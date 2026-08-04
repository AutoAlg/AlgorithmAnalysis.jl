export R, Rⁿ, Sⁿ, VectorSpace, MatrixSpace, field
export zero, one, mat, size, tr

abstract type Field <: NodeType end
abstract type VectorSpace{F} <: NodeType end
abstract type MatrixSpace{F} <: NodeType end
abstract type SymmetricMatrix{F} <: MatrixSpace{F} end

"""
    R

The field of real numbers.
"""
abstract type R <: Field end

"""
    Rⁿ

A real finite-dimensional vector space of arbitrarily large dimension. Note that the superscript `n` does *not* refer to the variable `n`, but is simply part of the symbol for the vector space (`Rⁿ` is a single symbol in Julia). To create other similar vector spaces, just create an abstract type that subtypes `VectorSpace{R}`, such as:

    abstract type Rᵐ <: VectorSpace{R} end

"""
abstract type Rⁿ <: VectorSpace{R} end

"""
    Sⁿ

A real finite-dimensional vector space of symmetric matrices.
"""
abstract type Sⁿ <: MatrixSpace{R} end

Base.convert(::Type{<:Node}, val::Number) = R(val)
Base.convert(::Type{Node{R}}, val::Number) = R(val)
Base.promote_rule(::Type{Node{R}}, ::Type{<:Number}) = Node{R}

function Base.convert(::Type{T}, val::Node{R}) where {T<:Real}
    if isone(val)
        one(T)
    elseif iszero(val)
        zero(T)
    elseif is_constant(val)
        arguments(val)[1]
    else
        error("Cannot convert $val to a real.")
    end
end

for op in (:+, :-, :*, :/, :^, :≤, :≥, :(==))
    @eval begin
        Base.$op(x::Number, y::Node{R}) = $op(promote(x, y)...)
        Base.$op(x::Node{R}, y::Number) = $op(promote(x, y)...)
    end
end

Base.:*(x::Number, y::Node{Rⁿ}) = R(x) * y


field(::Type{<:VectorSpace{F}}) where F = F
field(::Node{V}) where {F,V<:VectorSpace{F}} = F
field(::Type{R}) = R
field(::Node{R}) = R
field(::Type{Sⁿ}) = R
field(::Node{Sⁿ}) = R

zero(::Type{Rⁿ}) = Term{Rⁿ}(zero, [])
zero(::Type{R}) = Term{R}(zero, [])
one(::Type{R}) = Term{R}(one, [])
R(val::Real) = Term{R}(constant, [val])
R(x::Node{<:Real}) = R(value(x))
R(x::Node{R}) = x

iszero(x::Node) = iscall(x) && isequal(operation(x), zero)
isone(x::Node) = iscall(x) && isequal(operation(x), one)

function Sⁿ(A::Matrix{Node{R}})
    size(A,1) ≠ size(A,2) && error("Matrix $A is not square")
    n = size(A,1)
    # for i in 1:n
    #     for j in 1:i
    #         if !isequal(A[i,j], A[j,i])
    #             error("Matrix $A is not symmetric")
    #         end
    #     end
    # end
    return Term{Sⁿ}(Matrix, vec(A))
end

function Base.convert(::Type{<:Node}, A::Matrix)
    Sⁿ(Base.convert.(Node, A))
end

tr(A::Node{Sⁿ}) = Term{R}(tr, [A])
tr(A::Matrix) = la.tr(A)
⋅(A::Node{Sⁿ}, B::Node{Sⁿ}) = arguments(A) ⋅ arguments(B) # tr(A*B)

function size(A::Node{Sⁿ}, i::Union{Int, Missing} = missing)
    n = Integer(sqrt(length(arguments(A))))
    if ismissing(i)
        (n,n)
    elseif i == 1 || i == 2
        n
    else
        error("Invalid index $i")
    end
end

+(x::T, y::T) where {T<:Node{Sⁿ}} = Term{Sⁿ}(+, [x, y])
*(x::T, y::T) where {T<:Node{Sⁿ}} = Term{Sⁿ}(*, [x, y])
-(x::T, y::T) where {T<:Node{Sⁿ}} = Term{Sⁿ}(-, [x, y])
/(x::T, y::T) where {T<:Node{Sⁿ}} = Term{Sⁿ}(/, [x, y])

+(x::T...) where {F<:Field, T<:Node{F}} = Term{F}(+, x)
*(x::T...) where {F<:Field, T<:Node{F}} = Term{F}(*, x)
-(x::T, y::T) where {F<:Field, T<:Node{F}} = Term{F}(-, [x, y])
/(x::T, y::T) where {F<:Field, T<:Node{F}} = Term{F}(/, [x, y])
-(x::Node{F}) where {F<:Field} = Term{F}(-, [x])
⋅(x::T...) where {F<:Field, T<:Node{F}} = *(x...)



function +(u::Node{V}, v::Node{V}) where {V<:VectorSpace}
    return Term{V}(+, [u, v])
end

+(u::Node{<:VectorSpace}) = u

function -(u::Node{V}, v::Node{V}) where {V<:VectorSpace}
    return Term{V}(-, [u, v])
end

function -(v::Node{V}) where {V<:VectorSpace}
    return Term{V}(-, [v])
end

function *(scalar::Node{F}, v::Node{V}) where {F,V<:VectorSpace{F}}
    return Term{V}(*, [scalar, v])
end

(⋅)(u::Node{V}, v::Node{V}) where {F,V<:VectorSpace{F}} = u'(v)

function adjoint(x::Node{V}) where {F,V<:VectorSpace{F}}
    iszero(x) && return Term{FnType{Tuple{V},F,LinearFunctional}}(zero, [])
    return Term{FnType{Tuple{V},F,LinearFunctional}}(adjoint, [x])
end

function adjoint(f::Node{FnType{Tuple{V},F,LinearFunctional}}) where {F,V<:VectorSpace{F}}
    # If it's already an adjoint term tree, peel it off to prevent double nesting
    if iscall(f) && isequal(operation(f), adjoint)
        return arguments(f)[1]
    end
    return Term{V}(adjoint, [f])
    # return Sym{V}( Symbol(f, "'") )
end

Base.literal_pow(::typeof(^), x::Node{<:VectorSpace}, ::Val{2}) = x'(x)

function (f::Node{FnType{Tuple{V},F,Nothing}})(x::V) where {F,V<:VectorSpace{F}}
    return Term{F}(f, [x])
end

function getindex(A::Node{MatrixSpace{F}}, i::Int, j::Int) where F
    if isequal(operation(A), Gram)
        args = arguments(A)
        return args[i]'(args[j])
    else
        error("Indexing of general matrices not implemented")
    end
end

function mat(v::AbstractVector)
    n = sqrt(length(v))
    if n == round(n)
        n = Int(n)
        return reshape(v, (n, n))
    end
    error("Vector $v cannot be reshaped into a square matrix")
end

mat(A::Node{<:MatrixSpace}) = mat(arguments(A))
size(A::Node{<:MatrixSpace}) = size(mat(A), 1)

const Gram = Sym{FnType{Tuple{Vararg{Rⁿ}}, MatrixSpace{R}, Nothing}}(:Gram)
