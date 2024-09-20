cd("S:\\Research Material\\CSE\\MU\\Project\\AlgorithmAnalysis.jl")
using Pkg
Pkg.activate(".")
using Revise
using AlgorithmAnalysis
using Logging

# Start setup time measurement
global_setup_start = time_ns()

m, L = 1, 10
α    = 2 / (L + m)

global_logger(ConsoleLogger(stderr, Logging.Info))

# End setup time measurement
setup_end = time_ns()

# Start measuring RAM usage before the algorithm
start_ram_usage = Base.summarysize( [m, L, α] )  # Adjusted to measure relevant objects
# PERFORMANCE ESTIMATION


@algorithm begin
    # Objective function
    f  = DifferentiableFunctional{Rⁿ}()
    xs = first_order_stationary_point(f)
    f' ∈ SectorBounded(m, L, xs, f'(xs))

    # Algorithm
    x0 = Rⁿ()
    x1 = x0 - α * f'(x0)

    # Constraint on initial condition
    (x0 - xs)^2 ≤ 1

    # Performance measure
    performance = (x1 - xs)^2
end
algorithm_start = time_ns()

maximize(performance)

algorithm_end  = time_ns()

# Measure RAM usage after the algorithm
end_ram_usage  = Base.summarysize( [f, xs, x0, x1, performance] )  # Adjust to measure relevant objects

# Convert nanoseconds to seconds
setup_time     = (setup_end - global_setup_start) / 1e9
algorithm_time = (algorithm_end - algorithm_start) / 1e9
ram_usage      = (end_ram_usage - start_ram_usage) / 1e6  # Convert to MB

println("Setup Time: $setup_time seconds")
println("Algorithm Computation Time: $algorithm_time seconds")
println("RAM Usage: $ram_usage MB")
