cd("your-path-here\\AlgorithmAnalysis.jl\\")
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

# m,L = 1,2 # Kf = 2
# σl, σu = 1,1 # kA = 1
# kA = σu/σl
# # Primal Dual # 2
# αx = kA ≤ sqrt(2) ? 1/(2*L) : (1-kA^(-2))/L
# αl = kA ≤ sqrt(2) ? (m/4)*(2/(σu^2) + (1/(σl^2))) : m/(σu^2)
# μ = 0; γ = 1
# @algorithm begin
#     f = DualInputFunctional{Rⁿ, Rᵐ, R}()
#     f ∈ SmoothStronglyConvex(1, 2)
#     Σ = SymmetricLinearMap{Rⁿ}()
#     Σ ∈ Eigenvalues{σl^2, σu^2}()
#     ps = Rⁿ(); qs = Rᵐ(); vs = Rⁿ() 
#     ps == Zero(); f''(qs) == Zero();  Σ*ps == Zero()
#     vs - f'(ps) == Zero()


#     v0 = Rⁿ(); v0 == Zero()
#     p0, q0 = Rⁿ(), Rᵐ()
#     p1 = p0 - αx*f'(p0) + αx*(v0 - μ*(Σ*p0))
#     q1 = q0 - αx*f''(q0)

m,L = 1,10
α = 2/(L+m)
ρ = (L-m)/(L+m)
n = 3


#     v1 = v0 - αl*(Σ*(p0 + γ*(p1-p0)))
#     p2 = p1 - αx*f'(p1) + αx*(v1 - μ*(Σ*p1))
#     q2 = q1 - αx*f''(q1)
    

#     p0 => p1; p1 => p2; #p2 => p3
#     q0 => q1; q1 => q2; #q2 => q3
#     v0 => v1; #v1 => v2 
#     vs => vs; ps => ps; qs => qs;
#     performance = (v1-vs)^2
# end

function PD(σl, σu, prev_rate = 0)
    m,L = 1,2 # Kf = 2
    σl, σu = 1,1 # kA = 1
    kA = σu/σl
    # Primal Dual # 1
    # c = 2*L*σu^3/(m^2 * σl^2)
    # αx = 2/(m+L)
    # αl = m/((m+L)*(σu^2/m + c*σu))
    # μ = 0
    # γ = 0
    # Primal Dual # 2
    αx = kA ≤ sqrt(2) ? 1/(2*L) : (1-kA^(-2))/L
    αl = kA ≤ sqrt(2) ? (m/4)*(2/(σu^2) + (1/(σl^2))) : m/(σu^2)
    μ = 0
    γ = 1
    @algorithm begin
        Σ = SymmetricLinearMap{Rⁿ}()
        Σ ∈ Eigenvalues{σl^2, σu^2}()
        ps, ups = Rⁿ(), Rⁿ(); 
        qs, uqs = Rᵐ(), Rᵐ(); 
        vs = Rⁿ() 

        ps == Zero(); uqs == Zero();  Σ*ps == Zero()
        vs - ups == Zero()


        v0 = Rⁿ(); v0 == Zero()
        f0, f1, fs = R(), R(), R()
        p0, up0, up1 = Rⁿ(), Rⁿ(), Rⁿ()
        q0, uq0, uq1 = Rᵐ(), Rᵐ(), Rᵐ()
        
        p1 = p0 - αx*up0 + αx*(v0 - μ*(Σ*p0))
        q1 = q0 - αx*uq0

        v1 = v0 - αl*(Σ*(p0 + γ*(p1-p0)))
        p2 = p1 - αx*up1 + αx*(v1 - μ*(Σ*p1))
        q2 = q1 - αx*uq1
        
        up0 => up1; uq0 => uq1; ups => ups; uqs => uqs; f0 => f1; fs => fs
        
        # v2 = v1 - αl*(Σ*(p1)) #+ γ*(p2-p1)))
        # p3 = p2 - αx*fp'(p2) + αx*(v2 - μ*(Σ*p2))
        # q3 = q2 - αx*fq'(q2)

        p0 => p1; p1 => p2; #p2 => p3
        q0 => q1; q1 => q2; #q2 => q3
        v0 => v1; #v1 => v2 
        vs => vs; ps => ps; qs => qs;
        
        # ps == Zero()
        # αx*(fp'(ps) - vs + μ*(Σ*ps)) == Zero()
        # αl*(Σ*(ps)) == Zero()#+ γ*(ps-ps))) == Zero()

        # performance = evaluate(Gram([p3-ps, v2-vs]))
        # performance = (p2-ps)^2# + (v1-vs)^2 + (q2-qs)^2
        # performance = ((p2-ps)^2+(q2-qs)^2)
        performance = (v1-vs)^2
    end
    # Interpolation conditions
    interpolated_points = [(f0, [p0; q0], [up0; uq0]), (f1, [p1; q1], [up1; uq1]), (fs, [ps; qs], [ups; uqs])]
    for (fᵢ,xᵢ,uᵢ) in interpolated_points, (fⱼ,xⱼ,uⱼ) in interpolated_points
        fᵢ - fⱼ - uⱼ'*(xᵢ-xⱼ) ≥ 1/(2*(1-m/L))*(((uᵢ - uⱼ)'*(uᵢ - uⱼ)) + m*((xᵢ - xⱼ)'*(xᵢ - xⱼ)) - 2*m*((uⱼ - uᵢ)'*(xⱼ - xᵢ))/L)/L
    end
    # f0 - f1 - [up1; uq1]'*([p0; q0] - [p1; q1]) ≥ 1/(2*(1-m/L))*((([up0; uq0] - [up1; uq1])'*([up0; uq0] - [up1; uq1])) + m*(([p0; q0] - [p1; q1])'*([p0; q0] - [p1; q1])) - 2*m*(([up1; uq1] - [up0; uq0])'*([p1; q1] - [p0; q0]))/L)/L
    # f1 - f0 - [up0; uq0]'*([p1; q1] - [p0; q0]) ≥ 1/(2*(1-m/L))*((([up1; uq1] - [up0; uq0])'*([up1; uq1] - [up0; uq0])) + m*(([p1; q1] - [p0; q0])'*([p1; q1] - [p0; q0])) - 2*m*(([up0; uq0] - [up1; uq1])'*([p0; q0] - [p1; q1]))/L)/L
    # @show certify(performance, 0.995)
    @show rate(performance, 0.96)
