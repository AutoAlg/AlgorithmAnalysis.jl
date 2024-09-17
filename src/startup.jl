
cd("C:\\Users\\vanscob\\github\\BlackBoxOptimization.jl\\")
using Pkg
Pkg.activate(".")
using Revise
using BlackBoxOptimization
using Logging

m,L = 1,10
α = 2/(L+m)

global_logger(ConsoleLogger(stderr, Logging.Info))


############################################################################################
# PERFORMANCE ESTIMATION

@algorithm begin

    # objective function
    f = DifferentiableFunctional{Rⁿ}()
    xs = first_order_stationary_point(f)
    f' ∈ SectorBounded(m, L, xs, gs)

    # algorithm
    x0 = Rⁿ()
    x1 = x0 - α*f'(x0)

    # constraint on initial condition
    (x0-xs)^2 ≤ 1

    # performance measure
    performance = (x1-xs)^2
end

maximize(performance)
