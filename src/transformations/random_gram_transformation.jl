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

# TODO: is there any reason this can't be unified with the regular gram transformation?
function random_gram_transformation(node::Node{<:Optimization})
    
    # because of the guard, these are all leaf nodes
    all_Rcov_nodes = find_nodes(x -> iscall(x) && operation(x) == Cov && arguments(x)[1] isa Node{RandomR}, node)
    all_Rⁿcov_nodes = find_nodes(x -> iscall(x) && operation(x) == Cov && arguments(x)[1] isa Node{RandomRⁿ}, node)

    node = rewrite(node, [
        @rule(Cov(~X, ~Y) => E(centered_component(~X)'*centered_component(~Y)) where (issym(~X) && issym(~Y)))
    ])

    if !isempty(all_Rcov_nodes)
        allRandomRs::Vector{Node{RandomR}} = collect(Iterators.flatmap(n -> [arguments(n)[1], arguments(n)[2]], all_Rcov_nodes))
        unique!(allRandomRs)

        allCenteredRandomRs::Vector{Node{RandomRCenteredComponent}} = map(x -> centered_component(x), allRandomRs)

        gramMatrix = Sⁿ([E(x'*y) for x in allCenteredRandomRs, y in allCenteredRandomRs ])

        node = add_constraint(node, gramMatrix ⪰ 0)
    end


    if !isempty(all_Rⁿcov_nodes)
        allRandomRⁿs::Vector{Node{RandomRⁿ}} = collect(Iterators.flatmap(n -> [arguments(n)[1], arguments(n)[2]], all_Rⁿcov_nodes))
        unique!(allRandomRⁿs)

        allCenteredRandomRⁿs::Vector{Node{RandomRⁿCenteredComponent}} = map(x -> centered_component(x), allRandomRⁿs)

        gramMatrix = Sⁿ([E(x'*y) for x in allCenteredRandomRⁿs, y in allCenteredRandomRⁿs ])

        node = add_constraint(node, gramMatrix ⪰ 0)
    end




    is_centered_leaf(x) = issym(x) && (symtype(x) <: RandomRCenteredComponent || symtype(x) <: RandomRCenteredComponent)

    node = rewrite(node, [
        # By construction, this rule should only match on ~X and ~Y where is_centered_leaf is true
        # if that doesn't happen, you're representing something uncomputable in jump
        @rule(E(~X * ~Y) => centered_product_leaf(~X, ~Y)), # where (is_centered_leaf(~a) && is_centered_leaf(~b)))
        @rule(E(~X ⋅ ~Y) => centered_product_leaf(~X, ~Y)),
        @rule(E(~X) => mean_component(~X) where issym(~X)), # isleaf
    ])

    return node
end