end

# FG
function FG(m, L, lift_dimension=0, prev_rate = 0)
    m, L, lift_dimension = 1, 10, 1
    α = 4/(3*L+m); β=(sqrt(3*L+1)-2)/(sqrt(3*L+1)+2)
    @algorithm begin
        f = DifferentiableFunctional{Rⁿ}()
        xs = first_order_stationary_point(f)
        f ∈ SmoothStronglyConvex(m, L)
        x0 = Rⁿ()
        x1 = Rⁿ()
        y1 = x1 + β*(x1 - x0)
        x2 = y1 - α*f'(y1)
        # y2 = x2 + β*(x2 - x1)
        # x3 = y2 - α*f'(y2)
        x0 => x1
        x1 => x2
        # x2 => x3
        # y1 => y2  
        lift(x2, lift_dimension)
        performance = (y1-xs)^2
    end
@show rate(performance, prev_rate)
end
        
# # TMM
function TMM(m, L, prev_rate=0)
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
        # x3 = (1+β)*x2 - β*x1 - α*f'(y2)
        # y3 = (1+gamma)*x3 - gamma*x2
        # x4 = (1+β)*x3 - β*x2 - α*f'(y3)
        x0 => x1
        x1 => x2
        # x2 => x3
        # x3 => x4
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
    @show rate(performance, prev_rate)
end
# HB
function HB(m, L, prev_rate=0)
    α = 4/((sqrt(L)+sqrt(m))^2)
    β=((sqrt(L/m)-1)/(sqrt(L/m)+1))^2
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
    @show rate(performance, prev_rate)

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
# GD
function GD(m, L, prev_rate=0)
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
    @show rate(performance, prev_rate)
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

# savefig(plt, "tmm_results_bad.pdf")
# @algorithm begin
#     f = DifferentiableFunctional{Rⁿ}()
#     f ∈ SmoothStronglyConvex(m, L)
#     A = LinearMap{Rⁿ, Rᵐ}()
#     xs = Rⁿ()
#     x0 = Rⁿ()
#     ls = Rᵐ()
#     l0 = Rᵐ()
#     b = A*xs
#     # x1 = x0 - αx*(f'(x0) + A'*l0 + μ*(A'*(A*x0 - b)))
#     x1 = x0 - αx*(f'(x0) + A'*l0)
#     # l1 = l0 + αl*(A*(x0 + γ*(x1-x0))-b)
#     l1 = l0 + αl*(A*x0-b)
#     # x2 = x1 - αx*(f'(x1) + A'*l1 + μ*(A'*(A*x1 - b)))
#     x2 = x1 - αx*(f'(x1) + A'*l1)
#     # l2 = l1 + αl*(A*(x1 + γ*(x2-x1))-b)
#     l2 = l1 + αl*(A*x1-b)
#     # x3 = x2 - αx*(f'(x2) + A'*l2 + μ*(A'*(A*x2 - b)))
#     x3 = x2 - αx*(f'(x2) + A'*l2)

#     x0 => x1
#     x1 => x2
#     x2 => x3
#     l0 => l1
#     l1 => l2

#     (f'(xs) + A'*ls) == Zero()
#     performance = Gram([x0-xs, x1-xs, x2-xs, l0-ls, l1-ls])
# end
# certify(performance, 0.98, kA, A)
# @show rate(performance, 0.96)
# ρ = 0.98
# vars, cons, orcs = variables_constraints_oracles(performance)
# linear_cons = constraints(A, first(properties(A)), L)
# union!( cons, linear_cons )
# constraints(A, first(properties(A)), L)
# vars = collect(vars)
# X, X⁺, x, u = stateupdate(vars)
# # optimization problem
# model = JuMP.Model(SCS.Optimizer)
# JuMP.set_silent(model)
# # optimization variables
# JuMP.@variable(model, P[1:length(x)])
# # Lyapunov function
# V = X'*P
# V⁺ = X⁺'*P
# 𝒫 = vec(linearform( [x; u] => performance ))
# L1 = 𝒫 - V
# L2 = V⁺ - ρ^2*V
# # optimization constraints
# for con ∈ cons
#     λ = multiplier(model, con)
#     μ = multiplier(model, con)
#     e = expression(con)
#     if e isa Gram
#         e = evaluate(e)
#     end
#     if e isa Expression
#         M = vec(linearform( [x; u] => λ * e ))
#         N = vec(linearform( [x; u] => μ * e ))
#     elseif e isa Vector
#         M = vec(linearform( [x; u] => λ' * e ))
#         N = vec(linearform( [x; u] => μ' * e ))
#     elseif e isa Matrix
#         M = vec(linearform( [x; u] => la.tr(λ * e) ))
#         N = vec(linearform( [x; u] => la.tr(μ * e) ))
#     end
#     L1 += M
#     L2 += N
# end
# JuMP.@constraint(model, L1 .== 0 )
# JuMP.@constraint(model, L2 .== 0 )

# JuMP.optimize!(model)

# JuMP.termination_status(model) == JuMP.OPTIMAL