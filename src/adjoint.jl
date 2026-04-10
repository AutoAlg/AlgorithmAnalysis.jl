"""
    adjoint(x)

Adjoint of an oracle, vector, or wrapper of those types.

The adjoint function is used because it is automatically called by the notation `x'`.
The semantics of the adjoint depend on the type of object (and may not correspond to the
standard notion of adjoint).

- For an oracle, the adjoint is used to access its related operators. The related operators
  available depends on the type of oracle.
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

function adjoint(o::Oracle)
    error("Oracle type $(typeof(o)) does not have an associated operator o'. To specify a related operator, specialize `adjoint` for this oracle type.")
end

# adjoint(o::AbstractLinearMap) = Transpose{typeof(o)}(o)
# adjoint(o::Transpose{<:AbstractLinearMap}) = o.parent
# adjoint(o::AbstractSymmetricLinearMap) = o
# adjoint(o::AbstractSkewSymmetricLinearMap) = LinearDecomposition{typeof(o)}(Dict(o => -1))
# adjoint(o::AbstractSubdifferentiableFunctional) = Subdifferential{typeof(o)}(o)
# adjoint(o::AbstractDifferentiableFunctional) = Gradient{typeof(o)}(o)

# function adjoint(o::Gradient{<:AbstractTwiceDifferentiableFunctional})
#     Hessian{typeof(o.parent)}(o.parent)
# end

adjoint(f::SmoothStronglyConvexFunction) = f.associations[Gradient]

function adjoint(x::LinearDecomposition)
    mapreduce( p -> last(p) * first(p)', +, weights(x); init=Zero() )
end

# adjoint(o::Dual{<:InnerProductSpace}) = o.parent
adjoint(::ZeroFunctional{X}) where {X} = X(Zero())
adjoint(a::Field) = a

function adjoint(x::X) where {X<:InnerProductSpace}
    if iszero(x)
        ZeroFunctional{X}()
    elseif isdefined(x, :associations) && haskey(x.associations, Dual)
        x.associations[Dual]
    elseif value(x) isa LinearDecomposition
        mapreduce(p -> last(p) * first(p)', +, weights(value(x)))
    end
end

function adjoint(x::LinearFunctional)
    if isdefined(x, :associations) && haskey(x.associations, DualOf)
        x.associations[DualOf]
    elseif !ismissing(x.value)
        mapreduce(p -> last(p) * first(p)', +, weights(x.value))
    end
end

adjoint(K::Cone) = dual(K)
adjoint(K::Type{<:Cone}) = dual(K)