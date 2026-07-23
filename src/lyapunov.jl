# ------------------------------------------------------
# LYAPUNOV ANALYSIS
# ------------------------------------------------------

export apply_transition

"""
    apply_transition(trans::Transition, expr::BasicSymbolic) -> BasicSymbolic

Substitute state variables in `expr` with their next-step expressions defined by `trans`.

Each pair `(state_var => next_expr)` in `trans` is applied sequentially via a single-pass
`replace_node` rewrite, so the result is the performance measure evaluated at the
next-step state. Sequential application is correct for non-coupled transitions (e.g.
gradient descent with a single state variable).

# Example
```julia
@alg begin
    x, xs ∈ Rⁿ
    f ∈ F(Rⁿ)
    α ∈ R
    g = f'(x)
end
perf  = (x - xs)^2
trans = Transition([x => x - α*g, xs => xs])
perf_next = apply_transition(trans, perf)   # = ((x - α*g) - xs)^2
```
"""
function apply_transition(trans::Transition, expr::BasicSymbolic)
    result = expr
    for p in trans.pairs
        result = replace_node(result, first(p), last(p))
    end
    return result
end

# Override the forward declaration from transformation.jl
lyapunov_transformation_is_applicable(::BasicSymbolic{LyapunovAnalysis}) = true

"""
    lyapunov_transformation(prob::BasicSymbolic{LyapunovAnalysis})

Transform a Lyapunov certification problem into a 1-step performance estimation SDP.

The conversion is:
1. Compute `perf_next` = performance measure at the next state via `apply_transition`.
2. Add a normalization constraint `perf == 1` (scale-invariance of the Lyapunov condition).
3. Return `maximize(perf_next, oracle_con ∧ (perf == 1))`.

If the optimal value of the resulting SDP is ≤ `rate`, there exists a Lyapunov function
(whose certificate is the dual variable of the Gram PSD constraint) certifying that the
performance measure decreases geometrically at the given rate.
"""
function lyapunov_transformation(prob::BasicSymbolic{LyapunovAnalysis})
    trans      = lyap_transition(prob)
    oracle_con = lyap_oracle(prob)
    perf       = lyap_performance(prob)
    rate       = lyap_rate(prob)

    # Performance measure evaluated at the next state
    perf_next = apply_transition(trans, perf)

    # Normalization: fix the scale of the current-step performance to 1
    # (The Lyapunov condition V(x_{k+1}) ≤ ρ·V(x_k) is scale-invariant.)
    norm_con = (perf == one(R))

    state_strs = join([tostring(first(p)) for p in trans.pairs], ", ")
    @info "Lyapunov: building 1-step SDP for rate ≤ $rate  (state variables: [$state_strs])"

    # 1-step worst-case SDP.
    # Certify succeeds iff  evaluate(simplify(certify(...))) ≤ rate.
    return maximize(perf_next, oracle_con ∧ norm_con)
end
