export find_nodes, replace_nodes, flatten_evaluations
export rewrite, find_evaluation_points
export with_verbose, postwalk_with_operators
export transitions, apply_transition, propagate_transition, propagate_transitions
export has_next, next, tostring

function postwalk_with_operators(f, x)
    if iscall(x)
        op = postwalk_with_operators(f, operation(x))
        args = map(arg -> postwalk_with_operators(f, arg), arguments(x))
        return f(maketerm(typeof(x), op, args, metadata(x)))
    else
        return f(x)
    end
end

"""
    rewrite(node, rules)
"""
rewrite(node::Node, rules) = postwalk_with_operators(Chain(rules), node)

"""
    find_nodes(predicate::Function, tree) -> Vector

Recursively scans a SymbolicUtils AST or algebraic expression. Returns a flat vector 
containing every sub-tree, terminal node, or variable that satisfies `predicate(node)`.
"""
function find_nodes(predicate::Function, node, results::Set = Set())
    if predicate(node)
        push!(results, node)
    end
    if !iscall(node)
        return
    end
    op = operation(node)
    args = arguments(node)

    find_nodes(predicate, op, results)
    for arg in args
        find_nodes(predicate, arg, results)
    end
    return results
end

"""
    replace_node(tree, old_node, new_node)

Walks the entire AST and swaps every instance that matches `old_node` 
with `new_node`.
"""
function replace_node(tree::Node, old_node::Node, new_node::Node)
    return postwalk_with_operators(tree) do node
        isequal(node, old_node) ? new_node : node
    end
end

function flatten_evaluations(tree::Node, f::Node)

    f₊ = next(f, tree)
    T = symtype(f).parameters[2]
    iseval(x) = iscall(x) && isequal(operation(x), f)
    newsym(x) = begin
        arg = tostring(arguments(x)[1])
        fstr = tostring(f)
        sym = Symbol(fstr, "(", arg, ")")
        x₊ = next(x, tree)
        if !isnothing(f₊) && !isnothing(x₊)
            return Sym{T}(sym)
        else
            return Sym{T}(sym)
        end
    end
    
    rule = @rule( ~x => newsym(~x) where iseval(~x) )
    return rewrite(tree, [rule])
end

function flatten_evaluations(tree::Node, fs::Vector{Node})
    for f ∈ fs
        tree = flatten_evaluations(tree, f)
    end
    return tree
end

function flatten_inner_product(v1::Node, v2::Node)

    if symtype(v1) ≠ symtype(v2)
        error("Inner product of $v1 and $v2 cannot be flattened since they are in different spaces")
    end

    if iszero(v1) || iszero(v2)
        return zero(field(v1))
    end

    if iscall(v1) && isequal(operation(v1), -) && length(arguments(v1)) == 1
        return -flatten_inner_product(arguments(v1)[1], v2)
    end
    if iscall(v2) && isequal(operation(v2), -) && length(arguments(v2)) == 1
        return -flatten_inner_product(v1, arguments(v2)[1])
    end

    if issym(v1) && issym(v2)
        T = field(v1)
        s1 = tostring(v1)
        s2 = tostring(v2)
        if isequal(v1, v2)
            sym = Symbol("‖", s1, "‖²")
        else
            first_str, second_str = s1 < s2 ? (s1, s2) : (s2, s1)
            sym = Symbol("⟨", first_str, ",", second_str, "⟩")
        end
        return Sym{T}(sym)
    end

    if iscall(v1)
        op = operation(v1)
        args = arguments(v1)
        if isequal(op, +)
            return sum(map(v -> flatten_inner_product(v, v2), args))
        elseif isequal(op, -)
            if length(args) == 2
                return flatten_inner_product(args[1], v2) - flatten_inner_product(args[2], v2)
            end
        elseif isequal(op, *)
            # Assuming first arg is scalar, second is vector
            return args[1] * flatten_inner_product(args[2], v2)
        end
    end

    if iscall(v2)
        op = operation(v2)
        args = arguments(v2)
        if isequal(op, +)
            return sum(map(v -> flatten_inner_product(v1, v), args))
        elseif isequal(op, -)
            new_args = map(v -> flatten_inner_product(v1, v), args)
            if length(args) == 2
                return flatten_inner_product(v1, args[1]) - flatten_inner_product(v1, args[2])
            end
        elseif isequal(op, *)
            # Assuming first arg is scalar, second is vector
            return args[1] * flatten_inner_product(v1, args[2])
        end
    end

    error("Could not flatten inner product between vectors $v1 and $v2")
end

