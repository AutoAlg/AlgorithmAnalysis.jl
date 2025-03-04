cd("C:\\Users\\nlam1\\.julia\\dev\\AlgorithmAnalysis.jl\\")
using Pkg
Pkg.activate(".")
using Revise
using AlgorithmAnalysis
using Logging
using Plots

m,L = 1,11
# # TMM
function TMM(m, L)
    k = L/m
    rho = 1 - 1/(sqrt(k))
    α = (1 + rho)/L
    β = (rho^2)/(2-rho)
    gamma = (rho^2)/((1+rho)*(2-rho))
    delta = (rho^2)/(1-rho^2)
    @algorithm begin
        f = DifferentiableFunctional{Rⁿ}()
        xs = first_order_stationary_point(f)
        f ∈ SmoothStronglyConvex(m, L)
        x0 = Rⁿ()
        x1 = Rⁿ()
        y1 = (1+gamma)*x1 - gamma*x0
        x2 = (1+β)*x1 - β*x0 - α*f'(y1)
        y2 = (1+gamma)*x2 - gamma*x1
        x3 = (1+β)*x2 - β*x1 - α*f'(y2)
        x0 => x1
        x1 => x2
        x2 => x3
        performance = ((1+delta)*x2 - delta*x1 -xs)^2

        # z2 = (1+delta)*x2 - delta*x1
        # z3 = (1+delta)*x3 - delta*x2
        # q1s = ((L-m)*(f(y1)-f(xs)) - (f'(y1)-f'(xs))^2/2 + (m*f'(y1)-L*f'(xs))'*(y1-xs) - m*L*(y1-xs)^2/2)
        # qs2 = ((L-m)*(f(xs)-f(y2)) - (f'(xs)-f'(y2))^2/2 + (m*f'(xs)-L*f'(y2))'*(xs-y2) - m*L*(xs-y2)^2/2)
        # q2s = ((L-m)*(f(y2)-f(xs)) - (f'(y2)-f'(xs))^2/2 + (m*f'(y2)-L*f'(xs))'*(y2-xs) - m*L*(y2-xs)^2/2)
        # q12 = ((L-m)*(f(y1)-f(y2)) - (f'(y1)-f'(y2))^2/2 + (m*f'(y1)-L*f'(y2))'*(y1-y2) - m*L*(y1-y2)^2/2)
        # V2 = m*L*(z2-xs)^2 + q1s
        # V3 = m*L*(z3-xs)^2 + q2s
        # V3 - rho^2*V2 + ((1-rho^2)*qs2 + rho^2*q12)
    end
    # certifyTMM(performance, 0.9, q1s, qs1, q01)
    # @show certify(performance, 0.9)
    @show rate(performance)
end
# HB
function HB(m, L)
    α = 4/((sqrt(L)+sqrt(m))^2)
    β=((sqrt(L/m)-1)/(sqrt(L/m)+1))^2
    @algorithm begin
        f = DifferentiableFunctional{Rⁿ}()
        xs = first_order_stationary_point(f)
        f ∈ SmoothStronglyConvex(m, L)
        # f' ∈ SectorBounded(m, L, xs, f'(xs))
        x0 = Rⁿ()
        x1 = Rⁿ()
        # x1 = x0 - α*f'(x0)
        x2 = x1 - α*f'(x1) + β*(x1-x0)
        x3 = x2 - α*f'(x2) + β*(x2-x1)
        x0 => x1
        x1 => x2
        x2 => x3
        performance = (x0-xs)^2
    end
    # certify(performance, 0.9)
    # maximize(performance)
    @show rate(performance)
end
# FG
function FG(m, L)
    α = 4/(3*L+m); β=(sqrt(3*L+1)-2)/(sqrt(3*L+1)+2)
    @algorithm begin
        f = DifferentiableFunctional{Rⁿ}()
        xs = first_order_stationary_point(f)
        f ∈ SmoothStronglyConvex(m, L)
        x0 = Rⁿ()
        x1 = Rⁿ()
        y1 = x1 + β*(x1 - x0)
        x2 = y1 - α*f'(y1)
        y2 = x2 +  β*(x2 - x1)
        x3 = y2 - α*f'(y2)
        x0 => x1
        x1 => x2
        x2 => x3
        y1 => y2  
        performance = (x0-xs)^2
    end
    # certify(performance, 0.81)
    # maximize(performance)
    @show rate(performance)
end
# GD
function GD(m, L)
    α = 2/(L+m)
    @algorithm begin
        f = DifferentiableFunctional{Rⁿ}()
        xs = first_order_stationary_point(f)
        # f' ∈ SectorBounded(m, L, xs, f'(xs))
        f ∈ SmoothStronglyConvex(m, L)
        x0 = Rⁿ()
        x1 = x0 - α*f'(x0)
        x0 => x1
        performance = (x0-xs)^2
    end
    @show rate(performance)
end

# Benchmarking Plots

m = 1
L_sampled = exp10.(range(log10(1), log10(100), length=24))  # 12 logarithmically spaced points
# L_fine = exp10.(range(log10(1), log10(100), length=1000))  # 1000 logarithmically spaced points for smooth curve
condition_numbers_sampled = L_sampled ./ m  # L/m values where function is evaluated
# condition_numbers_fine = L_fine ./ m  # L/m values for smooth reference curve
results = [FG(m, L) for L in L_sampled]  # Evaluate TMM at selected L values

# Reference function 1 - 1/sqrt(condition_numbers)
reference_curve = 1 .- 1 ./ sqrt.(condition_numbers_fine)

# Plot results
scatter(condition_numbers_sampled, results, xscale=:log10, xlabel="Condition Number (L/m)", ylabel="TMM(m, L)", title="TMM Results", label="TMM(m, L)", marker=:circle, markersize=5)
plot!(condition_numbers_fine, reference_curve, label="1 - 1/sqrt(L/m)", linewidth=2)