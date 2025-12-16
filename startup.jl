using Pkg
Pkg.activate(".")
using Revise
using AlgorithmAnalysis

# @set A, B, C

# @var a ∈ A, b ∈ B, c ∈ C

# I = A ∩ B
# U = A ∪ B
# F = A → B
# G = A ⇒ B
# D = A × B

# @var f ∈ F, g ∈ G, h ∈ F, d ∈ D, z ∈ graph(g)

# fa = f(a)
# ga = g(a)

# f ∈ Differentiable{A,B}()
# h ∈ Convex{A,B}()

@set M
M ∈ Magma{M}(:+)
@var m ∈ M, n ∈ M

@set G
G ∈ Group{G}(:⋅, Symbol("1"))
@var g1 ∈ G, g2 ∈ G

# Reals
@set R
R ∈ Ring{R}()
@implementation(R, Real)
@var x ∈ R, y ∈ R, m ∈ R, L ∈ R
@var α = 2/(L+m)

@set V
V ∈ VectorSpace{V,R}()
@var x0 ∈ V, x1 ∈ V
@var f : V → R
f ∈ Differentiable{V,R}()
@var g0 = f'(x0)
@var Δ = α ⋅ g0
@var x1 = x0 - Δ

# @var a ∈ R, b ∈ R, u ∈ Rⁿ, v ∈ Rⁿ, f : Rⁿ → R, g : Rⁿ → R


############################################################################################
# PERFORMANCE ESTIMATION
@set Rⁿ
Rⁿ ∈ InnerProductSpace{Rⁿ,R}()
@var f : Rⁿ → R, x₀ ∈ Rⁿ, xₒₚₜ ∈ Rⁿ
f ∈ Convex{Rⁿ,R}()
f'(xₒₚₜ) == zero(innerproductspace(Rⁿ))
(x₀ - xₒₚₜ)^2 ≤ 1
x₁ = x₀ - 0.2 * f'(x₀)
performance = (x₁ - xₒₚₜ)^2
# maximize(performance)

# @var f ∈ ℱ{m,L,Rⁿ}

;
# f ∘ g + 2h



############################################################################################
# ALGEBRA

# add = instance(R).addition
# mul = instance(R).multiplication

# ℱ = Rⁿ → R, Differentiable
# ℒ = ℱ, Linear
# @let f ∈ ℱ
# @let g ∈ ℒ

# h = f + g

# R² = R × R

# @set S
# @set T

# @algorithm begin
#     F = S → T
#     R = S × T
#     a ∈ S
#     b ∈ S
#     c ∈ T
# #     p ∈ S × T
# end

# @algorithm begin
#     F = R² → R
#     f ∈ F
#     a ∈ R
#     b ∈ R
#     c ∈ R
#     d = a * b + c

#     # x ∈ Rⁿ
#     # y ∈ Rⁿ
#     # z = 2x - y

#     # f ∈ 𝓕{Rⁿ}
#     # α ∈ R
#     # x ∈ Rⁿ
#     # xs ∈ Rⁿ
#     # y = x - α * f'(x)
    
#     # performance = (x-xs)^2
# end

# nodes(a)

# vars = filter(x -> isa(x, Element{R}) && !hasvalue(x), nodes(a))


############################################################################################
# PERFORMANCE ESTIMATION

# @algorithm begin

#     # objective function
#     f = DifferentiableFunctional{Rⁿ}()
#     xs = first_order_stationary_point(f)
#     f' ∈ SectorBounded(m, L, xs, f'(xs))

#     # iterates
#     x = Vector{Rⁿ}(undef, n+1)

#     # initial condition
#     x[1] = Rⁿ()

#     # constraint on initial condition
#     # (scale so that the maximum performance should be one to avoid numerical issues)
#     (x[1]-xs)^2 ≤ ρ^(-2n)

#     # algorithm
#     for k = 1:n
#         x[k+1] = x[k] - α*f'(x[k])
#     end

#     # performance measure
#     performance = (x[end]-xs)^2
# end

# maximize(performance)