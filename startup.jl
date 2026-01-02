using Pkg
Pkg.activate(".")
using Revise
using AlgorithmAnalysis
using Logging
using Plots
import JuMP
import SCS
import LinearAlgebra as la
using AbstractTrees
using LiveServer

# m, L = 1, 10
# α = 2 / (L + m)
# @algorithm begin
#     f = DifferentiableFunctional{Rⁿ}()
#     xs = first_order_stationary_point(f)
#     f' ∈ SectorBounded(m, L, xs, f'(xs))
#     x0 = Rⁿ()
#     x1 = x0 - α * f'(x0)
#     x0 => x1
#     performance = (x0 - xs)^2
# end
# @show rate(performance)


function dump_fancy(e)
    show(stdout, MIME("text/plain"), e)
    println()
end

# TODO julia> @algorithm begin x = RandomR(); y = RandomR(); s = x+y; end
# julia> label(s.mean)
# "Variable{R}"
# julia> 

@algorithm begin
    w = RandomR()
    k = RandomR()
    x = R()
    rx = RandomR()

    h = RandomRⁿ()
    u = RandomRⁿ()


end

# function RVTest()

#     @algorithm begin
#         x = Rⁿ()
#         μ = Rⁿ()
#         σ = R()

#         g = GaussianRV{Rⁿ}(IntervalRange(μ, x), σ)

#         v = Rⁿ(); 
#         v_hi = Rⁿ()
#         t_sq = R();
#         h = GaussianRV{Rⁿ}(IntervalRange(v, v_hi), t_sq)
#         p = Rⁿ();
#         k_sq = R(); 
#         r_sq = R();
#         k = GaussianRV{Rⁿ}(p, IntervalRange(k_sq, r_sq));
#         Cgk_lo = R()
#         Cgk_hi = R()
#         set_bulk_covariances!([
#             (g, k) => IntervalRange(Cgk_lo, Cgk_hi)
#         ])

#         println("original gaussian")
#         dump_fancy(g)

#         println("adding x to gaussian")
#         dump_fancy(g + x)

#         println("adding gaussian to gaussian")
#         dump_fancy(g + g)

#         println("subtracting gaussian from gaussian")
#         dump_fancy(g - g)

#         println("scaled gaussian")
#         dump_fancy(2 * g)

#         println("subtracted gaussian")
#         dump_fancy(x - g)

#         println("complex expression")
#         complex = 2 * g - 4 * μ + g + g
#         dump_fancy(complex)

#         @show variance(g)
#         @show variance(complex)
#         @show expectation(complex)


#         println("negated")
#         dump_fancy(-g)

#         println("dependent sum")
#         dump_fancy(h + g)

#         println("complex dependent sum")
#         dump_fancy(g + h - k)

#         println("cancellation sum")
#         dump_fancy((g + x) - g)

#         println("sum cov")
#         @show get_covariance(g + h, g)

#         print("independent var")
#         @show variance(g + k)

#         println("compelx 2")
#         c2 = (g - h) * 0.5 + v
#         dump_fancy(c2)
#     end
# end

function SGD(m, L, prev_rate=0)
    α = 2 / (L + m)
    @algorithm begin
        f = DifferentiableFunctional{Rⁿ}()
        xs = first_order_stationary_point(f)
        f' ∈ SectorBounded(m, L, xs, f'(xs))
        ω = RandomRⁿ()
        covariance(ω, ω) ≤ 0.3
        x0 = Rⁿ()
        x1 = x0 - α * (f'(x0) + ω)
        x0 => x1
        performance = (x0 - xs)^2
    end
    @show rate(performance, prev_rate)
end

# GD
function GD(m, L, prev_rate=0)
    α = 2 / (L + m)
    @algorithm begin
        f = DifferentiableFunctional{Rⁿ}()
        xs = first_order_stationary_point(f)
        f' ∈ SectorBounded(m, L, xs, f'(xs))
        x0 = Rⁿ()
        x1 = x0 - α * f'(x0)
        x0 => x1
        performance = (x0 - xs)^2
    end
    @show rate(performance, prev_rate)
end

