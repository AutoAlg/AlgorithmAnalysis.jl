"""
    adjoint(x)

Adjoint of an object.

The adjoint function is used because it is automatically called by the notation `x'`.
The semantics of the adjoint depend on the type of object (and may not correspond to the
standard notion of adjoint).

- For an operator, the adjoint is used to access its related operators. The related operators available depend on the type of operator.
    - the adjoint of a linear operator is its transpose
    - the adjoint of a subdifferentiable function is its subdifferential
    - the adjoint of a differentiable function is its gradient
    - the adjoint of the gradient of a twice differentiable function is its Hessian
- For a vector in an inner product space, its adjoint is its dual linear functional that
    evaluates the inner product with the vector. If the vector is a linear function of other
    vectors, then its adjoint is computated as the same linear function of the duals of its variables.

# Examples
```julia-repl
julia> A = SymmetricLinearMap{Rⁿ}();     A ==  A'  # true
julia> B = SkewSymmetricLinearMap{Rⁿ}(); B == -B'  # true
julia> C = LinearMap{Rⁿ,Rᵐ}();           C == C''  # true
julia> f = TwiceDifferentiableFunctional{Rⁿ}();
julia> f'   # gradient of f
julia> f''  # Hessian of f
julia> x = Rⁿ();  x'      # linear functional y ↦ ⟨x,y⟩
julia> y = Rⁿ();  (x+y)'  # linear functional z ↦ ⟨x,z⟩ + ⟨y,z⟩
```
"""
function adjoint end

function adjoint(o::Element)
    error("Objects of type $(typeof(o)) do not have an associated operator o'. To specify a related operator, specialize `adjoint` for this object type.")
end

# adjoint(o::AbstractLinearMap) = Transpose{typeof(o)}(o)
# adjoint(o::Transpose{<:AbstractLinearMap}) = o.parent
# adjoint(o::AbstractSymmetricLinearMap) = o
# adjoint(o::AbstractSkewSymmetricLinearMap) = Negation{typeof(o)}(o)
# adjoint(o::AbstractSubdifferentiableFunctional) = Subdifferential{typeof(o)}(o)
# adjoint(o::AbstractDifferentiableFunctional) = associations(o)[Gradient]

# function adjoint(o::Gradient{<:AbstractTwiceDifferentiableFunctional})
#     Hessian{typeof(o.parent)}(o.parent)
# end

adjoint(x::Element{<:Functional}) = instance(space(x)).gradient
adjoint(x::Element{<:Field}) = x
adjoint(x::Element{<:VectorSpace}) = instance(space(x)).dual(x)

# adjoint(x::Zero) = Zero{LinearFunctional{space(x)}}()

# dual cones
# adjoint(::Type{PositiveSemidefiniteCone}) = PositiveSemidefiniteCone
# adjoint(::Type{PositiveOrthant}) = PositiveOrthant
# adjoint(::Type{ZeroSet}) = Any

# dual space
# adjoint(::Type{T}) where {T} = LinearFunctional{T}
adjoint(::Type{<:LinearFunctional{X}}) where X = X
adjoint(::Type{T}) where {T<:Field} = T
adjoint(::Type{T}) where {T<:VectorSpace} = LinearFunctional{T}

