export FunctionClass, OperatorClass
export Convex, Curvature, ConvexIndicator, StronglyConvex, Smooth, QuadraticGrowth
export LinearOperator, Monotone, Symmetric, Eigenvalues, SkewSymmetric, Cocoercive, Lipschitz
export StronglyMonotone, MaxSingularValue
export interpolation_conditions, triplets, Triplets


###############################################################################
# Relation classes

abstract type FunctionClass <: RelationClass end
abstract type OperatorClass <: RelationClass end

# function class primitives
struct Curvature{μ,L} <: FunctionClass end
# struct Smooth{L} <: FunctionClass end
# struct Convex <: FunctionClass end
# struct StronglyConvex{μ} <: FunctionClass end
# struct ConvexIndicator{D} <: FunctionClass end
struct QuadraticGrowth{μ} <: FunctionClass end
struct ZeroFunction <: FunctionClass end

# struct BlockSmoothConvex{L} <: FunctionClass end

# operator class primitives
struct LinearOperator <: OperatorClass end
struct Monotone <: OperatorClass end
struct Symmetric <: OperatorClass end
struct Eigenvalues{μ,L} <: OperatorClass end
struct MaxSingularValue{L} <: OperatorClass end
struct SkewSymmetric <: OperatorClass end
struct Cocoercive{β} <: OperatorClass end
struct StronglyMonotone{μ} <: OperatorClass end
struct Nonexpansive{v} <: OperatorClass end
struct NegativelyComonotone{ρ} <: OperatorClass end
struct Lipschitz{L} <: RelationClass end

# relation class primitives
struct ZeroImage <: RelationClass end
struct ZeroPreimage <: RelationClass end


# Interpolation conditions not known
# Lipschitz{L} ∩ StronglyMonotoneOperator{μ}
# CocoerciveOperator{β} ∩ StronglyMonotoneOperator{μ}


###############################################################################
# Interpolation conditions
###############################################################################

const Triplets{X,F} = Set{Tuple{X,F,X}}

triplets(o::DifferentiableFunction) = Set( (x,o(x),o'(x)) for x ∈ preimage(o,o') )

