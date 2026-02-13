using Plots
using Random
using Measures

Random.seed!("myseed")

# ENV["GKS_FONTPATH"] = "/graphics/_code/cmu-serif"

# for i in 1:50
#     plt = plot(rand(10), title = "Font $i", titlefont = font(i, 20))
#     display(plt)  # or display() / savefig
#     sleep(0.5)
# end

# using PGFPlotsX
# pgfplotsx()

# PGFPlotsX.CUSTOM_PREAMBLE[] = raw"""
# \pgfplotsset{axis background/.style={fill=none}}
# """

# Parameters
n = 50                   # number of iterations
N = 500                  # number of trajectories
x0_range = (-2.0, 2.0)   # random initial points
a_range = (0.5, 8.0)     # random quadratic coefficients (strongly convex)
L = a_range[2]           # Lipschitz constant of gradient
η = 1 / L                # step size

iters = 0:n-1

# Theoretical exponential bound: worst-case rate
ρ = 1 - η * a_range[1]   # slowest possible contraction rate
bound = [abs(x0_range[2]) * ρ^k for k in iters]

# Start plot
plt = plot()

# Plot N trajectories from gradient descent on random quadratics
for i in 1:N
    a = rand() * (a_range[2] - a_range[1]) + a_range[1]
    x = rand() * (x0_range[2] - x0_range[1]) + x0_range[1]
    xs = Float64[]               # to store errors

    for k in 1:n
        push!(xs, abs(x))        # error = distance from minimizer (0)
        x = x - η * a * x        # GD update
    end

    plot!(plt, iters, xs, lw=1, color=:black, alpha=0.1)
end

# Plot the theoretical exponential bound
plot!(plt, iters, bound, lw=8, color=:orange, linestyle=:dash)

# Remove ticks, labels, and legend
plot!(plt,
    xticks = false,
    yticks = false,
    xlabel = "iteration",
    ylabel = "error",
    legend = false,
    title = "",
    size = (600, 250),
    left_margin = 5mm,
    bottom_margin = 3mm,
    guidefont = font(18),
    background_color = :transparent,
    foreground_color = :transparent,
    # grid = false,
)

display(plt)
savefig(plt, "graphics/_code/plot.pdf")
