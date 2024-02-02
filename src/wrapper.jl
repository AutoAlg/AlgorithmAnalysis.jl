############################################################################################
# Generic wrappers

"""
    LinearDecomposition

Decomposition of an expression as a linear function of other expressions.

# Fields
    weights::Dict{T, Number}

# Constructors
    LinearDecomposition{T}()
    LinearDecomposition{T}(weights)
"""
struct LinearDecomposition{T} <: Wrapper{T}
  weights::Dict{T,Number}

  LinearDecomposition{T}(weights::Dict{<:T,<:Number}) where {T} = new{T}(Dict{T,Number}(weights))
end

"""
    AffineDecomposition

Decomposition of an expression as an affine function of other expressions.

# Fields
    linear::LinearDecomposition{T}
    constant::Any

# Constructor
    AffineDecomposition{T}()
    AffineDecomposition{T}(lineardecomposition)
    AffineDecomposition{T}(weights)
    AffineDecomposition{T}(number)
"""
struct AffineDecomposition{T} <: Wrapper{T}
  linear::LinearDecomposition{T}
  constant::Any
end

"Default constructors."
LinearDecomposition{T}() where {T} = LinearDecomposition{T}(Dict{T,Number}())
AffineDecomposition{T}() where {T} = AffineDecomposition{T}(LinearDecomposition{T}(), 0)
AffineDecomposition{T}(x::LinearDecomposition{<:T}) where {T} = AffineDecomposition{T}( LinearDecomposition{T}(x.weights), 0)
AffineDecomposition{T}(weights::Dict{<:T,<:Number}) where {T} = AffineDecomposition{T}( LinearDecomposition{T}(weights), 0)
AffineDecomposition{T}(a::Number) where {T} = AffineDecomposition{T}( LinearDecomposition{T}(), a )

"LinearDecomposition part of a decomposition."
linear(x::LinearDecomposition) = x
linear(x::AffineDecomposition) = x.linear

"Constant part of a decomposition."
constant(x::LinearDecomposition) = error("A linear expression has no constant term.")
constant(x::AffineDecomposition) = x.constant

"Check if a decomposition is empty."
isempty(x::LinearDecomposition) = isempty(x.weights)
isempty(x::AffineDecomposition) = isempty(linear(x)) && iszero(constant(x))

"Weights of the linear part of a decomposition."
weights(x::Union{LinearDecomposition,AffineDecomposition}) = linear(x).weights

# Sum two decompositions
function +(x1::LinearDecomposition{T}, x2::LinearDecomposition{T}) where {T}
  dict = mergewith(+, weights(x1), weights(x2))
  for (key,value) ∈ dict
    if iszero(key) || iszero(value)
      delete!(dict, key)
    end
  end
  LinearDecomposition{T}(dict)
end
+(x1::AffineDecomposition{T}, x2::AffineDecomposition{T}) where {T} = AffineDecomposition{T}( linear(x1) + linear(x2), constant(x1) + constant(x2) )
+(x::AffineDecomposition{T}, a::Number) where {T} = AffineDecomposition{T}( linear(x), constant(x) + a )
+(a::Number, x::AffineDecomposition{T}) where {T} = x + a

# Subtract two decompositions
-(x1::T, x2::T) where {T<:Union{LinearDecomposition,AffineDecomposition}} = x1 + (-x2)

# Scale a decomposition
*(a::Number, x::LinearDecomposition{T}) where {T} = LinearDecomposition{T}( Dict{T,Number}(keys(weights(x)) .=> map(x->a*x, values(weights(x)))) )
*(a::Number, x::AffineDecomposition{T}) where {T} = AffineDecomposition{T}( a*linear(x), a*constant(x) )
*(x::Union{LinearDecomposition,AffineDecomposition}, a::Number) = a*x
/(x::Union{LinearDecomposition,AffineDecomposition}, a::Number) = (1/a)*x

# Negate a decomposition
-(x::Union{LinearDecomposition,AffineDecomposition}) = -1*x

"Variables in a decomposition."
variables(x::Union{LinearDecomposition,AffineDecomposition}) = Set(keys(weights(x)))


############################################################################################
# Oracle wrappers

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

"Generic wrapper for the Hessian of a twice-differentiable functional."
struct Hessian{T<:AbstractTwiceDifferentiableFunctional} <: AbstractDifferential{T}
  parent::T
end

*(a::Number, o::T) where {T<:Oracle} = LinearDecomposition{T}(Dict(o => a))
*(a::Number, o::LinearDecomposition{T}) where {T<:Oracle} = LinearDecomposition{T}(Dict(first(p) => a*last(p) for p ∈ weights(o)))
+(o1::T, o2::T) where {T<:Oracle} = LinearDecomposition{T}(Dict(o1=>1, o2=>1))
+(o1::T, o2::T) where {T<:LinearDecomposition{<:Oracle}} = T(mergewith(+, weights(o1), weights(o2)))
+(o1::T, o2::LinearDecomposition{T}) where {T<:Oracle} = LinearDecomposition{T}(Dict(o1=>1)) + o2
+(o1::LinearDecomposition{T}, o2::T) where {T<:Oracle} = o1 + LinearDecomposition{T}(Dict(o2=>1))


############################################################################################
# Subset

struct Subset{T}
    properties::Properties

    Subset(T) = new{T}(Set{Property{T}}())
end


############################################################################################
# Unwrap

"""
    unwrap(w)

Unwrap a wrapper (get the object that it wraps).
"""
unwrap(x) = x
unwrap(w::W) where {W<:Wrapper{<:Oracle}} = w.parent.associations[Base.typename(W).wrapper]
