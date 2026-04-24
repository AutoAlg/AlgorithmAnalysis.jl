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

function _walk_dependencies!(expression_identifier::ExpressionID, algorithm_context::AlgorithmContext, reachable_expressions::Set{ExpressionID})::Nothing
    if expression_identifier in reachable_expressions
        return nothing
    end
    
    push!(reachable_expressions, expression_identifier)
    
    for dependency_identifier in dependencies(algorithm_context._expressions[expression_identifier])
        _walk_dependencies!(dependency_identifier, algorithm_context, reachable_expressions)
    end
    
    return nothing
end

function compute_reachable_expressions(algorithm_context::AlgorithmContext)::Set{ExpressionID}
    reachable_expressions::Set{ExpressionID} = Set{ExpressionID}()
    
    for (expression_identifier, abstract_expression) in algorithm_context._expressions
        is_explicitly_named::Bool = haskey(algorithm_context._expression_names, expression_identifier) # TODO: this works, but I'm not sure it's entierly correct
        is_terminal_transition::Bool = abstract_expression isa StateTransition # TODO: make this more explicit
        
        if is_explicitly_named || is_terminal_transition
            _walk_dependencies!(expression_identifier, algorithm_context, reachable_expressions)
        end
    end
    
    return reachable_expressions
end

function eliminate_unreachable_expressions!(algorithm_context::AlgorithmContext)::Nothing
    if try_get_algorithm_context() !== nothing
        error("Compiler passes must be evaluated without an active ALGORITHM_CONTEXT.")
    end

    reachable_expressions::Set{ExpressionID} = compute_reachable_expressions(algorithm_context)
    all_tracked_identifiers::Vector{ExpressionID} = collect(keys(algorithm_context._expressions))
    
    for expression_identifier in all_tracked_identifiers
        if !(expression_identifier in reachable_expressions)
            delete!(algorithm_context._expressions, expression_identifier)
        end
    end
    
    return nothing
end

function eliminate_unreachable_expressions(source_context::AlgorithmContext)::AlgorithmContext
    cloned_context::AlgorithmContext = clone(source_context)
    eliminate_unreachable_expressions!(cloned_context)
    return cloned_context
end