# FG
function FG(m, L, lift_dimension=0, prev_rate=0)
    m, L, lift_dimension = 1, 10, 1
    α = 4 / (3 * L + m)
    β = (sqrt(3 * L + 1) - 2) / (sqrt(3 * L + 1) + 2)
    @algorithm begin
        f = DifferentiableFunctional{Rⁿ}()
        xs = first_order_stationary_point(f)
        f ∈ SmoothStronglyConvex(m, L)
        x0 = Rⁿ()
        x1 = Rⁿ()
        y1 = x1 + β * (x1 - x0)
        x2 = y1 - α * f'(y1)
        x0 => x1
        x1 => x2
        lift(x2, lift_dimension)
        performance = (y1 - xs)^2
    end
    @show rate(performance, prev_rate)
end

# TM
function TM(m, L, prev_rate=0)
    κ = L / m
    ρ = 1 - 1 / (sqrt(κ))
    α = (1 + ρ) / L
    β = ρ^2 / (2 - ρ)
    γ = ρ^2 / ((1 + ρ) * (2 - ρ))
    δ = ρ^2 / (1 - ρ^2)

    @algorithm begin
        f = DifferentiableFunctional{Rⁿ}()
        xs = first_order_stationary_point(f)
        f ∈ SmoothStronglyConvex(m, L)
        x0 = Rⁿ()
        x1 = Rⁿ()
        y1 = (1 + γ) * x1 - γ * x0
        x2 = (1 + β) * x1 - β * x0 - α * f'(y1)
        y2 = (1 + γ) * x2 - γ * x1
        x0 => x1
        x1 => x2
        performance = ((1 + δ) * x2 - δ * x1 - xs)^2
    end
    @show rate(performance, prev_rate)
end

# HB
function HB(m, L, prev_rate=0)
    κ = L / m
    α = 4 / ((√L + √m)^2)
    β = ((sqrt(L / m) - 1) / (sqrt(L / m) + 1))^2
    @algorithm begin
        f = DifferentiableFunctional{Rⁿ}()
        xs = first_order_stationary_point(f)
        f ∈ SmoothStronglyConvex(m, L)
        x0 = Rⁿ()
        x1 = Rⁿ()
        x2 = x1 - α * f'(x1) + β * (x1 - x0)
        x3 = x2 - α * f'(x2) + β * (x2 - x1)
        x4 = x3 - α * f'(x3) + β * (x3 - x2)
        x0 => x1
        x1 => x2
        x2 => x3
        x3 => x4
        performance = (x1 - xs)^2
    end
    # certify(performance, 0.9)
    # maximize(performance)
    @show rate(performance, prev_rate)

    # objective function
    f = DifferentiableFunctional{Rⁿ}()
    xs = first_order_stationary_point(f)
    f' ∈ SectorBounded(m, L, xs, f'(xs))

    # iterates
    x = Vector{Rⁿ}(undef, n + 1)

    # initial condition
    x[1] = Rⁿ()

    # constraint on initial condition
    # (scale so that the maximum performance should be one to avoid numerical issues)
    (x[1] - xs)^2 ≤ ρ^(-2n)

    # algorithm
    for k = 1:n
        x[k+1] = x[k] - α * f'(x[k])
    end

    # performance measure
    performance = (x[end] - xs)^2

end


############################################################################################
# Hierarchy

AbstractTrees.children(d::Union{DataType,UnionAll}) = InteractiveUtils.subtypes(d)

"""
    hierarchy(datatype)
    
Print the subtype hierarchy of a datatype.

# Examples
```julia-repl
julia> hierarchy(Oracle)
```
"""
hierarchy(d::DataType) = AbstractTrees.print_tree(d; maxdepth=10)


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



# m,L = 1,10
# α = 2/(L+m)
# ρ = (L-m)/(L+m)
# n = 3


#     v1 = v0 - αl*(Σ*(p0 + γ*(p1-p0)))
#     p2 = p1 - αx*f'(p1) + αx*(v1 - μ*(Σ*p1))
#     q2 = q1 - αx*f''(q1)

#     p0 => p1; p1 => p2; #p2 => p3
#     q0 => q1; q1 => q2; #q2 => q3
#     v0 => v1; #v1 => v2 
#     vs => vs; ps => ps; qs => qs;
#     performance = (v1-vs)^2
# end

