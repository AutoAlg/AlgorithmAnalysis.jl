using Revise
using AlgorithmAnalysis

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