"An abstract vector space over the field `Number`."
abstract type Vec end

###############################################################################
# Each `Vec` must specialize the following methods.

"Sum to vectors to product another vector."
function sum end

"Scale a vector by a scalar (`Number`)"
function scale end

###############################################################################
# Derived methods.

"Add two vectors."
Base.:+(v1::Vec, v2::Vec) = sum(promote(v1,v2)...)

"Subtract two vectors."
Base.:-(v1::Vec, v2::Vec) = v1 + (-v2)

"Scale a vector."
Base.:*(a::Number, v::Vec) = scale(a,v)
Base.:*(v::Vec, a::Number) = a*v
Base.:/(v::Vec, a::Number) = (1/a)*v

"Negate a vector."
Base.:-(v::Vec) = -1*v

"Zero vector."
struct ZeroVector <: Vec end
zeroVec = ZeroVector()

"Add vector with the zero vector."
sum(v::Vec, ::ZeroVector) = v
sum(::ZeroVector, v::Vec) = v



# "An abstract scalar field compatible with the field `Number`."
# abstract type Scalar <: Vec end

# ###############################################################################
# # Each `Field` must specialize the methods required
# # by `Vec` along with the following methods.

# function sum(a::Number, s::Scalar)::Scalar end

# ###############################################################################
# # Derived methods.

# "Add a scalar and a number."
# Base.:+(a::Number, s::Scalar) = sum(a,s)
# Base.:+(s::Scalar, a::Number) = sum(a,s)

# "Subtract a scalar and a number."
# Base.:-(a::Number, s::Scalar) = sum(a,-s)
# Base.:-(s::Scalar, a::Number) = sum(-a,s)