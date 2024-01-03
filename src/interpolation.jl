export FirstOrder, Operator
export FunctionClass, OperatorClass
export Convex, SmoothStronglyConvex, ConvexIndicator, StronglyConvex, Smooth
export MonotoneOperator, Eigenvalues, Symmetric, SkewSymmetric, CocoerciveOperator, Lipschitz, StronglyMonotoneOperator
export stationary_point, interpolation_conditions, ∞

"Infinity symbol."
const ∞ = Inf


###############################################################################
# Relation classes

abstract type FunctionClass <: RelationClass end
abstract type OperatorClass <: RelationClass end

struct SmoothStronglyConvex{μ,L} <: FunctionClass end
struct Smooth{L} <: FunctionClass end

struct Convex <: FunctionClass end
struct StronglyConvex{μ} <: FunctionClass end

# struct BlockSmoothConvex{L} <: FunctionClass end

struct MonotoneOperator <: FunctionClass end
# struct LinearOperator{L} <: FunctionClass end
struct Symmetric <: FunctionClass end
struct Eigenvalues{μ,L} <: FunctionClass end
struct CocoerciveOperator{β} <: FunctionClass end
struct ConvexIndicatorFunction{D} <: FunctionClass end
struct StronglyMonotoneOperator{μ} <: FunctionClass end
struct SkewSymmetric{L} <: FunctionClass end
struct Nonexpansive{v} <: FunctionClass end
struct NegativelyComonotone{ρ} <: FunctionClass end
struct Lipschitz{L} <: FunctionClass end

# Interpolation conditions not known
# Lipschitz{L} ∩ StronglyMonotoneOperator{μ}
# CocoerciveOperator{β} ∩ StronglyMonotoneOperator{μ}






###############################################################################
# Interpolation conditions
###############################################################################

# one_point_constraint(o::Oracle, f::Function) = Constraints([ f(x) for x ∈ samples(o) ])
# two_point_constraint(o::Oracle, f::Function) = Constraints([ f(x,y) for x ∈ samples(o), y ∈ samples(o) ])

# "Interpolation conditions for an oracle and relation class. Returns a set of constraints."
# function interpolation_conditions end


###############################################################################
# Functions

# function interpolation_conditions(o::FirstOrder, ::Convex)
#   two_point_constraint(o, ((x1,(f1,g1)),(x2,(f2,_))) -> f2 ≥ f1 + g1*(x2-x1) )
# end

"""
  Interpolation conditions for the class of L-smooth and μ-strongly convex functions.
  
  A. Taylor, J. Hendrickx, F. Glineur (2017).
  Exact worst-case performance of first-order methods for composite convex optimization.
  SIAM Journal on Optimization, 27(3):1283–1313.
  <https://arxiv.org/pdf/1512.07516.pdf>
"""
# function interpolation_conditions(o::FirstOrder, ::SmoothStronglyConvex{μ,L}) where {μ,L}
#   two_point_constraint(o, ((x1,(f1,g1)),(x2,(f2,g2))) ->
#     f2-f1-g1*(x2-x1) ≥ 1/(2*(1-μ/L))*(1/L*(g2-g1)^2 + μ*(x2-x1)^2 - 2μ/L*(g2-g1)*(x2-x1)) )
# end

"""
  Interpolation conditions for the class of convex indicator functions.
  
  A. Taylor, J. Hendrickx, F. Glineur (2017).
  Exact worst-case performance of first-order methods for composite convex optimization.
  SIAM Journal on Optimization, 27(3):1283–1313.
  <https://arxiv.org/pdf/1512.07516.pdf>
  Theorem 3.6
"""
# function interpolation_conditions(o::FirstOrder, ::ConvexIndicatorFunction{D}) where {D}
#   one_point_constraint(o, (x,(f,g)) -> f == 0) ∪
#   two_point_constraint(o, ((xi,_),(xj,(_,gj))) -> 0 ≥ gj*(xi-xj)) ∪
#   two_point_constraint(o, ((xi,_),(xj,_)) -> (xi-xj) ≤ D^2)
# end

###############################################################################
# Operators

"""
  Interpolation conditions for the class of linear operators with maximum singular value upper bounded by L.

  N. Bousselmi, J. Hendrickx, F. Glineur (2023).
  Interpolation Conditions for Linear Operators and applications to Performance Estimation Problems.
  arXiv <https://arxiv.org/pdf/2302.08781.pdf>
  Theorem 3.1
"""
# function interpolation_conditions(o::Operator, ::LinearOperator{L}) where {L}
#   X = Vector{Expression{Point}}(o.inputs)
#   Y = Vector{Expression{Point}}(o.outputs)
#   U = Vector{Expression{Point}}(o.adjoint.inputs)
#   V = Vector{Expression{Point}}(o.adjoint.outputs)
#   (X ⊗ V == Y ⊗ U) ∪ Constraints([Y ⊗ Y ⪯ L^2*(X ⊗ X)]) ∪ Constraints([V ⊗ V ⪯ L^2*(U ⊗ U)])
# end

