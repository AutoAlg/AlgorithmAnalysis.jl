cd("C:\\Users\\nlam1\\.julia\\dev\\AlgorithmAnalysis.jl\\")
using Pkg
Pkg.activate(".")
using Revise
using AlgorithmAnalysis
using Logging
using Plots
using LaTeXStrings
import JuMP
import SCS
import LinearAlgebra as la

function PD(σl, σu, param, prev_rate = 0)
    # σl, σu, param,prev_rate = 1,1,2,0
    m,L = 1,2 # Kf = 2
    kA = σl/σu
    # Primal Dual 1
    if param == 1
        c = 2*L*σu^3/(m^2 * σl^2)
        αx = 2/(m+L)
        αl = m/((m+L)*(σu^2/m + c*σu))
        μ = 0; γ = 0
    else # Primal Dual # 2
        αx = kA ≤ sqrt(2) ? 1/(2*L) : (1-kA^(-2))/L
        αl = kA ≤ sqrt(2) ? (m/4)*(2/(σu^2) + (1/(σl^2))) : m/(σu^2)
        μ = 0; γ = 1
    end
    @algorithm begin
        f = TwoInputDifferentiableFunctional{Rⁿ, Rᵐ}()
        f ∈ SmoothStronglyConvex(m, L)
        Σ = SymmetricLinearMap{Rⁿ}()
        Σ ∈ Eigenvalues{σl^2, σu^2}()
        ps = Rⁿ(); qs = Rᵐ(); 
        vs = Rⁿ(); v0 = Rⁿ();
        # Constraints
        ps == Zero(); first(f'([ps; qs])) == Zero();  Σ*ps == Zero(); vs - first(f'([ps; qs])) == Zero(); v0 == Zero()

        p0, q0 = Rⁿ(), Rᵐ()
        p1 = p0 - αx*first(f'([p0; q0])) + αx*(v0 - μ*(Σ*p0))
        q1 = q0 - αx*last(f'([p0; q0]))

        v1 = v0 - αl*(Σ*(p0 + γ*(p1-p0)))
        p2 = p1 - αx*first(f'([p1; q1])) + αx*(v1 - μ*(Σ*p1))
        q2 = q1 - αx*last(f'([p1; q1]))

        # v2 = v1 - αl*(Σ*(p1 + γ*(p2-p1)))
        # p3 = p2 - αx*first(f'([p2; q2])) + αx*(v2 - μ*(Σ*p2))
        # q3 = q2 - αx*last(f'([p2; q2]))
        
        p0 => p1; p1 => p2; #p2 => p3
        q0 => q1; q1 => q2; #q2 => q3
        v0 => v1; #v1 => v2
        vs => vs; ps => ps; qs => qs;

        performance = (v1-vs)^2
    end
    @show rate(performance)
end
# TMM
function TMM(m, L, lifting_dimension=0, prev_rate=0)
    # m, L, lifting_dimension, prev_rate = 1, 1.5, 1, 0
    goal = 1-1/sqrt(L); k = L/m; rho = 1 - 1/(sqrt(k)); α = (1 + rho)/L; β = (rho^2)/(2-rho); gamma = (rho^2)/((1+rho)*(2-rho)); delta = (rho^2)/(1-rho^2)
    @algorithm begin
        f = DifferentiableFunctional{Rⁿ}()
        xs = first_order_stationary_point(f)
        f ∈ SmoothStronglyConvex(m, L)
        x0 = Rⁿ()
        x1 = Rⁿ()
        y1 = (1+gamma)*x1 - gamma*x0
        x2 = (1+β)*x1 - β*x0 - α*f'(y1)
        # y2 = (1+gamma)*x2 - gamma*x1
        # x3 = (1+β)*x2 - β*x1 - α*f'(y2)
        x0 => x1
        x1 => x2
        # x2 => x3
        # y3 = (1+gamma)*x3 - gamma*x2
        # x4 = (1+β)*x3 - β*x2 - α*f'(y3)
        # x3 => x4
        lift(x2, lifting_dimension)
        performance = ((1+delta)*(x2) - delta*(x1) -xs)^2
        # performance = (x2-xs)^2
    end
    @show rate(performance, prev_rate)
end
# FG
function FG(m, L, lifting_dimension=0, prev_rate = 0)
    # m, L, lifting_dimension, prev_rate = 1, 10, 1, 0
    α = 4/(3*L+m); β=(sqrt(3*L+1)-2)/(sqrt(3*L+1)+2)
    @algorithm begin
        f = DifferentiableFunctional{Rⁿ}()
        xs = first_order_stationary_point(f)
        f ∈ SmoothStronglyConvex(m, L)
        x0 = Rⁿ()
        x1 = Rⁿ()
        y1 = x1 + β*(x1 - x0)
        x2 = y1 - α*f'(y1)
        x0 => x1
        x1 => x2
        lift(x2, lifting_dimension)
        performance = (x1-xs)^2
    end
    @show rate(performance, prev_rate)
end
# HB
function HB(m, L, lifting_dimension=1, prev_rate=0)
    # m, L, lifting_dimension, prev_rate = 1, 10, 1, 0
    α = 4/((sqrt(L)+sqrt(m))^2)
    β=((sqrt(L/m)-1)/(sqrt(L/m)+1))^2
    @algorithm begin
        f = DifferentiableFunctional{Rⁿ}()
        xs = first_order_stationary_point(f)
        f ∈ SmoothStronglyConvex(m, L)
        x0 = Rⁿ()
        x1 = Rⁿ()
        x2 = x1 - α*f'(x1) + β*(x1-x0)
        x0 => x1
        x1 => x2
        lift(x2, lifting_dimension)
        performance = (x1-xs)^2
    end
    @show rate(performance, prev_rate)
end
# GD
function GD(m, L, lifting_dimension=0, prev_rate=0)
    α = 2/(L+m)
    @algorithm begin    
        f = DifferentiableFunctional{Rⁿ}()
        f ∈ SmoothStronglyConvex(m, L)        
        # f' ∈ SectorBounded(m, L, xs, f'(xs))
        xs = first_order_stationary_point(f)
        
        x0 = Rⁿ()
        x1 = x0 - α*f'(x0)
        x0 => x1
        lift(x1, lifting_dimension)
        performance = (x0-xs)^2
    end
    @show rate(performance, prev_rate)
end
function plot_lift(savef::Bool, points_per_algo=12)
    # Generate results: Set up the parameters of the function calls
    # savef = true; points_per_algo = 20
    points_per_algo = 20
    m, L_sampled = 1, exp10.(range(log10(1), log10(100), length=points_per_algo))
    condition_numbers_sampled = L_sampled ./ m

    resultsTMM0 = [] # Generate lift 0
    for L in L_sampled
        prev_rate = length(resultsTMM0) == 0 ? 0 : resultsTMM0[end]
        push!(resultsTMM0, HB(m, L, 0, prev_rate))
    end
    resultsTMM1 = [] # Generate lift 1
    for L in L_sampled
        prev_rate = length(resultsTMM1) == 0 ? 0 : resultsTMM1[end]
        push!(resultsTMM1, HB(m, L, 1, prev_rate))
    end
    resultsTMM2 = [] # Generate lift 2
    for L in L_sampled
        prev_rate = length(resultsTMM2) == 0 ? 0 : resultsTMM2[end]
        push!(resultsTMM2, HB(m, L, 2, prev_rate))
    end

    # Plot the results: Set up blank plot
    tick_positions = (union(collect(1:10), collect(10:10:100)))
    tick_labels = Dict(1 => L"10^0", 10 => L"10^1", 100 => L"10^2")
    formatted_labels = [get(tick_labels, x, "") for x in tick_positions]
    font_spec = font("Computer Modern", 12)
    plt = scatter(
        xscale=:log10,
        xlabel="Condition Number (L/m)",
        ylabel="Convergence rate",
        xticks=(tick_positions, formatted_labels),
        ylim = (0, 1.1),
        xlim = (nothing, 110),
        guidefont = font_spec,     # Axis labels
        tickfont = font_spec,      # Tick labels
        legendfont = font_spec,    # Legend
        titlefont = font_spec      # Title
    )
    scatter!(plt, condition_numbers_sampled, resultsTMM0; label = "HB(m, L) (lift 0)", markersize = 9, marker = :circle, markerstrokewidth = 1.5,
    markerstrokecolor = :black)
    scatter!(plt, condition_numbers_sampled, resultsTMM1; label = "HB(m, L) (lift 1)", markersize = 7, marker = :diamond, markerstrokewidth = 1.5,
    markerstrokecolor = :black)
    scatter!(plt, condition_numbers_sampled, resultsTMM2; label = "HB(m, L) (lift 2)", markersize = 5, marker = :utriangle, markerstrokewidth = 1.5,
    markerstrokecolor = :black)

    L_fine = exp10.(range(log10(1), log10(100), length=1000))
    condition_numbers_fine = L_fine ./ m
    reference_curveTMM = 1 .- 1 ./ sqrt.(condition_numbers_fine)
    reference_curveGD = (L_fine.-m)./(L_fine.+m)

    color = plt.series_list[end][:seriescolor]
    # plot!(condition_numbers_fine, reference_curveTMM, label="TMM theoretical", color = color, linewidth=2)
    # plot!(condition_numbers_fine, reference_curveGD, label="GD theoretical", color = color, linewidth=2)
    if savef
        savefig(plt, "HBresults.pdf")
    end
end
function plot_results(savef::Bool, points_per_algo=12)
    # Generate results: Set up the parameters of the function calls
    save = false; points_per_algo = 12
    m, L_sampled = 1, exp10.(range(log10(1), log10(100), length=points_per_algo))
    condition_numbers_sampled = L_sampled ./ m

    resultsGD = [] # Generate GD
    for L in L_sampled
        prev_rate = length(resultsGD) == 0 ? 0 : resultsGD[end]
        push!(resultsGD, GD(m, L, 1, prev_rate))
    end
    resultsFG = [] # Generate FG
    for L in L_sampled
        prev_rate = length(resultsFG) == 0 ? 0 : resultsFG[end]
        push!(resultsFG, FG(m, L, 1, prev_rate))
    end
    resultsHB = [] # Generate HB
    for L in L_sampled
        prev_rate = length(resultsHB) == 0 ? 0 : resultsHB[end]
        push!(resultsHB, HB(m, L, 1, prev_rate))
    end
    resultsTMM = [] # Generate TMM
    for L in L_sampled
        prev_rate = length(resultsTMM) == 0 ? 0 : resultsTMM[end]
        push!(resultsTMM, TMM(m, L, 1, prev_rate))
    end
    # (Only for TMM) Smooth reference curve using 1000 points for plotting purposes
    L_fine = exp10.(range(log10(1), log10(100), length=1000))
    condition_numbers_fine = L_fine ./ m
    reference_curveTMM = 1 .- 1 ./ sqrt.(condition_numbers_fine)
    reference_curveGD = (L_fine.-m)./(L_fine.+m)

    # Plot the results: Set up blank plot
    tick_positions = (union(collect(1:10), collect(10:10:100)))
    tick_labels = Dict(1 => L"10^0", 10 => L"10^1", 100 => L"10^2")
    formatted_labels = [get(tick_labels, x, "") for x in tick_positions]
    font_spec = font("Computer Modern", 12)
    plt = scatter(
        xscale=:log10,
        xlabel="Condition Number (L/m)",
        ylabel="Convergence rate ρ",
        xticks=(tick_positions, formatted_labels),
        ylim = (0, 1.1),
        xlim = (nothing, 110),
        guidefont = font_spec,     # Axis labels
        tickfont = font_spec,      # Tick labels
        legendfont = font_spec,    # Legend
        titlefont = font_spec      # Title
    )
    scatter!(plt, condition_numbers_sampled, resultsGD; label = "GD(m, L)", markersize = 5)
    gd_color = plt.series_list[end][:seriescolor]
    plot!(condition_numbers_fine, reference_curveGD, label="GD theoretical", color = gd_color, linewidth=2)
    scatter!(plt, condition_numbers_sampled, resultsFG; label = "FG(m, L)", markersize = 5)
    scatter!(plt, condition_numbers_sampled, resultsHB; label = "HB(m, L)", markersize = 5)
    scatter!(plt, condition_numbers_sampled, resultsTMM; label = "TMM(m, L)", markersize = 5)
    tmm_color = plt.series_list[end][:seriescolor]
    plot!(condition_numbers_fine, reference_curveTMM, label="TMM theoretical", color = tmm_color, linewidth=2)
    if savef
        savefig(plt, "results.pdf")
    end
end
function plot_PD()
# Generate results: Set up the parameters of the function calls
    ol, ou_sampled = 1, exp10.(range(log10(1), log10(10), length=6))
    condition_numbers_sampled = ou_sampled ./ m
    resultsPD1, resultsPD2 = [], [] # Generate PD
    for ou in ou_sampled
        push!(resultsPD1, PD(ol, ou, 1, length(resultsPD1) == 0 ? 0 : resultsPD1[end]))
        push!(resultsPD2, PD(ol, ou, 2, length(resultsPD2) == 0 ? 0 : resultsPD2[end]))
    end
    # Plot the results: Set up blank plot
    tick_positions = collect(1:10)
    tick_labels = Dict(1 => L"10^0", 10 => L"10^1")
    formatted_labels = [get(tick_labels, x, "") for x in tick_positions]
    font_spec = font("Computer Modern", 12)
    plt = scatter(
        xscale=:log10,
        xlabel="Condition Number (σl/σu)",
        ylabel="Convergence rate",
        xticks=(tick_positions, formatted_labels),
        ylim = (0.9975, 1.001),
        xlim = (nothing, 11),
        guidefont = font_spec,     # Axis labels
        tickfont = font_spec,      # Tick labels
        legendfont = font_spec,    # Legend
        titlefont = font_spec      # Title
    )
    scatter!(plt, condition_numbers_sampled, resultsPD1; label = "PD1(σl, σu)", markersize = 5)
    scatter!(plt, condition_numbers_sampled, resultsPD2; label = "PD2(σl, σu)", markersize = 5)
    savefig(plt, "PDresults.pdf")
end

# function PD(σl, σu, prev_rate = 0)
#     m,L = 1,2 # Kf = 2
#     σl, σu = 1,1 # kA = 1
#     kA = σu/σl
#     # Primal Dual # 1
#     # c = 2*L*σu^3/(m^2 * σl^2)
#     # αx = 2/(m+L)
#     # αl = m/((m+L)*(σu^2/m + c*σu))
#     # μ = 0
#     # γ = 0
#     # Primal Dual # 2
#     αx = kA ≤ sqrt(2) ? 1/(2*L) : (1-kA^(-2))/L
#     αl = kA ≤ sqrt(2) ? (m/4)*(2/(σu^2) + (1/(σl^2))) : m/(σu^2)
#     μ = 0
#     γ = 1
#     @algorithm begin
#         Σ = SymmetricLinearMap{Rⁿ}()
#         Σ ∈ Eigenvalues{σl^2, σu^2}()
#         ps, ups = Rⁿ(), Rⁿ(); 
#         qs, uqs = Rᵐ(), Rᵐ(); 
#         vs = Rⁿ() 

#         ps == Zero(); uqs == Zero();  Σ*ps == Zero()
#         vs - ups == Zero()

#         v0 = Rⁿ(); v0 == Zero()
#         f0, f1, fs = R(), R(), R()
#         p0, up0, up1 = Rⁿ(), Rⁿ(), Rⁿ()
#         q0, uq0, uq1 = Rᵐ(), Rᵐ(), Rᵐ()
        
#         p1 = p0 - αx*up0 + αx*(v0 - μ*(Σ*p0))
#         q1 = q0 - αx*uq0

#         v1 = v0 - αl*(Σ*(p0 + γ*(p1-p0)))
#         p2 = p1 - αx*up1 + αx*(v1 - μ*(Σ*p1))
#         q2 = q1 - αx*uq1
        
#         up0 => up1; uq0 => uq1; ups => ups; uqs => uqs; f0 => f1; fs => fs
        
#         # v2 = v1 - αl*(Σ*(p1)) #+ γ*(p2-p1)))
#         # p3 = p2 - αx*fp'(p2) + αx*(v2 - μ*(Σ*p2))
#         # q3 = q2 - αx*fq'(q2)

#         p0 => p1; p1 => p2; #p2 => p3
#         q0 => q1; q1 => q2; #q2 => q3
#         v0 => v1; #v1 => v2 
#         vs => vs; ps => ps; qs => qs;
        
#         # ps == Zero()
#         # αx*(fp'(ps) - vs + μ*(Σ*ps)) == Zero()
#         # αl*(Σ*(ps)) == Zero()#+ γ*(ps-ps))) == Zero()

#         # performance = evaluate(Gram([p3-ps, v2-vs]))
#         # performance = (p2-ps)^2# + (v1-vs)^2 + (q2-qs)^2
#         # performance = ((p2-ps)^2+(q2-qs)^2)
#         performance = (v1-vs)^2
#     end
#     # Interpolation conditions
    # interpolated_points = [(f0, [p0; q0], [up0; uq0]), (f1, [p1; q1], [up1; uq1]), (fs, [ps; qs], [ups; uqs])]
    # for (fᵢ,xᵢ,uᵢ) in interpolated_points, (fⱼ,xⱼ,uⱼ) in interpolated_points
    #     fᵢ - fⱼ - uⱼ'*(xᵢ-xⱼ) ≥ 1/(2*(1-m/L))*(((uᵢ - uⱼ)'*(uᵢ - uⱼ)) + m*((xᵢ - xⱼ)'*(xᵢ - xⱼ)) - 2*m*((uⱼ - uᵢ)'*(xⱼ - xᵢ))/L)/L
#     end
#     # f0 - f1 - [up1; uq1]'*([p0; q0] - [p1; q1]) ≥ 1/(2*(1-m/L))*((([up0; uq0] - [up1; uq1])'*([up0; uq0] - [up1; uq1])) + m*(([p0; q0] - [p1; q1])'*([p0; q0] - [p1; q1])) - 2*m*(([up1; uq1] - [up0; uq0])'*([p1; q1] - [p0; q0]))/L)/L
#     # f1 - f0 - [up0; uq0]'*([p1; q1] - [p0; q0]) ≥ 1/(2*(1-m/L))*((([up1; uq1] - [up0; uq0])'*([up1; uq1] - [up0; uq0])) + m*(([p1; q1] - [p0; q0])'*([p1; q1] - [p0; q0])) - 2*m*(([up0; uq0] - [up1; uq1])'*([p0; q0] - [p1; q1]))/L)/L
#     # @show certify(performance, 0.995)
#     @show rate(performance, 0.96)
# end