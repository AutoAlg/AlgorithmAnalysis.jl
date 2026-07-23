using Revise
using AlgorithmAnalysis
import SymbolicUtils: Term, operation, arguments, symtype, iscall, substitute

# TODO
# Lyapunov analysis
# @var a = one(R) overwrites the id, which is how we identify the multiplicative identity
# does show() actually need to construct a separate semantic_ast?

# begin
#     @alg begin
#         α, L ∈ R
#         x, xs ∈ Rⁿ
#         f ∈ F(Rⁿ)
#         gs = f'(xs)
#         g  = f'(x)
#     end

#     # --- PEP (N = 1) ---
#     obj  = f(x - α * g) - f(xs)
#     con  = smooth_convex(f, L) ∧ (gs^2 == zero(R)) ∧ ((x - xs)^2 ≤ one(R))
#     pep  = maximize(obj, con)
#     tpep = simplify(pep)

#     # --- Lyapunov 1-step SDP with f-suboptimality as performance measure ---
#     perf  = f(x) - f(xs)
#     trans = @transition begin
#         x  => x - α * g
#         xs => xs
#     end
#     c_oracle = smooth_convex(f, L) ∧ (gs^2 == zero(R))
#     prob     = certify(trans, c_oracle, perf, nothing)
#     tprob    = simplify(prob)

#     params = Dict(α => 0.075, L => 10.0)

#     with_numerics(parameters = params) do
#         evaluate(tpep) ≈ evaluate(tprob)
#     end
# end

begin
    @alg begin
        α, L, ρ ∈ R
        x, xs ∈ Rⁿ
        f ∈ F(Rⁿ)
        gs = f'(xs)
        g  = f'(x)
        t1 = x → x - α * g
        t2 = xs → xs
        c1 = smooth_convex(f, L)
        c2 = gs^2 == zero(R)
        con = t1 ∧ t2 ∧ c1 ∧ c2
        perf = (x - xs)^2
    end
    
    prob = certify(con, perf, ρ)
    # tprob = simplify(prob)

    # # Evaluate feasibility of the Lyapunov certificate.
    # with_numerics(parameters = Dict(α => 0.1, L => 1.0)) do
    #     evaluate(tprob)
    # end
end

tprob = AlgorithmAnalysis.lyapunov_transformation(prob);

trans = transitions(con)

basis      = AlgorithmAnalysis.lyapunov_basis_candidates(perf, con)

basis_next = AlgorithmAnalysis.map(expr -> AlgorithmAnalysis.apply_transitions(trans, expr), basis)

AlgorithmAnalysis.apply_transitions(trans, perf)

propagate_transitions(trans, (x-xs)^2)


tprob = propagate_transitions(t1, perf)
