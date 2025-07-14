############################################################################################
# WRAPPER

"Wrapper for the dual of a vector in an inner product space."
struct Dual{T} <: Wrapper{T}
    parent::T
end

"Wrapper for the transpose of a linear map."
struct Transpose{T<:AbstractLinearMap} <: Wrapper{T}
    parent::T
end

abstract type AbstractDifferential{T} <: Wrapper{T} end
abstract type AbstractSubdifferential{T} <: AbstractDifferential{T} end

"Generic wrapper for the subdifferential of a subdifferentiable functional."
struct Subdifferential{T<:AbstractSubdifferentiableFunctional} <: AbstractSubdifferential{T}
    parent::T
end

"Generic wrapper for the gradient of a differentiable functional."
struct Gradient{T<:AbstractDifferentiableFunctional} <: AbstractSubdifferential{T}
    parent::T
end

struct GradientOf{T<:AbstractDifferentiableFunctional} <: Wrapper{T}
    parent::T
end

"Generic wrapper for the Hessian of a twice-differentiable functional."
struct Hessian{T<:AbstractTwiceDifferentiableFunctional} <: AbstractDifferential{T}
    parent::T
end


############################################################################################
# Subset

# struct Subset{T}
#     properties::Properties

#     Subset(T) = new{T}(Set{Property{T}}())
# end


############################################################################################
# Unwrap

"""
    unwrap(w)

Unwrap a wrapper (get the object that it wraps).
"""
unwrap(x) = x
unwrap(w::W) where {W<:Wrapper} = w.parent.associations[Base.typename(W).wrapper]


iszero(w::Wrapper) = iszero(unwrap(w))
