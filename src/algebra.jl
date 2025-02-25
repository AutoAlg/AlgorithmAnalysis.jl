############################################################################################
# ALGEBRA

# Decompositions
+(::EmptyDecomposition{T}, ::EmptyDecomposition{T}) where {T} = EmptyDecomposition{T}()
*(::Any, ::EmptyDecomposition{T}) where {T} = EmptyDecomposition{T}()

function +(x1::Gram, x2::Number)
    if x2 == 0
        return x1
    else
        return missing
    end
end
function -(x1::Gram, x2::Gram)
    if issetequal(x1.vecs, x2.vecs)
        return 0
    else
        return missing
    end
end
function +(x1::LinearDecomposition{T}, x2::LinearDecomposition{T}) where {T}
    dict = mergewith(+, weights(x1), weights(x2))
    for (key,value) ∈ dict
        if iszero(key) || iszero(value)
            delete!(dict, key)
        end
    end
    LinearDecomposition{T}(dict)
end
function *(a::DecompositionValue, x::LinearDecomposition{T}) where {T}
    new_weights = Dict{T,DecompositionValue}(keys(weights(x)) .=> map(x->a*x, values(weights(x))))
    LinearDecomposition{T}( new_weights )
end
# +(x1::AffineDecomposition{T}, x2::AffineDecomposition{T}) where {T} = AffineDecomposition{T}( linear(x1) + linear(x2), constant(x1) + constant(x2) )
# +(x::AffineDecomposition{T}, a::Number) where {T} = AffineDecomposition{T}( linear(x), constant(x) + a )
#   +(a::Number, x::AffineDecomposition{T}) where {T} = x + a

# Expressions in a vector space
function +(e1::T, e2::T) where {T<:AbstractVectorSpace}
    if iszero(e1)
        e2
    elseif iszero(e2)
        e1
    elseif hasvalue(e1) && hasvalue(e2)
        T( value(e1) + value(e2) )
    else
        decomp = selfdecomp(e1) + selfdecomp(e2)
        isempty(decomp) ? T(Zero()) : T(decomp)
    end
end

function *(a::DecompositionValue, e::T) where {T<:AbstractVectorSpace}
    hasvalue(e) ? T( a*value(e) ) : T( a*selfdecomp(e) )
end

-(e1::Gram, e2::Number) = e1 + (-e2)
+(e1::AbstractVectorSpace, e2::AbstractVectorSpace) = +(promote(e1,e2)...)
-(e1::AbstractVectorSpace, e2::AbstractVectorSpace) = e1 + (-e2)
-(e::AbstractVectorSpace) = -1*e
*(e::AbstractVectorSpace, a::Any) = a*e
/(e::AbstractVectorSpace, a::Any) = (1/a)*e

# Scalars with numbers
# +(a1::F, a2::Number) where {F<:Field} = F( value(a1) + a2, selfdecomp(a1) + a2 )
# +(a1::Number, a2::Field) = +(promote(a1,a2)...)
# -(a1::Field, a2::Number) = a1 + (-a2)
# -(a1::Number, a2::Field) = a1 + (-a2)



# # Summation
# +(x::T, y::T) where {T<:Expression}
#     prune( LinearDecomposition{T}( prune( mergewith( +, weights(x), weights(y) ) ) ) )
# end
# # function +(x::LinearDecomposition{T}, y::T) where {T<:VectorOrWrapper}
# #     x + LinearDecomposition{T}(Dict(y=>1))
# # end
# # +(x::T, y::LinearDecomposition{T}) where {T<:VectorOrWrapper} = y + x
# +(x::T, y::T) where {T<:VectorOrWrapper} = LinearDecomposition{T}(Dict(x=>1, y=>1))

# function +(x::LinearDecomposition, a::Number)
#     iszero(a) ? x : error("Cannot add linear decompositions and numbers")
# end
# +(a::Number, x::LinearDecomposition) = x + a


# function +(x::T, a::Number) where {T<:AbstractVectorSpace}
#     if iszero(a)
#         x
#     else
#         error("Cannot add vectors and numbers")
#     end
# end
# +(a::Number, x::AbstractVectorSpace) = x + a


# # Subtraction
# -(x::VectorExpression, y::VectorExpression) = x + (-y)

# -(x::VectorExpression, a::Number) = x + (-a)
# -(a::Number, x::VectorExpression) = -x + a

# # Multiplication
# function *(x::LinearDecomposition, y::LinearDecomposition)
#     f = p -> (first(first(p))*first(last(p)) => last(first(p))*last(last(p)))
#     op = (p1,p2)->mergewith(+, Dict(p1), Dict(p2))
#     itrs = Iterators.product( weights(x), weights(y) )
#     d = mapreduce( f, op, itrs )
#     LinearDecomposition{keytype(d)}(d)
# end

# *(x::LinearDecomposition, y::VectorOrWrapper) = x * LinearDecomposition{typeof(y)}(Dict(y=>1))
# *(x::VectorOrWrapper, y::LinearDecomposition) = LinearDecomposition{typeof(x)}(Dict(x=>1)) * y

# # Scaling
# *(a::Number, x::T) where {T<:VectorOrWrapper} = LinearDecomposition{T}(Dict(x=>a))

# function *(a::Number, x::LinearDecomposition{T}) where {T}
#     new_weights = Dict{T,Number}(keys(weights(x)) .=> map(x->a*x, values(weights(x))))
#     LinearDecomposition{T}( new_weights )
# end

# *(x::VectorExpression, a::Number) = a*x
# /(x::VectorExpression, a::Number) = (1/a)*x

# # Negation
# -(x::VectorExpression) = -1*x


# Squared norm of a vector in a normed vector space
function ^(v::OrWrapper{NormedVectorSpace}, n::Int)
    if n == 2
        squarednorm(v)
    else
        error("Can only compute squared norm of vectors.")
    end
end

squarednorm(v::OrWrapper{InnerProductSpace}) = v'*v

"""
    ⊗(x,x)

Outer product (Gram matrix) of two vectors whose elements are themselves vectors in the same inner product space.

# Examples
```julia-repl
julia> x = [ Rⁿ(); Rⁿ(); Rⁿ() ]
julia> y = [ Rⁿ(); Rⁿ() ]
julia> G = x ⊗ y
```
"""
function ⊗(x1::Vector{V}, x2::Vector{V}) where {F<:Field, V<:InnerProductSpace{F}}
    F[ x'*y for x ∈ x1, y ∈ x2 ]
end

+(::Missing, ::Any) = missing
+(::Any, ::Missing) = missing
-(::Missing, ::Any) = missing
-(::Any, ::Missing) = missing
*(::Missing, ::Any) = missing
*(::Any, ::Missing) = missing
/(::Missing, ::Any) = missing
/(::Any, ::Missing) = missing
# -(::Missing) = missing


# Matrix-Number addition and subtraction
function +(x::AbstractArray, y::Number)
    iszero(y) ? x : error("Addition of array and number is ill-defined")
end
+(x::Number, y::AbstractArray) = y + x
-(x::AbstractArray, y::Number) = x + (-y)
-(x::Number, y::AbstractArray) = x + (-y)
