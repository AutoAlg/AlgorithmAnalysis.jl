export postwalk_with_operators, rewrite, find_nodes, replace_node
export find_evaluation_points, leaves

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

"""
    find_evaluation_points!(node, state::ExtendedProblemAnalysisState)

Recursively crawls your optimization tree. It safely matches standard function calls 
and looks inside applied adjoint operators to capture gradient evaluation points.
"""
function find_evaluation_points(f::Node, node::Node)
    evals = find_nodes(x -> iscall(x) && isequal(operation(x), f), node)
    map(x -> arguments(x)[1], collect(evals))
end

"""
    leaves(v::Node)

Recursively collects all AST leaf nodes (nodes where `iscall(v)` is false) from an expression tree.
Returns a `Set` of unique leaf nodes.
"""
function leaves(node::Node, nodes::Set = Set{Node}())
    if !iscall(node)
        push!(nodes, node)
        return nodes
    end
    for arg in arguments(node)
        leaves(arg, nodes)
    end
    return nodes
end

leaves(::Any, nodes::Set) = nodes
