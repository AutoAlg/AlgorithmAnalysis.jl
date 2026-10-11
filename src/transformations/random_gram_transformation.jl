export is_random_gram_transformation_applicable, random_gram_transformation

is_random_gram_transformation_applicable(::Any) = false
function is_random_gram_transformation_applicable(node::Node{<:Optimization})
    if !isempty(find_nodes(x -> iscall(x) && operation(x) == Var, node))
        return false
    end

    all_cov_nodes = find_nodes(x -> iscall(x) && operation(x) == Cov, node)

    for n in all_cov_nodes
        if !issym(arguments(n)[1]) || !issym(arguments(n)[2])
            return false
        end
    end

    if !isempty(all_cov_nodes)
        return true
    else
        return false
    end
end

function random_gram_transformation(node::Node{<:Optimization})
    all_cov_nodes = find_nodes(x -> iscall(x) && operation(x) == Cov, node)
    # because of above, these are all leaf nodes

    allRandomRs::Vector{Node{RandomR}} = collect(Iterators.flatmap(n -> [arguments(n)[1], arguments(n)[2]], all_cov_nodes))
    unique!(allRandomRs)

    # TODO: replace this with a proper E(x'*y) call, as that would prove the algebra
    # works generically
    gramMatrix = Sⁿ([ get_cov_leaf(x, y) for x in allRandomRs, y in allRandomRs ])

    node = add_constraint(node, gramMatrix ⪰ 0)

    node = rewrite(node, [@rule(Cov(~X, ~Y) => get_cov_leaf(~X, ~Y) where (issym(~X) && issym(~Y)))])

    return node
end