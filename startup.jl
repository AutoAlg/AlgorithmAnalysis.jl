using Pkg
Pkg.activate(".")
using Revise
using AlgorithmAnalysis


############################################################################################
# ALGEBRA

add = instance(R).addition
mul = instance(R).multiplication

@algorithm begin
    a ∈ R
    b ∈ R
    c ∈ R
    d = 2a - b + 3c

    x ∈ Rⁿ
    y ∈ Rⁿ
    z = 2x - y

    f ∈ 𝓕{Rⁿ}
    α ∈ R
    x ∈ Rⁿ
    xs ∈ Rⁿ
    y = x - α * f'(x)
    
    performance = (x-xs)^2
end

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