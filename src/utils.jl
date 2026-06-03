export find_nodes, replace_nodes, flatten_evaluations
export rewrite, find_evaluation_points

function postwalk_with_operators(f, x)
    if istree(x)
        new_op = postwalk_with_operators(f, operation(x))
        new_args = map(arg -> postwalk_with_operators(f, arg), arguments(x))
        T = symtype(x)
        return f(Term{T}(new_op, new_args))
    else
        return f(x)
    end
end

"""
    rewrite(tree, rules)
"""
rewrite(tree, rules) = postwalk_with_operators(Chain(rules), tree)

"""
    find_nodes(predicate::Function, tree) -> Vector

Recursively scans a SymbolicUtils AST or algebraic expression. Returns a flat vector 
containing every sub-tree, terminal node, or variable that satisfies `predicate(node)`.
"""
function find_nodes(predicate::Function, node, results::Set = Set())
    if predicate(node)
        push!(results, node)
    end
    if !istree(node)
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
function replace_node(tree, old_node, new_node)
    swap_rule = @rule( ~x => new_node where (~x === old_node) )
    return rewrite(tree, [swap_rule])
end

function flatten_evaluations(tree, f::BasicSymbolic)

    T = symtype(f).parameters[2]
    iseval(x) = istree(x) && operation(x) === f
    newsym(x) = begin
        arg = arguments(x)[1]
        sym = istree(arg) ? Symbol(f, "_(", arg, ")") : Symbol(f, "_", arg)
        setmetadata(Sym{T}(sym), ID, sym)
    end
    
    rule = @rule( ~x => newsym(~x) where iseval(~x) )
    return rewrite(tree, [rule])
end

function flatten_evaluations(tree, fs::Vector{BasicSymbolic})
    new_tree = deepcopy(tree)
    for f ∈ fs
        new_tree = flatten_evaluations(new_tree, f)
    end
    return new_tree
end

"""
    find_evaluation_points!(node, state::ExtendedProblemAnalysisState)

Recursively crawls your optimization tree. It safely matches standard function calls 
and looks inside applied adjoint operators to capture gradient evaluation points.
"""
function find_evaluation_points(f, node)
    evals = find_nodes(x -> istree(x) && operation(x) === f, node)
    map(x -> arguments(x)[1], collect(evals))
end
