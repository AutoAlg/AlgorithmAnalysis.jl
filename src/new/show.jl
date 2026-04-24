import Base: show

function _format_nested(io::IO, abstract_expression::NewExpression, algorithm_context::Union{AlgorithmContext, Nothing})::Nothing
    if algorithm_context !== nothing
        expression_name::Union{String, Nothing} = get(algorithm_context._expression_names, abstract_expression.id, nothing)
        if expression_name !== nothing
            print(io, expression_name)
            return nothing
        end
    end
    _show_structural(io, abstract_expression, algorithm_context)
    return nothing
end


function show(io::IO, abstract_expression::NewExpression)::Nothing
    _format_nested(io, abstract_expression, ALGORITHM_CONTEXT[])
    return nothing
end

_show_structural(io::IO, real_variable::NewR, ctx::Union{AlgorithmContext, Nothing})::Nothing = (print(io, "R_$(real_variable.id._node_id)"); nothing)
_show_structural(io::IO, vector_variable::NewRⁿ, ctx::Union{AlgorithmContext, Nothing})::Nothing = (print(io, "Rⁿ_$(vector_variable.id._node_id)"); nothing)
_show_structural(io::IO, ssc_function::SSCFunction, ctx::Union{AlgorithmContext, Nothing})::Nothing = (print(io, "SSC_$(ssc_function.id._node_id)(m=$(ssc_function.m), L=$(ssc_function.L))"); nothing)
_show_structural(io::IO, ssc_gradient::SSCGradient, ctx::Union{AlgorithmContext, Nothing})::Nothing = (print(io, "∇SSC_$(ssc_gradient.function_of._node_id)"); nothing)

function _show_structural(io::IO, evaluated_gradient::SSCGradientOf, ctx::Union{AlgorithmContext, Nothing})::Nothing
    if ctx === nothing
        print(io, "Oracle_$(evaluated_gradient.∇_id._node_id)(x_$(evaluated_gradient.x_id._node_id))")
        return nothing
    end
    
    _format_nested(io, ctx._expressions[evaluated_gradient.∇_id], ctx)
    print(io, "(")
    _format_nested(io, ctx._expressions[evaluated_gradient.x_id], ctx)
    print(io, ")")
    return nothing
end

function _format_identifier_reference(io::IO, expression_identifier::ExpressionID, ctx::Union{AlgorithmContext, Nothing})::Nothing
    if ctx === nothing || !haskey(ctx._expressions, expression_identifier)
        print(io, "ID_$(expression_identifier._node_id)")
        return nothing
    end
    _format_nested(io, ctx._expressions[expression_identifier], ctx)
    return nothing
end

function _show_structural(io::IO, linear_decomposition::LinearDecomposition, ctx::Union{AlgorithmContext, Nothing})::Nothing
    if isempty(linear_decomposition.terms)
        print(io, "0")
        return nothing
    end

    sorted_decomposition_terms::Vector{Pair{ExpressionID, Float64}} = sort(collect(linear_decomposition.terms), by = term_pair -> term_pair.first._node_id)
    
    is_first_term::Bool = true
    for (expression_identifier, coefficient_value) in sorted_decomposition_terms
        if coefficient_value == 0.0
            continue
        end

        if is_first_term
            if coefficient_value == 1.0
                _format_identifier_reference(io, expression_identifier, ctx)
            elseif coefficient_value == -1.0
                print(io, "-")
                _format_identifier_reference(io, expression_identifier, ctx)
            else
                print(io, coefficient_value, " * ")
                _format_identifier_reference(io, expression_identifier, ctx)
            end
            is_first_term = false
        else
            if coefficient_value == 1.0
                print(io, " + ")
                _format_identifier_reference(io, expression_identifier, ctx)
            elseif coefficient_value == -1.0
                print(io, " - ")
                _format_identifier_reference(io, expression_identifier, ctx)
            elseif coefficient_value > 0.0
                print(io, " + ", coefficient_value, " * ")
                _format_identifier_reference(io, expression_identifier, ctx)
            else
                print(io, " - ", -coefficient_value, " * ")
                _format_identifier_reference(io, expression_identifier, ctx)
            end
        end
    end
    
    if is_first_term
        print(io, "0")
    end
    return nothing
end

function _show_structural(io::IO, state_transition::StateTransition, ctx::Union{AlgorithmContext, Nothing})::Nothing
    if ctx === nothing
        print(io, "StateTransition($(state_transition.current_id._node_id) => $(state_transition.next_id._node_id))")
        return nothing
    end
    
    _format_nested(io, ctx._expressions[state_transition.current_id], ctx)
    print(io, " => ")
    _format_nested(io, ctx._expressions[state_transition.next_id], ctx)
    return nothing
