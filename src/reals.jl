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

function *(X::Matrix{<:Union{JuMP.VariableRef,JuMP.AffExpr}}, Y::Matrix{R})
    if size(X)[2] != size(Y)[1]
        error("Matrix dimensions do not agree for matrix multiplication, dimensions are $(size(X)) and $(size(Y))")
    end
    Z = Matrix{R}(undef, size(X)[1], size(Y)[2])
    for i = 1:size(X)[1], j = 1:size(Y)[2]
        Z[i,j] = R(Zero())
        for k = 1:size(X)[2]
            Z[i,j] += X[i,k]*Y[k,j]
        end
    end
    Z
end

zero(::R) = R(0)

zero(::Type{JuMP.GenericAffExpr}) = JuMP.AffExpr(0)
zero(::Type{JuMP.GenericAffExpr{_A, JuMP.VariableRef} where _A}) = JuMP.AffExpr(0)

iszero(e::R) = e.value isa Zero || (e.value isa Number && iszero(e.value))