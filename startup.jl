using Revise
using AlgorithmAnalysis
import SymbolicUtils: Term, operation, arguments, symtype, iscall, substitute, @rule

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

@alg begin
    α, μ, L, ρ ∈ R
    x, xs, y ∈ Rⁿ
    f ∈ F(Rⁿ)
    gs = f'(xs)
    g  = f'(x)
    x₊ = x - α * g
    t1 = x → x₊
    t2 = xs → xs
    t3 = (f → f) ∧ (f' → f')
    c1 = sector_bounded(f, μ, L)
    c2 = gs^2 == zero(R)
    con = t1 ∧ t2 ∧ t3 ∧ c1 ∧ c2
    perf = (x - xs)^2
    prob = certify(con, perf, ρ)
end

# @alg begin
#     α, ρ, μ, L ∈ R
#     x, y ∈ Rⁿ
#     f ∈ F(Rⁿ)
#     con = sector_bounded(f, μ, L)
#     perf = (x - α * f'(x))^2
#     prob = certify(con, perf, ρ)
# end

prob

tprob = sector_bounded_interpolation(prob)

ttprob = gram_transformation(tprob)


opt = with_numerics(parameters = Dict(ρ => 0.9, α => 0.1, μ => 1.0, L => 10.0)) do
    evaluate_node(ttprob)
end

cons = arguments(constraint(opt))

with_numerics(parameters = Dict(ρ => 0.9, α => 0.1, μ => 1.0, L => 10.0)) do
    evaluate(opt)
end

with_verbose() do
    with_numerics() do
        evaluate(feasible(cons[1]))
    end
end

# # Retain R across operations and scalar products
# promote_symtype(::typeof(*), ::Type{<:Number}, ::Type{R}) = R
# promote_symtype(::typeof(*), ::Type{R}, ::Type{<:Number}) = R
# promote_symtype(::typeof(*), ::Type{<:R}, ::Type{<:R}) = R

# simp = SymbolicUtils.Rewriters.Fixpoint(
#     SymbolicUtils.Rewriters.Prewalk(
#         SymbolicUtils.Rewriters.Chain(
#             [
#                 @rule ~x::isone * ~y::(y -> symtype(y) <: R) => R(~y)
#             ]
#         )
#     )
# )

# z = simp( one(R) * R(2) )


# @alg begin
#     α, μ, L ∈ R, x, xs ∈ Rⁿ, f ∈ F(Rⁿ)

#     gs   = f'(xs)
#     g    = f'(x)
#     x⁺   = x - α * g
#     c1   = sector_bounded(f, μ, L)
#     c2   = gs^2 == zero(R)
#     con  = c1 ∧ c2 ∧ (f' → f') ∧ (x → x⁺)
#     perf = (x-xs)^2
#     opt  = feasible(con)
# end

# topt = simplify(opt)

# with_numerics(parameters = Dict(α => 0.1, μ => 1.0, L => 10.0)) do
#     evaluate(topt)
# end


@alg begin
    x ∈ R
    A = [-2 x; x -2]
end
with_numerics() do
    evaluate(feasible((x ≥ 1) ∧ (x ≤ 2)))
end

