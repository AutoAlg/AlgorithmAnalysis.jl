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

adjoint(o::Oracle) = error("Oracle $o does not have an associated operator o'. To specify a related operator, specialize `adjoint` for this oracle type.")
adjoint(o::AbstractDifferential) = error("Differential $o does not have an associated operator o'. To specify a related operator, specialize `adjoint' for this differential type.")
adjoint(o::AbstractLinearMap) = Transpose{typeof(o)}(o)
adjoint(o::Transpose{<:AbstractLinearMap}) = o.parent
adjoint(o::AbstractSymmetricLinearMap) = o
adjoint(o::AbstractSkewSymmetricLinearMap) = LinearDecomposition{typeof(o)}(Dict(o => -1))
adjoint(o::AbstractSubdifferentiableFunctional) = Subdifferential{typeof(o)}(o)
adjoint(o::AbstractDifferentiableFunctional) = Gradient{typeof(o)}(o)
adjoint(o::Gradient{<:AbstractTwiceDifferentiableFunctional}) = Hessian{typeof(o.parent)}(o.parent)
adjoint(o::LinearDecomposition{<:Oracle}) = mapreduce( p -> last(p) * first(p)', +, weights(o) )
adjoint(o::AbstractLinearFunctional) = o.dual
adjoint(x::X) where {X<:InnerProductSpace} = isvariable(x) ? x.dual : mapreduce( p -> p.second * p.first', +, weights(decomposition(x)) )
adjoint(a::F) where {F<:Field} = a
adjoint(G::GramMatrix) = G
