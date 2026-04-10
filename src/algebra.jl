############################################################################################
# ALGEBRA

# Decompositions
+(::EmptyDecomposition{T}, ::EmptyDecomposition{T}) where {T} = EmptyDecomposition{T}()
*(::Any, ::EmptyDecomposition{T}) where {T} = EmptyDecomposition{T}()

+(x1::Gram, x2::Number) = iszero(x2) ? x1 : 
+(x1::Number, x2::Gram) = iszero(x1) ? x2 : missing

function +(x1::Gram, x2::Gram)
    if field(x1) != field(x2)
        error("Cannot add Gram matrices over different fields.")
    end
    if length(vecs1(x1)) != length(vecs1(x2)) || length(vecs2(x1)) != length(vecs2(x2))
        error("Cannot add Gram matrices with different numbers of vectors.")
    end
    F = field(x1)
    F[ x1[i,j] + x2[i,j] for i in 1:length(vecs1(x1)), j in 1:length(vecs2(x1)) ]
end

*(a::Number, g::Gram) = [ a*g[i,j] for i in 1:length(vecs1(g)), j in 1:length(vecs2(g)) ]

-(g::Gram) = -1 * g
-(x1::Gram, x2::Gram) = x1 + (-x2)

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
        isempty(decomp) ? zero(T) : T(decomp)
    end
end

function *(a::DecompositionValue, e::T) where {T<:AbstractVectorSpace}
    hasvalue(e) ? T( a*value(e) ) : T( a*selfdecomp(e) )
end

-(e1::AbstractVectorSpace, ::Zero) = e1
-(e1::Gram, e2::Number) = e1 + (-e2)
+(e1::AbstractVectorSpace, e2::AbstractVectorSpace) = +(promote(e1,e2)...)
-(e1::AbstractVectorSpace, e2::AbstractVectorSpace) = e1 + (-e2)
-(e::AbstractVectorSpace) = -1*e
*(e::AbstractVectorSpace, a::Any) = a*e
/(e::AbstractVectorSpace, a::Any) = (1/a)*e

# Squared norm of a vector in a normed vector space
function ^(v::NormedVectorSpace, n::Int)
    if n == 2
        squarednorm(v)
    else
        error("Can only compute squared norm of vectors.")
    end
end

squarednorm(v::InnerProductSpace) = v'*v

"""
    x ⊗ y

Outer product (Gram matrix) of two vectors whose elements are themselves vectors in the same inner product space.

# Examples
```julia-repl
julia> x = [ Rⁿ(); Rⁿ(); Rⁿ() ]
julia> y = [ Rⁿ(); Rⁿ() ]
julia> G = x ⊗ y
```
"""
⊗(x1::Vector{V}, x2::Vector{V}) where {V<:InnerProductSpace} = Gram(x1,x2)



function +(e1::T, e2::T) where {T<:AbstractLinearFunctional}
    if iszero(e1)
        e2
    elseif iszero(e2)
        e1
    elseif hasvalue(e1) && hasvalue(e2)
        T( value(e1) + value(e2) )
    else
        decomp = selfdecomp(e1) + selfdecomp(e2)
        isempty(decomp) ? zero(T) : T(decomp)
    end
end

function *(a::DecompositionValue, e::T) where {T<:AbstractLinearFunctional}
    hasvalue(e) ? T( a*value(e) ) : T( a*selfdecomp(e) )
end

-(e1::AbstractLinearFunctional, ::ZeroFunctional) = e1
-(e::AbstractLinearFunctional) = -1*e