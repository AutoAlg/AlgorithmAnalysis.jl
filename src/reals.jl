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


convert(::Type{R}, x::Number) = R(x)
promote_rule(::Type{R}, ::Type{<:Number}) = R

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

# Scalar multiplication: Matrix * R
function *(X::Matrix{<:Union{JuMP.VariableRef,JuMP.AffExpr}}, y::R)
    Z = similar(X, R)
    for i in eachindex(X)
        Z[i] = X[i] * y
    end
    Z
end

# Scalar multiplication: R * Matrix
function *(y::R, X::Matrix{<:Union{JuMP.VariableRef,JuMP.AffExpr}})
    Z = similar(X, R)
    for i in eachindex(X)
        Z[i] = y * X[i]
    end
    Z
end

# # Symmetric matrix multiplication: Symmetric * Matrix{R}
# function *(X::la.Symmetric{<:Union{JuMP.VariableRef,JuMP.AffExpr},<:Matrix}, Y::Matrix{R})
#     parent(X) * Y
# end

# Symmetric matrix multiplication: Symmetric * Gram
function *(X::la.Symmetric{<:Union{JuMP.VariableRef,JuMP.AffExpr},<:Matrix}, g::Gram)
    Y = evaluate(g)
    parent(X) * Y
end

# # Symmetric scalar multiplication: Symmetric * R
# function *(X::la.Symmetric{<:Union{JuMP.VariableRef,JuMP.AffExpr},<:Matrix}, y::R)
#     parent(X) * y
# end

# # Symmetric scalar multiplication: R * Symmetric
# function *(y::R, X::la.Symmetric{<:Union{JuMP.VariableRef,JuMP.AffExpr},<:Matrix})
#     y * parent(X)
# end

zero(::R) = R(0)

zero(::Type{JuMP.GenericAffExpr}) = JuMP.AffExpr(0)
zero(::Type{JuMP.GenericAffExpr{_A, JuMP.VariableRef} where _A}) = JuMP.AffExpr(0)

iszero(e::R) = e.value isa Zero || (e.value isa Number && iszero(e.value))