end

function _clean_type_name(abstract_expression::NewExpression)::String
    raw_type_string::String = string(typeof(abstract_expression))
    raw_type_string = replace(raw_type_string, "{RealSpace}" => "")
    raw_type_string = replace(raw_type_string, "{RealVectorSpace}" => "")
    raw_type_string = replace(raw_type_string, r"Main\..*\." => "") 
    return raw_type_string
end

function _format_identifier_array(identifier_array::Vector{UInt32})::String
    isempty(identifier_array) && return "[]"
    return "[" * join(Int.(sort(identifier_array)), ", ") * "]"
end

function print_algorithm(io::IO, algorithm_context::AlgorithmContext)::Nothing
    sorted_expressions::Vector{Pair{ExpressionID, NewExpression}} = sort(collect(algorithm_context._expressions), by = expression_pair -> expression_pair.first._node_id)
    
    forward_edges::Dict{ExpressionID, Vector{ExpressionID}} = compute_forward_edges(algorithm_context)
    
    println(io, "Algorithm State")
    println(io, "────────────────────────────────────────────────────────────────────────────")
    
    oracle_strings::Vector{String} = String[]
    variable_strings::Vector{String} = String[]
    transition_strings::Vector{String} = String[]
    
    for (expression_identifier, abstract_expression) in sorted_expressions
        expression_name::Union{String, Nothing} = get(algorithm_context._expression_names, expression_identifier, nothing)
        display_name::String = expression_name === nothing ? "v$(expression_identifier._node_id)" : expression_name
        structure_string::String = sprint((io_stream, expression_node) -> _show_structural(io_stream, expression_node, algorithm_context), abstract_expression)
        
        if abstract_expression isa NewOracle
            push!(oracle_strings, "  $(rpad(display_name, 6)) = $structure_string")
        elseif abstract_expression isa StateTransition
            push!(transition_strings, "  $(rpad(display_name, 6)) : $structure_string")
        elseif abstract_expression isa NewR || abstract_expression isa NewRⁿ
            space_symbol::String = abstract_expression isa NewRⁿ ? "Rⁿ" : "R"
            push!(variable_strings, "  $(rpad(display_name, 6)) ∈ $space_symbol")
        else
            if expression_name === nothing
                continue
            end
            push!(variable_strings, "  $(rpad(display_name, 6)) = $structure_string")
        end
    end
    
    if !isempty(oracle_strings)
        println(io, "Oracles:\n", join(oracle_strings, "\n"))
        println(io)
    end
    if !isempty(variable_strings)
        println(io, "Variables:\n", join(variable_strings, "\n"))
        println(io)
    end
    if !isempty(transition_strings)
        println(io, "Transitions:\n", join(transition_strings, "\n"))
        println(io)
    end

    println(io, "Compiler Trace")
    println(io, "─────────────────────────────────────────────────────────────────────────────────────────")
    println(io, rpad("[ID]", 6), rpad("Name", 8), rpad("Type", 22), rpad("Depends On", 16), rpad("Used By", 16), "Structure")
    println(io, "-"^89)
    
    for (expression_identifier, abstract_expression) in sorted_expressions
        expression_name_trace::String = get(algorithm_context._expression_names, expression_identifier, "_")
        clean_type_string::String = _clean_type_name(abstract_expression)
        trace_structure_string::String = sprint((io_stream, expression_node) -> _show_structural(io_stream, expression_node, algorithm_context), abstract_expression)
        
        dependency_identifiers::Vector{UInt32} = UInt32[dependency_node._node_id for dependency_node in dependencies(abstract_expression)]
        depends_on_formatted::String = _format_identifier_array(dependency_identifiers)
        
        used_by_identifiers::Vector{UInt32} = UInt32[dependent_node._node_id for dependent_node in forward_edges[expression_identifier]]
        used_by_formatted::String = _format_identifier_array(used_by_identifiers)
        
        identifier_string::String = lpad(string(expression_identifier._node_id), 2)
        
        print(io, "[", identifier_string, "]  ")
        print(io, rpad(expression_name_trace, 8))
        print(io, rpad(clean_type_string, 20), "| ")
        print(io, rpad(depends_on_formatted, 14), "| ")
        print(io, rpad(used_by_formatted, 14), "| ")
        println(io, trace_structure_string)
    end
    return nothing
end

print_algorithm(algorithm_context::AlgorithmContext)::Nothing = print_algorithm(stdout, algorithm_context)
show(io::IO, ::MIME"text/plain", algorithm_context::AlgorithmContext)::Nothing = print_algorithm(io, algorithm_context)
show(io::IO, algorithm_context::AlgorithmContext)::Nothing = print_algorithm(io, algorithm_context)