using Pkg
Pkg.activate(".")
using Revise
using AlgorithmAnalysis
# using Logging
# using Plots
# import JuMP
# import SCS
# using LiveServer
using MosekTools


# TM
function TM(m, L, ρmin=0)
    κ = L/m
    ρ = 1 - 1/(sqrt(κ))
    α = (1 + ρ)/L
    β = ρ^2/(2-ρ)
    γ = ρ^2/((1+ρ)*(2-ρ))
    δ = ρ^2/(1-ρ^2)

    @algorithm begin
        f = DifferentiableFunctional{Rⁿ}()
        xs = first_order_stationary_point(f)
        f ∈ SmoothStronglyConvex(m, L)
        x0 = Rⁿ()
        x1 = Rⁿ()
        y1 = (1+γ)*x1 - γ*x0
        x2 = (1+β)*x1 - β*x0 - α*f'(y1)
        y2 = (1+γ)*x2 - γ*x1
        x0 => x1
        x1 => x2
        performance = ((1+δ)*x2 - δ*x1 -xs)^2
    end
    return rate(performance, ρmin)
end

# HB
function HB(m, L, ρmin=0)
    κ = L/m
    α = 4/((√L + √m)^2)
    β = ((sqrt(L/m)-1)/(sqrt(L/m)+1))^2
    @algorithm begin
        f = DifferentiableFunctional{Rⁿ}()
        xs = first_order_stationary_point(f)
        f ∈ SmoothStronglyConvex(m, L)
        x0 = Rⁿ()
        x1 = Rⁿ()
        x2 = x1 - α*f'(x1) + β*(x1-x0)
        x3 = x2 - α*f'(x2) + β*(x2-x1)
        x4 = x3 - α*f'(x3) + β*(x3-x2)
        x0 => x1
        x1 => x2
        x2 => x3
        x3 => x4
        performance = (x1-xs)^2
    end
    # certify(performance, 0.9)
    # maximize(performance)
    return rate(performance, ρmin)

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


# m = 1
# L_sampled = exp10.(range(log10(1), log10(100), length=12))
# condition_numbers_sampled = L_sampled ./ m
# prev_rate = 0 # Remembers the last returned rate
# results = []
# for L in L_sampled
#     length(results) == 0 ? prev_rate = 0 : prev_rate = results[end]
#     push!(results, TMM(m, L, prev_rate))
# end
# tick_positions = (union(collect(1:10), collect(10:10:100)))
# tick_labels = Dict(1 => L"10^0", 10 => L"10^1", 100 => L"10^2")
# formatted_labels = [get(tick_labels, x, "") for x in tick_positions]
# font_spec = font("Computer Modern", 12)
# plt = scatter(condition_numbers_sampled, results,
#     xscale=:log10,
#     xlabel="Condition Number (L/m)",
#     ylabel="Convergence rate",
#     label="TMM(m,L)",
#     markersize=5,
#     xticks=(tick_positions, formatted_labels),
#     ylim = (0, 1),
#     xlim = (nothing, 110),
#     guidefont = font_spec,     # Axis labels
#     tickfont = font_spec,      # Tick labels
#     legendfont = font_spec,    # Legend
#     titlefont = font_spec      # Title
# )
# # (Only for TMM) Smooth reference curve using 1000 points for plotting purposes
# L_fine = exp10.(range(log10(1), log10(100), length=1000))
# condition_numbers_fine = L_fine ./ m
# reference_curve = 1 .- 1 ./ sqrt.(condition_numbers_fine)
# plot!(condition_numbers_fine, reference_curve, label="TMM theoretical", linewidth=2)
