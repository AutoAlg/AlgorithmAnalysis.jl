export leaves

"""
    postwalk_with_operators(f, x)

Apply a postwalk to the symbolic expression `x` in which the function `f` is applied recursively directly to leaf nodes and to both the operator and arguments of `iscall` nodes, starting at the leaves. This is similar to [SymbolicUtils.Rewriters.Postwalk](https://docs.sciml.ai/SymbolicUtils/v4.37/api/#SymbolicUtils.Rewriters) except that the function is also applied to the operator for `iscall` nodes, as these may also be symbolic expressions.
"""
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

Rewrites a node using the given rules. See [`postwalk_with_operators`](@ref).
"""
rewrite(node::Node, rules) = postwalk_with_operators(SymbolicUtils.Rewriters.Chain(rules), node)

"""
    find_nodes(predicate, tree)

Recursively searches a symbolic AST. Returns a vector containing every node that satisfies `predicate(node)`.
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
    find_evaluation_points!(f, node)

Finds all evaluations of the function `f` in the symbolic node.
"""
function find_evaluation_points(f::Node, node::Node)
    evals = find_nodes(x -> iscall(x) && isequal(operation(x), f), node)
    map(x -> arguments(x)[1], collect(evals))
end

"""
    leaves(node)

Recursively collects all AST leaf nodes (nodes where `iscall(v)` is false) from an expression tree. Returns a `Set` of unique leaf nodes.
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