function PD(σl, σu, prev_rate=0)
    m, L = 1, 2 # Kf = 2
    σl, σu = 1, 1 # kA = 1
    kA = σu / σl
    # Primal Dual # 1
    # c = 2*L*σu^3/(m^2 * σl^2)
    # αx = 2/(m+L)
    # αl = m/((m+L)*(σu^2/m + c*σu))
    # μ = 0
    # γ = 0
    # Primal Dual # 2
    αx = kA ≤ sqrt(2) ? 1 / (2 * L) : (1 - kA^(-2)) / L
    αl = kA ≤ sqrt(2) ? (m / 4) * (2 / (σu^2) + (1 / (σl^2))) : m / (σu^2)
    μ = 0
    γ = 1
    @algorithm begin
        Σ = SymmetricLinearMap{Rⁿ}()
        Σ ∈ Eigenvalues{σl^2,σu^2}()
        ps, ups = Rⁿ(), Rⁿ()
        qs, uqs = Rᵐ(), Rᵐ()
        vs = Rⁿ()

        ps == Zero()
        uqs == Zero()
        Σ * ps == Zero()
        vs - ups == Zero()


        v0 = Rⁿ()
        v0 == Zero()
        f0, f1, fs = R(), R(), R()
        p0, up0, up1 = Rⁿ(), Rⁿ(), Rⁿ()
        q0, uq0, uq1 = Rᵐ(), Rᵐ(), Rᵐ()

        p1 = p0 - αx * up0 + αx * (v0 - μ * (Σ * p0))
        q1 = q0 - αx * uq0

        v1 = v0 - αl * (Σ * (p0 + γ * (p1 - p0)))
        p2 = p1 - αx * up1 + αx * (v1 - μ * (Σ * p1))
        q2 = q1 - αx * uq1

        up0 => up1
        uq0 => uq1
        ups => ups
        uqs => uqs
        f0 => f1
        fs => fs

        # v2 = v1 - αl*(Σ*(p1)) #+ γ*(p2-p1)))
        # p3 = p2 - αx*fp'(p2) + αx*(v2 - μ*(Σ*p2))
        # q3 = q2 - αx*fq'(q2)

        p0 => p1
        p1 => p2 #p2 => p3
        q0 => q1
        q1 => q2 #q2 => q3
        v0 => v1 #v1 => v2 
        vs => vs
        ps => ps
        qs => qs

        # ps == Zero()
        # αx*(fp'(ps) - vs + μ*(Σ*ps)) == Zero()
        # αl*(Σ*(ps)) == Zero()#+ γ*(ps-ps))) == Zero()

        # performance = evaluate(Gram([p3-ps, v2-vs]))
        # performance = (p2-ps)^2# + (v1-vs)^2 + (q2-qs)^2
        # performance = ((p2-ps)^2+(q2-qs)^2)
        performance = (v1 - vs)^2
    end
    # Interpolation conditions
    interpolated_points = [(f0, [p0; q0], [up0; uq0]), (f1, [p1; q1], [up1; uq1]), (fs, [ps; qs], [ups; uqs])]
    for (fᵢ, xᵢ, uᵢ) in interpolated_points, (fⱼ, xⱼ, uⱼ) in interpolated_points
        fᵢ - fⱼ - uⱼ' * (xᵢ - xⱼ) ≥ 1 / (2 * (1 - m / L)) * (((uᵢ - uⱼ)' * (uᵢ - uⱼ)) + m * ((xᵢ - xⱼ)' * (xᵢ - xⱼ)) - 2 * m * ((uⱼ - uᵢ)' * (xⱼ - xᵢ)) / L) / L
    end
    # f0 - f1 - [up1; uq1]'*([p0; q0] - [p1; q1]) ≥ 1/(2*(1-m/L))*((([up0; uq0] - [up1; uq1])'*([up0; uq0] - [up1; uq1])) + m*(([p0; q0] - [p1; q1])'*([p0; q0] - [p1; q1])) - 2*m*(([up1; uq1] - [up0; uq0])'*([p1; q1] - [p0; q0]))/L)/L
    # f1 - f0 - [up0; uq0]'*([p1; q1] - [p0; q0]) ≥ 1/(2*(1-m/L))*((([up1; uq1] - [up0; uq0])'*([up1; uq1] - [up0; uq0])) + m*(([p1; q1] - [p0; q0])'*([p1; q1] - [p0; q0])) - 2*m*(([up0; uq0] - [up1; uq1])'*([p0; q0] - [p1; q1]))/L)/L
    # @show certify(performance, 0.995)
    @show rate(performance, 0.96)
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
