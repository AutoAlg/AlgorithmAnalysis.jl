############################################################################################
# Real numbers

"""
    R <: Field

The field of real numbers.
"""
@field R

"""
    Rⁿ <: InnerProductSpace

A real inner product space.
"""
@innerproductspace Rⁿ, R

"""
    Rᵐ <: InnerProductSpace

A real inner product space.
"""
@innerproductspace Rᵐ, R

@innerproductspace X, R


convert(::Type{R}, x::Number) = R(x)
promote_rule(::Type{R}, ::Type{<:Number}) = R

# +(x::R, y::R) = LinearDecomposition{R}( Dict( R(1) => value(x) + value(y) ) )
+(x::Number, y::R) = +(promote(x,y)...)
+(x::R, y::Number) = y + x
-(x::Number, y::R) = x + (-y)
-(x::R, y::Number) = x + (-y)

zero(::R) = R(0)