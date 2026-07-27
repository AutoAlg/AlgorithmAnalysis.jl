using Revise
using AlgorithmAnalysis

using SymbolicUtils: iscall, symtype, isempty, isequal

# TODO
# Lyapunov analysis
@alg begin
    α, L, ρ ∈ R, x, x_s ∈ Rⁿ, f ∈ F(Rⁿ), P ∈ Sⁿ

    c_f = smooth_convex(f, L)
    c_p = P ⪰ 1e-6

    u = f'(x) # g
    xn = x - α * u # X_{k+1} = Ax + Bu

    c_opt = (f(x_s) == zero(R)) ∧ (f'(x_s) == zero(Rⁿ))

    V = (x - x_s)'(P * (x - x_s))
    Vn = (xn - x_s)'(P * (xn - x_s))

    c_vnv = (Vn - ρ * V) ≤ zero(R)

    cons = c_f ∧ c_p ∧ c_opt ∧ c_vnv
    opt = feasible(cons)
end

topt1 = smooth_convex_interpolation(opt);
topt2 = propagate_constants(topt1);
topt3 = apply_s_procedure(topt2, c -> iscall(c) && symtype(c) <: LessThanOrEqualTo && !isempty(find_nodes(x -> isequal(x, ρ), c)))
topt4 = extract_lmi_coefficients(topt3)

# with_numerics(parameters=Dict(α => 0.1, L => 1.0, ρ => 0.9)) do
#     evaluate(topt4)
#     inspect(model())
# end

function find_optimal_convergence_rate(; alpha::Float64, L_const::Float64, tol::Float64=1e-5)
    rho_low = 0.0
    rho_high = 1.0
    rho_opt = 1.0

    while (rho_high - rho_low) > tol
        rho_mid = (rho_low + rho_high) / 2.0

        # Suppress verbose output during the bisection loop
        is_feasible = with_verbose(false) do
            with_numerics(parameters=Dict(α => alpha, L => L_const, ρ => rho_mid)) do
                evaluate(topt4)
            end
        end

        if is_feasible
            rho_high = rho_mid
            rho_opt = rho_mid
        else
            rho_low = rho_mid
        end
    end

    return rho_opt
end

print(find_optimal_convergence_rate(alpha=0.1, L_const=1.0))

# NOTE: flip steps 2 & 3

# with_numeric( inject ρ)
#     do_bisection_search(evaluate(topt3)) 

# function w/ interpolation conditions
# s procedure
# gram stuff

# Meeting things

# how does this frontend look?
# How does the test case look?

# Sⁿ * Rⁿ representation.jl

# is the epsilon semidefinite -> definite thing fine? numeric:142
# I did add ≻ correctely, right? in representation.jl


# going forward the plan is to do seperate passes
# im thinking [
#   algebra,
#   expand sc & propagate x->xn,
#   algebra,
#   s-procedure,
#   algebra,
#   gram
#]
# breaking up the theory into multiple parts that can be segmented
# I'm also going to apply this to the pep stuff too but just vcat so it doesnt matter