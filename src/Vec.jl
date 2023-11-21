"An abstract vector space with vectors in V and scalars in F."
abstract type Vec{V,F<:Number} end

###############################################################################
# Each `Vec` must provide a specialized method for the following functions.
# The functions should be type stable in that they return vectors in Vec{V,F}.

function sum(v1::Vec{V1,F1}, v2::Vec{V2,F2}) where {V,F,V1<:V,V2<:V,F1<:F,F2<:F} end
function scale(a::F1, v::Vec{V,F2}) where {V,F,F1<:F,F2<:F} end

###############################################################################
# Derived vector functions.

"Add vectors."
Base.:+(v1::Vec{V1,F1}, v2::Vec{V2,F2}) where {V,F,V1<:V,V2<:V,F1<:F,F2<:F} = sum(v1,v2)

"Subtract vectors."
Base.:-(v1::Vec{V1,F1}, v2::Vec{V2,F2}) where {V,F,V1<:V,V2<:V,F1<:F,F2<:F} = v1 + (-v2)

"Multiply vector by scalar."
Base.:*(a::F1, v::Vec{V,F2}) where {V,F,F1<:F,F2<:F} = scale(a,v)

"Negate vector."
Base.:-(v::Vec) = -1*v


# struct ZeroScalar <: Number end
# struct OneScalar <: Number end
# struct ZeroVector <: Vec{Any,Number} end

# "Multiply vector by zero."
# scale(::Type{ZeroScalar}, v::Vec) = ZeroVector

# "Multiply vector by one."
# scale(::OneScalar, v::Vec) = v

# "Add vector with the zero vector."
# sum(::ZeroVector, v::Vec) = v
