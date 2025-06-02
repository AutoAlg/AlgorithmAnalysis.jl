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

adjoint(x::Object) = error("Objects of type $(typeof(x)) do not have an associated operator x'. To specify a related operator, specialize `adjoint` for this object type.")

function adjoint(x::Object{SingleValuedMap{X,Y}}) where {X,Y}
    if !ismissing(get(x, Differentiable))
        gradient(x)
    elseif !ismissing(get(x, Convex))
        subdifferential(x)
    elseif !ismissing(get(x, LocallyLipschitz))
        clark_subdifferential(x)
    elseif !ismissing(get(x, SelfAdjoint))
        x
    else
        error("Adjoint not implemented")
    end
end

adjoint(A::Object{T}) where {T<:AbstractLinearMap} = get!(T().adjoint, A) do
    Aᵀ = Atom{T'}(Symbol(label(A), "ᵀ"))
    get!(T'().adjoint, Aᵀ) do
        A
    end
    Aᵀ
end
adjoint(A::Object{<:AbstractSymmetricLinearMap}) = A
adjoint(A::Object{<:AbstractSkewSymmetricLinearMap}) = -A

# function adjoint(o::Gradient{<:AbstractTwiceDifferentiableFunctional})
#     Hessian{typeof(o.parent)}(o.parent)
# end

# adjoint(::Functional, x::Object) = instance(space(x)).gradient(x)
# adjoint(::Field, x::Object) = x
# adjoint(::VectorSpace, x::Object) = instance(space(x)).dual(x)

# adjoint(x::Zero) = Zero{LinearFunctional{space(x)}}()

# dual cones
# adjoint(::Type{PositiveSemidefiniteCone}) = PositiveSemidefiniteCone
# adjoint(::Type{PositiveOrthant}) = PositiveOrthant
# adjoint(::Type{ZeroSet}) = Any

# dual space
# adjoint(::Type{T}) where {T<:VectorSpace} = LinearFunctional{T}
# adjoint(::Type{<:LinearFunctional{X}}) where X = X
# adjoint(::Type{T}) where {T<:Field} = T

adjoint(::Type{LinearMap{X,Y}}) where {X,Y} = LinearMap{Y,X}