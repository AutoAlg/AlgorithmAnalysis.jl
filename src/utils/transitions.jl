export transitions, apply_transition, propagate_transition, propagate_transitions
export next, has_next, state

"Extract all transitions from a proposition."
function transitions(con::Node{Conjunction})
    foldl(∧, filter(t -> symtype(t) <: Transition, arguments(con)), init=satisfied())
end
transitions(t::Node{<:Transition}) = t
transitions(::Node{<:Prop}) = satisfied()

has_next(::Node, ::Node{<:Prop}) = false
has_next(node::Node, opt::Node{<:Optimization}) = has_next(node, constraint(opt))
has_next(node::Node, t::Node{<:Transition}) = isequal(node, arguments(t)[1])
has_next(node::Node, ts::Node{Conjunction}) = any(t -> has_next(node, t), arguments(ts))

next(node::Node, t::Node{<:Transition}) = has_next(node, t) ? arguments(t)[2] : nothing
function next(node::Node, ts::Node{Conjunction})
    if has_next(node, ts)
        idx = findfirst(t -> has_next(node, t), arguments(ts))
        next(node, arguments(ts)[idx])
    else
        nothing
    end
end
next(node::Node, opt::Node{<:Optimization}) = next(node, constraint(opt))

function state(prob::Node{LyapunovCertificate})
    ts = transitions(constraint(prob))
    if isnothing(ts)
        return nothing, nothing
    end
    states = [ arguments(t)[1] for t ∈ ts ]
    next_states = [ next(state, prob) for state ∈ states ]

    return states, next_states
end

"""
    apply_transition(trans::Node{Transition}, expr::Node) -> Node

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
function apply_transition(trans::Node{<:Transition}, expr::Node)
    result = expr
    x, x₊ = arguments(trans)
    return replace_node(result, x, x₊)
end

function apply_transitions(prop::Node{<:Prop}, expr::Node)
    trans = transitions(prop)
    result = expr
    for tran in trans
        result = apply_transition(tran, result)
    end
    return result
end

function propagate_transitions(ctx::Node, f::Node)
    points = find_evaluation_points(f, ctx)
    old, new = satisfied(), satisfied()
    if has_next(f, ctx)
        f₊ = next(f, ctx)
        for x ∈ points
            if has_next(x, ctx)
                x₊ = next(x, ctx)
                new = new ∧ ( f(x) → f₊(x₊) )
            end
        end
        old = old ∧ ( f → f₊ )
    end
    ctx = replace_constraint(ctx, old, new)
    return ctx
end

function propagate_transitions(ctx::Node, fs::Vector{<:Node})
    for f ∈ fs
        ctx = propagate_transitions(ctx, f)
    end
    return ctx
end
