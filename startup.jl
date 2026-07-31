using Revise
using AlgorithmAnalysis
import SymbolicUtils: Term, operation, arguments, symtype, iscall, substitute, @rule

# TODO
# Lyapunov analysis
# @var a = one(R) overwrites the id, which is how we identify the multiplicative identity
# does show() actually need to construct a separate semantic_ast?
# can/should we use Real and Bool instead of R and Prop?

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
    opt = rate(con, perf)
end

tprob = simplify(prob)
with_parameters(Dict(ρ => 0.9, α => 0.1, μ => 1.0, L => 10.0)) do
    evaluate_node(tprob)
end

topt = simplify(opt)

isapprox(with_parameters(Dict(α => 0.1, μ => 1.0, L => 10.0)) do
    evaluate_node(topt)
end, 0.81, rtol = 1e-5)
