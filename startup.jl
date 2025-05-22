using Pkg
Pkg.activate(".")
using Revise
using AlgorithmAnalysis

@set A, B, C

# I = A ∩ B
# U = A ∪ B
F = A → B
G = A ⇒ B
D = A × B

@var a ∈ A, b ∈ B, c ∈ C, f ∈ F, g ∈ G, h ∈ F, d ∈ D, z ∈ graph(g)

fa = f(a)
ga = g(a)

f ∈ Differentiable{A,B}()
h ∈ Convex{A,B}()




# # Declare a symbolic convex function f: ℝ → ℝ
# @symbolic f::ConvexFunction{X → Y}, g::ConvexFunction{X → Y}

# # Sample the function at a point
# fx = f(x)
# gx = g(x)

# # Build a composite expression h = f + 2g
# h = f + 2 * g
# hx = h(x)

# # Compose functions: k = f ∘ g
# k = f ∘ g
# kx = k(x)

# # Show results
# println("f(x) = $fx")
# println("g(x) = $gx")
# println("h(x) = $hx")
# println("k(x) = $kx")

# # Add assumptions
# @assume f ∈ ConvexFunctions
# @assume g ∈ ConvexFunctions

# println("Assumptions on f: ", assumptions(f))
# println("Assumptions on g: ", assumptions(g))

# # Check assumption
# println("Is f convex? ", has_assumption(f, ConvexFunctions))




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