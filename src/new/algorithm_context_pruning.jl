function compute_forward_edges(algorithm_context::AlgorithmContext)::Dict{ExpressionID, Vector{ExpressionID}}
    forward_edges::Dict{ExpressionID, Vector{ExpressionID}} = Dict{ExpressionID, Vector{ExpressionID}}(
        expression_identifier => ExpressionID[] for expression_identifier in keys(algorithm_context._expressions)
    )
    
    for (expression_identifier, abstract_expression) in algorithm_context._expressions
        for dependency_identifier in dependencies(abstract_expression)
            push!(forward_edges[dependency_identifier], expression_identifier)
        end
    end
    
    return forward_edges
end

function _walk_dependencies!(expression_identifier::ExpressionID, algorithm_context::AlgorithmContext, reachable_node_identifiers::Set{UInt32})::Nothing
    node_identifier::UInt32 = expression_identifier._node_id
    
    if node_identifier in reachable_node_identifiers
        return nothing
    end
    
    push!(reachable_node_identifiers, node_identifier)
    
    for dependency_identifier in dependencies(algorithm_context._expressions[expression_identifier])
        _walk_dependencies!(dependency_identifier, algorithm_context, reachable_node_identifiers)
    end
    
    return nothing
end

function compute_reachable_node_identifiers(algorithm_context::AlgorithmContext, root_expressions::Vector{ExpressionID})::Set{UInt32}
    reachable_node_identifiers::Set{UInt32} = Set{UInt32}()
    
    for root_identifier in root_expressions
        if !haskey(algorithm_context._expressions, root_identifier)
            error("provided root expression is not tracked within the given algorithm context")
        end
        
        _walk_dependencies!(root_identifier, algorithm_context, reachable_node_identifiers)
    end
    
    return reachable_node_identifiers
end

function extract_reachable_subgraph!(algorithm_context::AlgorithmContext, reachable_node_identifiers::Set{UInt32})::Nothing
    if try_get_algorithm_context() !== nothing
        error("compiler passes must be evaluated without an active context")
    end

    all_tracked_identifiers::Vector{ExpressionID} = collect(keys(algorithm_context._expressions))
    
    for expression_identifier in all_tracked_identifiers
        if !(expression_identifier._node_id in reachable_node_identifiers)
            delete!(algorithm_context._expressions, expression_identifier)
            delete!(algorithm_context._expression_aliases, expression_identifier)
        end
    end
    
    return nothing
end

function eliminate_unreachable_expressions(source_context::AlgorithmContext, root_expressions::Vector{ExpressionID})::AlgorithmContext
    reachable_node_identifiers::Set{UInt32} = compute_reachable_node_identifiers(source_context, root_expressions)
    
    cloned_context::AlgorithmContext = clone(source_context)
    extract_reachable_subgraph!(cloned_context, reachable_node_identifiers)
    
    return cloned_context
end

function eliminate_unreachable_expressions(source_context::AlgorithmContext, root_expressions::Vector{<:NewExpression})::AlgorithmContext
    root_identifiers::Vector{ExpressionID} = ExpressionID[abstract_expression.id for abstract_expression in root_expressions]
    return eliminate_unreachable_expressions(source_context, root_identifiers)
end