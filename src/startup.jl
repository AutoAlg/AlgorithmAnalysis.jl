
cd("your-path-here\\AlgorithmAnalysis.jl\\")
using Pkg
Pkg.activate(".")
using Revise
using AlgorithmAnalysis
using Logging

m,L = 1,10
α = 2/(L+m)
ρ = (L-m)/(L+m)
n = 3

global_logger(ConsoleLogger(stderr, Logging.Info))


############################################################################################
# PERFORMANCE ESTIMATION

@algorithm begin

    # objective function
    f = DifferentiableFunctional{Rⁿ}()
    xs = first_order_stationary_point(f)
    f' ∈ SectorBounded(m, L, xs, f'(xs))

    # iterates
    x = Vector{Rⁿ}(undef, n+1)

    # initial condition
    x[1] = Rⁿ()

    # constraint on initial condition
    # (scale so that the maximum performance should be one to avoid numerical issues)
    (x[1]-xs)^2 ≤ ρ^(-2n)

    # algorithm
    for k = 1:n
        x[k+1] = x[k] - α*f'(x[k])
    end

    # performance measure
    performance = (x[end]-xs)^2
end

maximize(performance)
