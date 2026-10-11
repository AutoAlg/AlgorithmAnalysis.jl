export is_random_gram_transformation_applicable, random_gram_transformation

is_random_gram_transformation_applicable(::Any) = false
function is_random_gram_transformation_applicable(node::Node{<:Optimization})
    all_var_nodes = find_nodes(x -> iscall(x) && operation(x) == Var, node)
    all_cov_nodes = find_nodes(x -> iscall(x) && operation(x) == Cov, node)
    all_expectation_nodes = find_nodes(x -> iscall(x) && operation(x) == E, node)


    if !isempty(all_var_nodes)
        return false
    end

    if isempty(union(all_cov_nodes, all_expectation_nodes))
        return false
    end


    for n in all_cov_nodes
        if !issym(arguments(n)[1]) || !issym(arguments(n)[2])
            return false
        end
    end

    for n in all_expectation_nodes
        if !issym(arguments(n)[1])
            return false
        end
    end

    return true
end

function random_gram_transformation(node::Node{<:Optimization})
    all_cov_nodes = find_nodes(x -> iscall(x) && operation(x) == Cov, node)
    # because of above, these are all leaf nodes

    if !isempty(all_cov_nodes)
        allRandomRs::Vector{Node{RandomR}} = collect(Iterators.flatmap(n -> [arguments(n)[1], arguments(n)[2]], all_cov_nodes))
        unique!(allRandomRs)

        # TODO: replace this with a proper E(x'*y) call, as that would prove the algebra
        # works generically
        gramMatrix = Sⁿ([ get_cov_leaf(x, y) for x in allRandomRs, y in allRandomRs ])

        node = add_constraint(node, gramMatrix ⪰ 0)
    end

    node = rewrite(node, [
        @rule(Cov(~X, ~Y) => get_cov_leaf(~X, ~Y) where (issym(~X) && issym(~Y))),
        @rule(E(~X) => mean_component(~X) where issym(~X)), # isleaf
    ])

    return node
end