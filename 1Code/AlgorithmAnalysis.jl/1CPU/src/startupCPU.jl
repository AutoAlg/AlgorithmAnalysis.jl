using Pkg
cd("S:\\Research Material\\CSE\\MU\\Project\\1Code\\AlgorithmAnalysis.jl\\1CPU")
Pkg.activate(".")
using Revise
using AlgorithmAnalysis
using Logging
using DataFrames
using Base.Threads  # Import the threading module

# Ensure the number of threads is set correctly
println("Using ", Threads.nthreads(), " threads.")  # Print the number of threads being used

function runPerformanceTest(threadCount::Int, numberOfIterations::Int, path::String, runIndex::Int)
    # Determine log file path
    logFilePath = "$path\\Run#$runIndex.log"
    # Create directory if it does not exist
    mkpath(dirname(logFilePath))

    # Redirect stdout and stderr to the log file
    open(logFilePath, "w") do logFile
        redirect_stdout(logFile)
        redirect_stderr(logFile)

        # Use a try...catch block to capture all errors
        try
            # Start setup time measurement
            setupTimeStart = time_ns()

            m, l = 1, 10
            α = 2 / (l + m)

            global_logger(ConsoleLogger(stderr, Logging.Info))

            # Start measuring RAM usage before the algorithm
            startRamUsage = Base.summarysize([m, l, α])

            # PERFORMANCE ESTIMATION
            @algorithm begin
                # Objective function
                f  = DifferentiableFunctional{Rⁿ}()
                xs = first_order_stationary_point(f)
                f' ∈ SectorBounded(m, l, xs, f'(xs))

                # Algorithm with n-iterations for gradient descent using multiple threads
                x0 = Rⁿ()
                x1 = x0

                # Parallel loop using Threads.@threads
                Threads.@threads for i in 1:numberOfIterations
                    x1 = x1 - α * f'(x1)  # Perform one step of gradient descent
                end

                # Constraint on initial condition
                (x0 - xs)^2 ≤ 1

                # Performance measure (after the loop is done, get the last iteration value - xs Euclidean)
                performance = (x1 - xs)^2
            end

            # End setup time measurement
            setupTimeEnd = time_ns()

            # Start measuring algorithm performance
            algorithmPerformanceStart = time_ns()

            # Precompile step and optimize
            optimizationTime = maximize(performance)

            # End measuring algorithm performance
            algorithmPerformanceEnd  = time_ns()

            # Measure RAM usage after the algorithm
            endRamUsage  = Base.summarysize([f, xs, x0, x1, performance])

            # Calculate time differences and RAM differences
            totalSetupTime     = (setupTimeEnd - setupTimeStart) / 1e9
            totalAlgorithmTime = (algorithmPerformanceEnd - algorithmPerformanceStart) / 1e9
            totalRamUsage      = (endRamUsage + startRamUsage) / 1e6  # Convert to MB
            threads            = Threads.nthreads()

            # Write results to the log file
            println(logFile, "------ BENCHMARKING RESULTS ------")
            println(logFile, "Setup Time: $totalSetupTime seconds")
            println(logFile, "Algorithm Computation Time: $totalAlgorithmTime seconds")
            println(logFile, "Optimization Time: $optimizationTime seconds")
            println(logFile, "RAM Usage: $totalRamUsage MB")
            println(logFile, "Threads Used: $threads")
            println(logFile, "----- END OF RESULTS -----")

            # Ensure output is immediately flushed
            flush(logFile)

        catch e
            # Write the error message to the log file
            println(logFile, "ERROR: ", e)
            println(logFile, stacktrace(e))  # Print the stack trace
        end

        # Ensure to reset stdout and stderr back to the terminal
        redirect_stdout()
        redirect_stderr()
    end
end

# Function to run multiple times
function runMultipleTests(threadCount::Int, numberOfIterations::Int, path::String, runsPerBatch::Int)
    for runIndex in 0:(runsPerBatch - 1)
        runIndex = runIndex + 1
        runPerformanceTest(threadCount, numberOfIterations, path, runIndex)
    end
end

# Call the function with default values or use the command-line arguments
if length(ARGS) >= 4
    runMultipleTests(parse(Int, ARGS[1]), parse(Int, ARGS[2]), ARGS[3], parse(Int, ARGS[4]))
end