"""
  Interpolation conditions for the class of skew-symmetric linear operators with maximum singular value upper bounded by L.
  
  N. Bousselmi, J. Hendrickx, F. Glineur (2023).
  Interpolation Conditions for Linear Operators and applications to Performance Estimation Problems.
  arXiv <https://arxiv.org/pdf/2302.08781.pdf>
  Corollary 3.2
"""
# function interpolation_conditions(o::Operator, ::SkewSymmetricLinearOperator{L}) where {L}
#   X = Vector{Expression{Point}}(o.inputs)
#   Y = Vector{Expression{Point}}(o.outputs)
#   (X ⊗ Y + Y ⊗ X == 0) ∪ Constraints([Y ⊗ Y ⪯ L^2*(X ⊗ X)])
# end

"""
  Interpolation conditions for the class of symmetric linear operators with eigenvalues in the closed interval [μ,L].

  N. Bousselmi, J. Hendrickx, F. Glineur (2023).
  Interpolation Conditions for Linear Operators and applications to Performance Estimation Problems.
  arXiv <https://arxiv.org/pdf/2302.08781.pdf>
  Theorem 3.3
"""
# function interpolation_conditions(o::Operator, ::SymmetricLinearOperator{μ,L}) where {μ,L}
#   X = Vector{Expression{Point}}(o.inputs)
#   Y = Vector{Expression{Point}}(o.outputs)
#   (X ⊗ Y == Y ⊗ X) ∪ Constraints([(Y-μ*X) ⊗ (L*X-Y) ⪰ 0])
# end

"""
  Interpolation conditions for the class of monotone operators.
  
  H. H. Bauschke and P. L. Combettes (2017).
  Convex Analysis and Monotone Operator Theory in Hilbert Spaces.
  Springer New York, 2nd ed.
  Theorem 20.21
"""
# function interpolation_conditions(o::Operator, ::MonotoneOperator)
#   two_point_constraint(o, ((xi,gi),(xj,gj)) -> (gi-gj)*(xi-xj) ≥ 0)
# end

# function interpolation_conditions(o::Operator, ::CocoerciveOperator{β}) where {β}
#   two_point_constraint(o, ((xi,gi),(xj,gj)) -> (gi-gj)*(xi-xj) ≥ β*(gi-gj)^2)
# end

"""
  Interpolation conditions for the class of strongly monotone operators.
  
  E. Ryu, A. Taylor, C. Bergeling, P. Giselsson (2020).
  Operator splitting performance estimation: Tight contraction factors and optimal parameter selection.
  SIAM Journal on Optimization, 30(3), 2251-2271.
  <https://arxiv.org/pdf/1812.00146.pdf>
  Section 2
"""
# function interpolation_conditions(o::Operator, ::StronglyMonotoneOperator{μ}) where {μ}
#   two_point_constraint(o, ((xi,gi),(xj,gj)) -> (gi-gj)*(xi-xj) ≥ μ*(xi-xj)^2)
# end

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
# function interpolation_conditions(o::Operator, ::Nonexpansive{v}) where {v}
#   two_point_constraint(o, ((xi,gi),(xj,gj)) -> (gi-gj)^2 ≤ (xi-xj)^2) ∪
#   one_point_constraint(o, (x,g) -> v^2 ≤ (xi-gi)*v)
# end

"""
  Interpolation conditions for the class of negatively comonotone operators (may not be sufficient) with comonotonicity parameter ρ > 0.
  
  References:
    E. Gorbunov, A. Taylor, S. Horváth, G. Gidel (2023).
    Convergence of proximal point and extragradient-based methods beyond monotonicity: the case of negative comonotonicity.
    International Conference on Machine Learning.
    <https://proceedings.mlr.press/v202/gorbunov23a/gorbunov23a.pdf>
"""
# function interpolation_conditions(o::Operator, ::NegativelyComonotone{ρ}) where {ρ}
#   two_point_constraint(o, ((xi,gi),(xj,gj)) -> (gi-gj)*(xi-xj) + ρ*(gi-gj)^2 ≥ 0)
# end

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
# function interpolation_conditions(o::Operator, ::Lipschitz{L}) where {L}
#   two_point_constraint(o, ((xi,gi),(xj,gj)) -> (gi-gj)^2 ≤ L^2*(xi-xj)^2)
# end