"""
    find_evaluation_points!(node, state::ExtendedProblemAnalysisState)

Recursively crawls your optimization tree. It safely matches standard function calls 
and looks inside applied adjoint operators to capture gradient evaluation points.
"""
function find_evaluation_points(f::Node, node::Node)
    evals = find_nodes(x -> iscall(x) && isequal(operation(x), f), node)
    map(x -> arguments(x)[1], collect(evals))
end

# iterate over conjunctions
iterate(prop::Node{Conjunction}) = iterate(prop, 1)
function iterate(prop::Node{Conjunction}, i::Int)
    args = arguments(prop)
    if i < 0 || i > length(args)
        return nothing
    else
        return args[i], i+1
    end
end
length(prop::Node{Conjunction}) = length(arguments(prop))

function tostring(node::Node)
    buf = IOBuffer()
    show(IOContext(buf, :compact => true), node)
    return String(take!(buf))
end


const VERBOSE = Base.ScopedValues.ScopedValue{Bool}(false)
verbose() = VERBOSE[]
with_verbose(code::Function, verbose::Bool = true) = Base.ScopedValues.with(code, VERBOSE => verbose)

"""
simple binary search
  f: function that evaluates to true or false
  a: lower bound
  b: upper bound
  tol: tolerance
Assumes f(a)==false and f(b)==true and f is monotone (only one cross-over point)
Returns the smallest x in [a,b] (within tol) such that f(x)==true.
"""
function bsmin(f, a::T, b::T; tol=T(1e-5), verbose=false) where T
    a, b = a > b ? (b, a) : (a, b)
    i = 0
    while (b - a) > tol
        i += 1
        c = (a + b) / T(2)
        f(c) ? (b = c) : (a = c)
        verbose && println("iteration $i: ($a, $b), gap = $(b-a)")
    end
    return b
end

"Extract all transitions from a proposition."
function transitions(con::Node{Conjunction})
    foldl(∧, filter(t -> symtype(t) <: Transition, arguments(con)))
end
transitions(t::Node{<:Transition}) = t

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


# x → x₊, fₓ = f(x), and f₊ = f(x₊) implies fₓ → f₊
function propagate_transition(t::Node{<:Transition}, expr::Node)
    x, x₊ = arguments(t)

    substitute_x(n) = n === x ? x₊ : n

    expr₊ = postwalk_with_operators(expr) do node
        if iscall(node)
            # Check if x is present in the arguments or operation of this function node
            has_source = (operation(node) === x) || any(arg -> arg === x, arguments(node))

            if has_source
                # Replace x with x₊ in both the operation and the arguments
                new_op = substitute_x(operation(node))
                new_args = map(substitute_x, arguments(node))

                # Reconstruct this function call at the target state
                return maketerm(typeof(node), new_op, new_args, nothing)
            end
        end

        # Leave leaf nodes and non-matching nodes unchanged for higher-level passes
        return node
    end

    if expr₊ !== expr
        return t ∧ (expr → setmetadata(expr₊, ID, nothing))
    else
        return t
    end
end

function propagate_transitions(props::Node{Conjunction}, node::Node)
    mapreduce(
        trans -> propagate_transition(trans, node),
        ∧,
        arguments(transitions(props))
    )
end

propagate_transitions(t::Node{Transition}, node::Node) = propagate_transition(t, node)



function add_constraint(opt::Node{T}, con::Node{<:Prop}) where {T<:Optimization}
    Term{T}(operation(opt), [objective(opt), constraint(opt) ∧ con])
end

function add_constraint(opt::Node{T}, con::Node{<:Prop}) where {T<:Feasibility}
    Term{T}(operation(opt), [constraint(opt) ∧ con])
end

function add_constraint(opt::Node{LyapunovCertificate}, new_con::Node{<:Prop})
    con, perf, rate = arguments(opt)
    op = operation(opt)
    Term{LyapunovCertificate}(op, [con ∧ new_con, perf, rate])
end


function remove_constraint(opt::Node{LyapunovCertificate}, old_con::Node{<:Prop})
    con, perf, rate = arguments(opt)
    op = operation(opt)
    if symtype(con) <: Conjunction
        cons = collect(arguments(con))
        filter!(c -> !isequal(old_con, c), cons)
        cons = foldl(∧, cons)
    else
        cons = con
    end
    Term{LyapunovCertificate}(op, [cons, perf, rate])
end

function remove_constraint(opt::Node{LyapunovCertificate}, old_con::Node{Conjunction})
    for con ∈ arguments(old_con)
        opt = remove_constraint(opt, con)
    end
    return opt
end

function replace_constraint(opt::Node{LyapunovCertificate}, old::Node{<:Prop}, new::Node{<:Prop})
    add_constraint(remove_constraint(opt, old), new)
end
