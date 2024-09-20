# Set the directory where all packages are stored
cd("S:\\Research Material\\CSE\\MU\\Project\\1Code\\AlgorithmAnalysis.jl\\1CPU")
using Pkg
Pkg.activate(".")
using Revise
using AlgorithmAnalysis
using Logging
using DataFrames
using CUDA  # Import CUDA for GPU support

# Function to run performance test and calculate relevant metrics on GPU
function runPerformanceTestGPU()
    # Start setup time measurement
    setupTimeStart = time_ns()

    # Initialize variables and move them to the GPU
    m = 1.0f0  # Use Float32 for GPU compatibility
    l = 10.0f0
    α = 2.0f0 / (l + m)

    # Move initial variables to the GPU
    m_gpu = CUDA.fill(m, 1)   # Create a scalar array on the GPU
    l_gpu = CUDA.fill(l, 1)
    α_gpu = CUDA.fill(α, 1)

    # GPU-compatible data structures
    global_logger(ConsoleLogger(stderr, Logging.Info))

    # Measure RAM usage before GPU computations
    startRamUsage = CUDA.memory_status().used / 1e6  # Measure initial GPU memory usage

    # Performance Estimation on the GPU
    @cuda function computePerformance(m_gpu, l_gpu, α_gpu)
        # Objective function - GPU compatible operations
        f_gpu  = DifferentiableFunctional{Rⁿ}()
        xs_gpu = first_order_stationary_point(f_gpu)
        f_gpu' ∈ SectorBounded(m_gpu, l_gpu, xs_gpu, f_gpu'(xs_gpu))

        # Algorithm - GPU computations
        x0_gpu = Rⁿ()
        x1_gpu = x0_gpu - α_gpu * f_gpu'(x0_gpu)

        # Constraint on initial condition
        (x0_gpu - xs_gpu)^2 ≤ 1

        # Performance measure
        return (x1_gpu - xs_gpu)^2
    end

    # Call the GPU function
    performance_gpu = computePerformance(m_gpu, l_gpu, α_gpu)

    # End setup time measurement
    setupTimeEnd = time_ns()

    # Start measuring algorithm performance
    algorithmPerformanceStart = time_ns()

    # Optimize on GPU
    maximize(performance_gpu)

    # End measuring algorithm performance
    algorithmPerformanceEnd = time_ns()

    # Measure RAM usage after the algorithm
    endRamUsage = CUDA.memory_status().used / 1e6  # Measure GPU memory usage after computation

    # Calculating time differences and RAM differences
    totalSetupTime     = (setupTimeEnd - setupTimeStart) / 1e9
    totalAlgorithmTime = (algorithmPerformanceEnd - algorithmPerformanceStart) / 1e9
    totalRamUsage      = endRamUsage - startRamUsage
    threads            = Threads.nthreads()

    # Output results
    println("Setup Time: $totalSetupTime seconds")
    println("Algorithm Computation Time: $totalAlgorithmTime seconds")
    println("RAM Usage: $totalRamUsage MB")
    println("Threads Used: $threads")
end

# Run the performance test on GPU
runPerformanceTestGPU()
