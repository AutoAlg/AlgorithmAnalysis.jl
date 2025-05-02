############################################################################################
# ALGEBRA
############################################################################################

############################################################################################
# Addition

+(x::Object, y::Object) = +(promote(x,y)...)
+(x::Any, y::Object) = +(promote(x,y)...)
+(x::Object, y::Any) = +(promote(x,y)...)

+(x::Object{T}...) where T = instance(T).addition(x...)
+(x::T, y::T) where {T<:Object} = instance(space(x)).addition(x,y)

############################################################################################
# Multiplication

*(x::Object, y::Object) = *(promote(x,y)...)
*(x::Any, y::Object) = *(promote(x,y)...)
*(x::Object, y::Any) = *(promote(x,y)...)

*(x::Object{T}...) where T = instance(T).multiplication(x...)
*(x::T, y::T) where {T<:Object} = instance(space(x)).multiplication(x,y)

*(x1::Atom{T1}, x2::Atom{T2}) where {T2<:Space, T1<:LinearFunctional{T2}} = x1(x2)

# Scaling

function *(e1::Object{F}, e2::Object{V}) where {F<:Field, V<:VectorSpace{F}}
    instance(V).scaling(e1,e2)
end

function *(x1::T1, x2::Object{V}) where {T1, F<:Field, V<:VectorSpace{F}}
    if T1 <: juliatype(F)
        F(x1) * x2
    else
        error("Cannot scale vector in $V by a scalar in $T1")
    end
end


############################################################################################
# Additive inverse

-(e::Object) = (-1)*e


############################################################################################
# Subtraction

-(e1::Object, e2::Object) = e1 + (-e2)


############################################################################################
# Multiplicative inverse

# inv(e::Object) = Inverse(e)


############################################################################################
# Division

# /(e1::Object, e2::Object) = e1 * inv(e2)



# Squared norm of a vector in a normed vector space
function ^(v::Object{<:NormedVectorSpace}, n::Int)
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
function ⊗(x1::T, x2::T) where {T<:Vector{<:Object{<:InnerProductSpace}}}
    Object{field(space(eltype(T)))}[ x'*y for x ∈ x1, y ∈ x2 ]
end
