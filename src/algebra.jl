############################################################################################
# ALGEBRA
############################################################################################

############################################################################################
# Addition

+(x::Element{T}...) where T = instance(T).addition( x... )

function +(x1::T1, x2::Element{T2}) where {T1,T2}
    if T1 <: juliatype(T2)
        T2(x1) + x2
    else
        error("Cannot add elements of type $T1 and $(Element{T2})")
    end
end

function +(x1::Element{T1}, x2::T2) where {T1,T2}
    if T2 <: juliatype(T1)
        x1 + T1(x2)
    else
        error("Cannot add elements of type $(Element{T1}) and $T2")
    end
end

############################################################################################
# Multiplication

*(x::Element{T}...) where T = instance(T).multiplication( x... )

function *(x1::T1, x2::Element{T2}) where {T1,T2}
    if T1 <: juliatype(T2)
        T2(x1) * x2
    else
        error("Cannot multiply elements of type $T1 and $(Element{T2})")
    end
end

function *(x1::Element{T1}, x2::T2) where {T1,T2}
    if T2 <: juliatype(T1)
        x1 + T1(x2)
    else
        error("Cannot multiply elements of type $(Element{T1}) and $T2")
    end
end

*(x1::Element{T1}, x2::Element{T2}) where {T2, T1<:LinearMap{T2}} = x1(x2)

# Scaling

function *(e1::Element{F}, e2::Element{V}) where {F<:Field, V<:VectorSpace{F}}
    instance(V).scaling(e1,e2)
end

function *(x1::T1, x2::Element{V}) where {T1, F<:Field, V<:VectorSpace{F}}
    if T1 <: juliatype(F)
        F(x1) * x2
    else
        error("Cannot scale vector in $V by a scalar in $T1")
    end
end


############################################################################################
# Additive inverse

-(e::Expression) = (-1)*e


############################################################################################
# Subtraction

-(e1::Element, e2::Element) = e1 + (-e2)


############################################################################################
# Multiplicative inverse

# inv(e::Expression) = Inverse(e)


############################################################################################
# Division

/(e1::Expression, e2::Expression) = e1 * inv(e2)



# Squared norm of a vector in a normed vector space
function ^(v::Expression{<:NormedVectorSpace}, n::Int)
    if n == 2
        v'*v
    else
        error("Unknown power $n for expressions in space $(space(v)).")
    end
end

"""
    x1 ⊗ x2

Outer product (Gram matrix) of two vectors whose elements are expressions in the same inner product space. The result is a matrix whose elements are expressions in the corresponding field.

# Examples
```julia-repl
julia> x1 = [ Rⁿ(); Rⁿ(); Rⁿ() ]
julia> x2 = [ Rⁿ(); Rⁿ() ]
julia> G = x1 ⊗ x2
```
"""
function ⊗(x1::T, x2::T) where {T<:Vector{<:Expression{<:InnerProductSpace}}}
    Expression{field(space(eltype(T)))}[ x'*y for x ∈ x1, y ∈ x2 ]
end
