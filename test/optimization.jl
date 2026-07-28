# @testitem "Linear programming" begin
#     @alg let
#         x, y ∈ R
#         c1 = 50x + 24y ≤ 2400
#         c2 = 30x + 33y ≤ 2100
#         c3 = x ≥ 45
#         c4 = y ≥ 5
#         cons = c1 ∧ c2 ∧ c3 ∧ c4
#         obj = x + y - 50
#         opt = maximize(obj, cons)
#         @test with_numerics() do
#             evaluate(opt) ≈ 1.25 && evaluate(x) ≈ 45.0 && evaluate(y) ≈ 6.25
#         end
#     end
# end

# @testitem "Semidefinite programming" begin
#     @alg let
#         x ∈ R
#         A = [2 x; x 2]
#         opt = maximize(x, A ⪰ 0)
#         @test with_numerics() do
#             evaluate(opt) ≈ 2.0
#         end
#     end

#     @alg let
#         x1, x2, x3 ∈ R
#         X = [x1 x2; x2 x3]
#         A = [1.0 0.0; 0.0 0.0]
#         B = [0.0 0.0; 0.0 1.0]
#         C = [0.0 1.0; 1.0 0.0]
#         c1 = X ⪰ 0
#         c2 = tr(A * X) == one(R)
#         c3 = tr(B * X) ≤ one(R)
#         con = c1 ∧ c2 ∧ c3
#         obj = tr(C * X)
#         opt = minimize(obj, con)
#         @test with_numerics() do
#             evaluate(opt) ≈ -2.0 && evaluate(X) ≈ [1 -1; -1 1]
#         end
#     end
# end

# @testitem "Performance estimation" begin
#     @alg begin
#         α, L ∈ R, x, xs ∈ Rⁿ, f ∈ F(Rⁿ)

#         gs = f'(xs)
#         g = f'(x)
#         init = (x - xs)'(x - xs)
#         x⁺ = x - α * g
#         f⁺ = f(x⁺)
#         c1 = smooth_convex(f, L)
#         c2 = gs'(gs) == zero(R)
#         c3 = init ≤ one(R)
#         con = c1 ∧ c2 ∧ c3
#         obj = f⁺ - f(xs)
#         opt = maximize(obj, con)
#     end

#     topt = pep_simplify(opt)

#     @test with_numerics(T=BigFloat, parameters=Dict(α => big"0.075", L => big"10.0")) do
#         evaluate(topt) ≈ 2.0
#     end
# end


@testitem "Strongly Convex Convergence Rate" begin
    using AlgorithmAnalysis
    using AlgorithmAnalysis.SymbolicUtils: iscall, symtype, isempty, isequal

    @alg begin
        α, L, μ, ρ ∈ R, x, x_s ∈ Rⁿ, f ∈ F(Rⁿ), P ∈ Sⁿ

        c_f = smooth_strongly_convex(f, μ, L)
        c_p = P ⪰ 1e-2

        u = f'(x)
        xn = x - α * u

        c_opt = (f(x_s) == zero(R)) ∧ (f'(x_s) == zero(Rⁿ))

        V = (x - x_s)'(P * (x - x_s))
        Vn = (xn - x_s)'(P * (xn - x_s))

        c_vnv = (Vn - ρ * V) ≤ zero(R)

        cons = c_f ∧ c_p ∧ c_opt ∧ c_vnv
        opt = feasible(cons)
    end

    topt1 = smooth_strongly_convex_interpolation(opt)
    topt2 = propagate_constants(topt1)
    topt3 = apply_s_procedure(topt2, c -> iscall(c) && symtype(c) <: LessThanOrEqualTo && !isempty(find_nodes(v -> isequal(v, ρ), c)))
    topt4 = extract_lmi_coefficients(topt3)

    function find_optimal_convergence_rate(
        compiled_optimization_problem,
        alpha_parameter::Float64,
        lipschitz_constant::Float64,
        strong_convexity_constant::Float64,
        tolerance::Float64
    )::Float64
        rho_lower_bound::Float64 = 0.0
        rho_upper_bound::Float64 = 1.25
        rho_optimal::Float64 = 1.0

        while (rho_upper_bound - rho_lower_bound) > tolerance
            rho_midpoint::Float64 = (rho_lower_bound + rho_upper_bound) / 2.0

            is_strictly_feasible::Bool = with_verbose(false) do
                with_numerics(parameters=Dict(α => alpha_parameter, L => lipschitz_constant, μ => strong_convexity_constant, ρ => rho_midpoint)) do
                    evaluate(compiled_optimization_problem)
                end
            end

            if is_strictly_feasible
                rho_upper_bound = rho_midpoint
                rho_optimal = rho_midpoint
            else
                rho_lower_bound = rho_midpoint
            end
        end

        return rho_optimal
    end

    tight_rate(α, L, μ) = max(abs(1 - α*μ), abs(1 - α*L))^2

    cases = [
        # (α, L, μ)  — description
        (0.05, 10.0, 1.0),  # κ=10, μ-side dominant, small step
        (2/11, 10.0, 1.0),  # κ=10, optimal step (crossover) — matches original test
        (0.15, 10.0, 1.0),  # κ=10, μ-side, near crossover
        (0.19, 10.0, 1.0),  # κ=10, L-side dominant
        (0.20, 10.0, 1.0),  # κ=10, L-side, boundary α=2/L → ρ=1
        (0.02, 10.0, 1.0),  # κ=10, very small step
        (0.10, 4.0, 2.0),  # κ=2, μ-side
        (1/3, 4.0, 2.0),  # κ=2, optimal step
        (0.25, 4.0, 2.0),  # κ=2, α=1/L
        (0.50, 4.0, 2.0),  # κ=2, boundary α=2/L → ρ=1
        (0.005, 100.0, 1.0),  # κ=100, ill-conditioned, tiny step
        (2/101, 100.0, 1.0),  # κ=100, optimal step
        (0.015, 100.0, 1.0),  # κ=100, μ-side dominant
        (0.01, 100.0, 1.0),  # κ=100, α=1/L
        (0.30, 1.5, 1.0),  # κ=1.5, well-conditioned, μ-side
        (0.80, 1.5, 1.0),  # κ=1.5, optimal step (small ρ, tests near-zero rates)
        (1.00, 2.0, 1.0),  # κ=2 at different absolute scale, boundary α=2/L
    ]

    for (α_val, L_val, μ_val) in cases
        expected = tight_rate(α_val, L_val, μ_val)
        computed = find_optimal_convergence_rate(topt4, α_val, L_val, μ_val, 1e-4)
        @test isapprox(computed, expected, atol=1e-2)
    end
end
