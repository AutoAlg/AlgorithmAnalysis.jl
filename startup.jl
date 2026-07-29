# using Revise
# using AlgorithmAnalysis
# using JuMP

# using AlgorithmAnalysis.SymbolicUtils: iscall, symtype, isempty, isequal

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
# topt3 = apply_s_procedure_to_single_constraint(topt2, c -> iscall(c) && symtype(c) <: LessThanOrEqualTo && !isempty(find_nodes(v -> isequal(v, ρ), c)))
# topt4 = extract_lmi_coefficients(topt3)

# function find_optimal_convergence_rate(
#     opt,
#     alpha_parameter::Float64,
#     lipschitz_constant::Float64,
#     strong_convexity_constant::Float64,
#     tolerance::Float64
# )::Float64
#     rho_lower_bound::Float64 = 0.0
#     rho_upper_bound::Float64 = 1.25
#     rho_optimal::Float64 = 1.0

#     while (rho_upper_bound - rho_lower_bound) > tolerance
#         rho_midpoint::Float64 = (rho_lower_bound + rho_upper_bound) / 2.0

#         is_strictly_feasible::Bool = with_verbose(false) do
#             with_numerics(parameters=Dict(α => alpha_parameter, L => lipschitz_constant, μ => strong_convexity_constant, ρ => rho_midpoint)) do
#                 evaluate(opt)
#             end
#         end

#         if is_strictly_feasible
#             rho_upper_bound = rho_midpoint
#             rho_optimal = rho_midpoint
#         else
#             rho_lower_bound = rho_midpoint
#         end
#     end

#     return rho_optimal
# end