function triplets(o::ConvexFunction)
  p = samples(o)
  d = samples(o')
  
  (x,o(x),evalute(o',x))
end

one_point_constraint(o::Oracle, f::Function) = prune(Constraints( f(x) for x ∈ samples(o) ))
two_point_constraint(o::Oracle, f::Function) = prune(Constraints( f(x,y) for x ∈ samples(o), y ∈ samples(o) ))

one_point_constraint(o::Functional, f::Function) = prune(Constraints( f(x) for x ∈ triplets(o) ))
two_point_constraint(o::Functional, f::Function) = prune(Constraints( f(x,y) for x ∈ triplets(o), y ∈ triplets(o) ))

"Interpolation conditions for an oracle and relation class. Returns a set of constraints."
function interpolation_conditions end


"All interpolation conditions for an oracle."
interpolation_conditions(o::Oracle) = mapreduce(fc -> interpolation_conditions(o,fc), ∪, classes(r); init=Constraints())




###############################################################################
# Functions

# Relation = Set{<:Tuple}

# function interpolation_conditions(o::Functional, ::Convex)
#   two_point_constraint(o, ((x1,f1,g1),(x2,f2,_)) -> f2 ≥ f1 + g1*(x2-x1) )
# end

"""
  Interpolation conditions for the class of L-smooth and μ-strongly convex functions.
  
  A. Taylor, J. Hendrickx, F. Glineur (2017).
  Exact worst-case performance of first-order methods for composite convex optimization.
  SIAM Journal on Optimization, 27(3):1283–1313.
  <https://arxiv.org/pdf/1512.07516.pdf>
"""
function interpolation_conditions(o::Functional, ::Curvature{μ,L}) where {μ,L}
  two_point_constraint(o, ((x1,f1,g1),(x2,f2,g2)) ->
    f2-f1-g1*(x2-x1) ≥ 1/(2*(1-μ/L))*(1/L*(g2-g1)^2 + μ*(x2-x1)^2 - 2μ/L*(g2-g1)*(x2-x1)) )
end

"""
  Interpolation conditions for the class of convex indicator functions.
  
  A. Taylor, J. Hendrickx, F. Glineur (2017).
  Exact worst-case performance of first-order methods for composite convex optimization.
  SIAM Journal on Optimization, 27(3):1283–1313.
  <https://arxiv.org/pdf/1512.07516.pdf>
  Theorem 3.6
"""
function interpolation_conditions(o::Functional, ::ConvexIndicator{D}) where {D}
  interpolation_conditions(o, Convex()) ∪
  interpolation_conditions(o, ZeroFunction()) ∪
  interpolation_conditions(o, BoundedDomain{D}())
end

"""
  Interpolation conditions for the class of functions that are zero on the domain.
"""
function interpolation_conditions(o::Functional, ::ZeroFunction)
  Constraints( f == 0 for f ∈ image(o) )
end

"""
  Interpolation conditions for the class of functions with bounded domain.
"""
function interpolation_conditions(o::Functional, ::BoundedDomain{D}) where {D}
  Constraints( (xi-xj)^2 ≤ D^2 for xi ∈ preimage(o,o'), xj ∈ preimage(o,o') )
end

"""
  Interpolation conditions for the class of functions with quadratic growth.
  
  References:
    B. Goujaud, A. Taylor, A. Dieuleveut (2022).
    Optimal first-order methods for convex functions with a quadratic upper bound.
    <https://arxiv.org/pdf/2205.15033.pdf>
    Theorem 2.6
"""
function interpolation_conditions(o::Functional, ::QuadraticGrowth{L}) where {L}
  two_point_constraint(o, ((xi,fi,gi),(xj,fj,gj)) -> fi-fj ≥ (xi-xj) ⋅ gj + 1/(2L)*gj^2)
end


###############################################################################
# Operators

"""
  Interpolation conditions for the class of linear operators.
"""
function interpolation_conditions(X::𝐗, Y::𝐘, U::𝐔, V::𝐕, ::Linear) where {𝐗,𝐘,𝐔,𝐕}
  # X = Vector{𝐗}(inputs(o))
  # Y = Vector{𝐘}(outputs(o))
  # U = Vector{𝐘}(inputs(o'))
  # V = Vector{𝐗}(outputs(o'))
  # Constraints( x ⋅ v == y ⋅ u for (x,y) ∈ o, (u,v) ∈ o' )
  if 𝐗 ≠ 𝐕 || 𝐘 ≠ 𝐔
    error("Spaces inconsistent for a linear operator.")
  end
  Constraints( X ⊗ V == Y ⊗ U )
end

"""
  Interpolation conditions for the class of symmetric linear operators.
"""
function interpolation_conditions(X::𝐗, Y::𝐘, U::𝐔, V::𝐕, ::Symmetric) where {𝐗,𝐘,𝐔,𝐕}
  if 𝐗 ≠ 𝐘 || 𝐗 ≠ 𝐔 || 𝐗 ≠ 𝐕
    error("Spaces inconsistent for a symmetric linear operator.")
  end
  Constraints( [X; U] ⊗ [Y; V] == [Y; V] ⊗ [X; U] )
  # Constraints( xi ⋅ yj == yi ⋅ xj for (xi,yi) ∈ o, (xj,yj) ∈ o )
end

"""
  Interpolation conditions for the class of skew-symmetric linear operators.
"""
function interpolation_conditions(X::𝐗, Y::𝐘, U::𝐔, V::𝐕, ::SkewSymmetric) where {𝐗,𝐘,𝐔,𝐕}
  if 𝐗 ≠ 𝐘 || 𝐗 ≠ 𝐔 || 𝐗 ≠ 𝐕
    error("Spaces inconsistent for a skew-symmetric linear operator.")
  end
  Constraints( [X; U] ⊗ [Y; V] + [Y; V] ⊗ [X; U] == 0 )
  # Constraints( xi ⋅ yj + xj ⋅ yi == 0 for (xi,yi) ∈ o, (xj,yj) ∈ o )
end

"""
  Interpolation conditions for the class of linear operators with maximum singular value upper bounded by L.

  N. Bousselmi, J. Hendrickx, F. Glineur (2023).
  Interpolation Conditions for Linear Operators and applications to Performance Estimation Problems.
  arXiv <https://arxiv.org/pdf/2302.08781.pdf>
  Theorem 3.1
"""
function interpolation_conditions(X::𝐗, Y::𝐘, U::𝐔, V::𝐕, ::MaxSingularValue{L})  where {𝐗,𝐘,𝐔,𝐕,L}
  if Linear() ∉ classes(o)
    error("Only linear operators have singular values.")
  end
  Constraints( Y ⊗ Y ⪯ L^2*(X ⊗ X) ) ∪ Constraints( V ⊗ V ⪯ L^2*(U ⊗ U) )
end

"""
  Interpolation conditions for the class of skew-symmetric linear operators with maximum singular value upper bounded by L.
  
  N. Bousselmi, J. Hendrickx, F. Glineur (2023).
  Interpolation Conditions for Linear Operators and applications to Performance Estimation Problems.
  arXiv <https://arxiv.org/pdf/2302.08781.pdf>
  Corollary 3.2
"""
function interpolation_conditions(o::Oracle, ::MaxSingularValue{L}) where {L}
  X = Vector{Expression{Point}}(o.inputs)
  Y = Vector{Expression{Point}}(o.outputs)
  (X ⊗ Y + Y ⊗ X == 0) ∪ Constraints([Y ⊗ Y ⪯ L^2*(X ⊗ X)])
end



"""
  Interpolation conditions for the class of symmetric linear operators with eigenvalues in the closed interval [μ,L].

  N. Bousselmi, J. Hendrickx, F. Glineur (2023).
  Interpolation Conditions for Linear Operators and applications to Performance Estimation Problems.
  arXiv <https://arxiv.org/pdf/2302.08781.pdf>
  Theorem 3.3
"""
function interpolation_conditions(o::LinearOperator, ::Eigenvalues{μ,L}) where {μ,L}
  X = Vector{Expression{Point}}(o.inputs)
  Y = Vector{Expression{Point}}(o.outputs)
  (X ⊗ Y == Y ⊗ X) ∪ Constraints([(Y-μ*X) ⊗ (L*X-Y) ⪰ 0])
end

"""
  Interpolation conditions for the class of monotone operators.
  
  H. H. Bauschke and P. L. Combettes (2017).
  Convex Analysis and Monotone Operator Theory in Hilbert Spaces.
  Springer New York, 2nd ed.
  Theorem 20.21
"""
function interpolation_conditions(o::Oracle, ::Monotone)
  two_point_constraint(o, ((xi,gi),(xj,gj)) -> (gi-gj)*(xi-xj) ≥ 0)
end

function interpolation_conditions(o::Oracle, ::Cocoercive{β}) where {β}
  two_point_constraint(o, ((xi,gi),(xj,gj)) -> (gi-gj)*(xi-xj) ≥ β*(gi-gj)^2)
end

"""
  Interpolation conditions for the class of strongly monotone operators.
  
  E. Ryu, A. Taylor, C. Bergeling, P. Giselsson (2020).
  Operator splitting performance estimation: Tight contraction factors and optimal parameter selection.
  SIAM Journal on Optimization, 30(3), 2251-2271.
  <https://arxiv.org/pdf/1812.00146.pdf>
  Section 2
"""
function interpolation_conditions(o::Oracle, ::StronglyMonotone{μ}) where {μ}
  two_point_constraint(o, ((xi,gi),(xj,gj)) -> (gi-gj)*(xi-xj) ≥ μ*(xi-xj)^2)
end

"""
  Interpolation conditions for the class of nonexpansive operators.
  
  Each nonexpansive operator has a unique vector called the `infimal displacement vector`, which we denote by v.
  
  If a nonexpansive operator is consistent, i.e., has a fixed point, then v=0.

  If v is nonzero, a nonexpansive operator is inconsistent, i.e., does not have a fixed point.

  References:
    E. Ryu, A. Taylor, C. Bergeling, P. Giselsson (2020).
    Operator splitting performance estimation: Tight contraction factors and optimal parameter selection.
    SIAM Journal on Optimization, 30(3), 2251-2271.
    <https://arxiv.org/pdf/1812.00146.pdf>

    J. Park, E. Ryu (2023).
    Accelerated Infeasibility Detection of Constrained Optimization and Fixed-Point Iterations.
    arXiv preprint:2303.15876.
    <https://arxiv.org/pdf/2303.15876.pdf>
"""
function interpolation_conditions(o::Oracle, ::Nonexpansive{v}) where {v}
  two_point_constraint(o, ((xi,gi),(xj,gj)) -> (gi-gj)^2 ≤ (xi-xj)^2) ∪
  one_point_constraint(o, (x,g) -> v^2 ≤ (xi-gi)*v)
end

"""
  Interpolation conditions for the class of negatively comonotone operators (may not be sufficient) with comonotonicity parameter ρ > 0.
  
  References:
    E. Gorbunov, A. Taylor, S. Horváth, G. Gidel (2023).
    Convergence of proximal point and extragradient-based methods beyond monotonicity: the case of negative comonotonicity.
    International Conference on Machine Learning.
    <https://proceedings.mlr.press/v202/gorbunov23a/gorbunov23a.pdf>
"""
function interpolation_conditions(o::Oracle, ::NegativelyComonotone{ρ}) where {ρ}
  two_point_constraint(o, ((xi,gi),(xj,gj)) -> (gi-gj)*(xi-xj) + ρ*(gi-gj)^2 ≥ 0)
end

"""
  Interpolation conditions for the class of Lipschitz operators.
  
  References:
  [1] M. Kirszbraun (1934).
  Uber die zusammenziehende und Lipschitzsche transformationen.
  Fundamenta Mathematicae, 22 (1934).

  [2] F.A. Valentine (1943).
  On the extension of a vector function so as to preserve a Lipschitz condition.
  Bulletin of the American Mathematical Society, 49 (2).

  [3] F.A. Valentine (1945).
  A Lipschitz condition preserving extension for a vector function.
  American Journal of Mathematics, 67(1).

  Discussions and appropriate pointers for the interpolation problem can be found in:
  [4] E. Ryu, A. Taylor, C. Bergeling, P. Giselsson (2020).
  Operator splitting performance estimation: Tight contraction factors and optimal parameter selection.
  SIAM Journal on Optimization, 30(3), 2251-2271.
  <https://arxiv.org/pdf/1812.00146.pdf>
"""
function interpolation_conditions(o::Oracle, ::Lipschitz{L}) where {L}
  two_point_constraint(o, ((xi,gi),(xj,gj)) -> (gi-gj)^2 ≤ L^2*(xi-xj)^2)
end
