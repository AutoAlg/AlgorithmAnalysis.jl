using Revise
using AlgorithmAnalysis
using JuMP

# using SymbolicUtils: iscall, symtype, isempty, isequal

# @alg begin
#     α, L, μ, ρ ∈ R, x, x_s ∈ Rⁿ, f ∈ F(Rⁿ), P ∈ Sⁿ

#     c_f = smooth_strongly_convex(f, μ, L)
#     c_p = P ⪰ 1e-2

#     u = f'(x)
#     xn = x - α * u

#     c_opt = (f(x_s) == zero(R)) ∧ (f'(x_s) == zero(Rⁿ))

#     V = (x - x_s)'(P * (x - x_s))
#     Vn = (xn - x_s)'(P * (xn - x_s))

#     c_vnv = (Vn - ρ * V) ≤ zero(R)

#     cons = c_f ∧ c_p ∧ c_opt ∧ c_vnv
#     opt = feasible(cons)
# end

# topt1 = smooth_strongly_convex_interpolation(opt)
# topt2 = propagate_constants(topt1)
# topt3 = apply_s_procedure(topt2, c -> iscall(c) && symtype(c) <: LessThanOrEqualTo && !isempty(find_nodes(x -> isequal(x, ρ), c)))
# topt4 = extract_lmi_coefficients(topt3)


# function find_optimal_convergence_rate(; alpha::Float64, L_const::Float64, mu_const::Float64, tol::Float64=1e-5)::Float64
#     rho_low::Float64 = -0.3
#     rho_high::Float64 = 1.25
#     rho_opt::Float64 = 1.2

#     while (rho_high - rho_low) > tol
#         rho_mid::Float64 = (rho_low + rho_high) / 2.0

#         is_feasible::Bool = with_verbose(false) do
#             with_numerics(parameters=Dict(α => alpha, L => L_const, μ => mu_const, ρ => rho_mid)) do
#                 evaluate(topt4)
#             end
#         end

#         if is_feasible
#             rho_high = rho_mid
#             rho_opt = rho_mid
#         else
#             rho_low = rho_mid
#         end
#     end

#     return rho_opt
# end

# print(find_optimal_convergence_rate(alpha=0.2, L_const=10.0, mu_const=1.0))
# with_verbose(false) do
#     with_numerics(parameters=Dict(α=>0.19, L=>10.0, μ=>1.0, ρ=>0.75)) do
#         result = evaluate(topt4)
#         inspect(model())

#         println("T_1 = ", JuMP.value(model()[:T_1]))
#         println("T_2 = ", JuMP.value(model()[:T_2]))
#         println("P = ", JuMP.value.(model()[:P]))
#     end
# end