import Base: show

const TRACE_COLUMN_WIDTHS = (id = 6, name = 12, type = 37, depends_on = 16, used_by = 16)

_name_of(identifier::ExpressionID, context::AlgorithmContext)::String = get(context._expression_names, identifier, "Unnamed Variable @ $(identifier._node_id)")

# TODO: I'm not a fan of how this is separate...
_format_structure(variable::NewR, context::AlgorithmContext)::String = "NewR()"
_format_structure(variable::NewRⁿ, context::AlgorithmContext)::String = "NewRⁿ()"
_format_structure(oracle::SSCFunction, context::AlgorithmContext)::String = "SSC(m=$(oracle.m), L=$(oracle.L))"
_format_structure(gradient::SSCGradient, context::AlgorithmContext)::String = "SSCGradient($(_name_of(gradient.function_of, context)))"
_format_structure(evaluation::SSCGradientOf, context::AlgorithmContext)::String = "$(_name_of(evaluation.∇_id, context))($(_name_of(evaluation.x_id, context)))"
_format_structure(transition::StateTransition, context::AlgorithmContext)::String = "$(_name_of(transition.current_id, context)) => $(_name_of(transition.next_id, context))"

function _format_structure(decomposition::LinearDecomposition, context::AlgorithmContext)::String
    isempty(decomposition.terms) && return "0"
    
    sorted_terms::Vector{Pair{ExpressionID, Float64}} = sort(collect(decomposition.terms), by = pair -> pair.first._node_id)
    formatted_parts::Vector{String} = String[]
    
    for (term_id, coefficient) in sorted_terms
        coefficient == 0.0 && continue
        term_name::String = _name_of(term_id, context)
        
        if isempty(formatted_parts)
            push!(formatted_parts, coefficient == 1.0 ? term_name : coefficient == -1.0 ? "-$(term_name)" : "$(coefficient) * $(term_name)")
        else
            operator::String = coefficient > 0.0 ? " + " : " - "
            absolute_coefficient::Float64 = abs(coefficient)
            push!(formatted_parts, operator * (absolute_coefficient == 1.0 ? term_name : "$(absolute_coefficient) * $(term_name)"))
        end
    end
    
    isempty(formatted_parts) && return "0"
    return join(formatted_parts)
end

function show(io::IO, expression::NewExpression)::Nothing
    context::Union{AlgorithmContext, Nothing} = try_get_algorithm_context()
    if context !== nothing && haskey(context._expression_names, expression.id)
        print(io, context._expression_names[expression.id])
    else
        print(io, context === nothing ? string(typeof(expression)) : _format_structure(expression, context))
    end
    return nothing
end

_clean_type_name(expression::NewExpression)::String = replace(string(typeof(expression)), r"^(?:[A-Za-z0-9_]+\.)+" => "")
_format_identifier_array(identifiers::Vector{UInt32})::String = isempty(identifiers) ? "[]" : "[" * join(sort(Int.(identifiers)), ", ") * "]"

function print_algorithm(io::IO, context::AlgorithmContext)::Nothing
    sorted_expressions::Vector{Pair{ExpressionID, NewExpression}} = sort(collect(context._expressions), by = pair -> pair.first._node_id)
    forward_edges::Dict{ExpressionID, Vector{ExpressionID}} = compute_forward_edges(context)
    
    println(io, "Algorithm State")
    println(io, "─"^99)
    
    oracle_strings::Vector{String} = String[]
    variable_strings::Vector{String} = String[]
    transition_strings::Vector{String} = String[]
    
    for (identifier, expression) in sorted_expressions
        display_name::String = _name_of(identifier, context)
        structure_string::String = _format_structure(expression, context)
        
        if expression isa NewOracle
            push!(oracle_strings, "  $(rpad(display_name, 10)) = $(structure_string)")
        elseif expression isa StateTransition
            push!(transition_strings, "  $(rpad(display_name, 10)) : $(structure_string)")
        elseif expression isa NewR || expression isa NewRⁿ
            space_symbol::String = expression isa NewRⁿ ? "Rⁿ" : "R"
            push!(variable_strings, "  $(rpad(display_name, 10)) ∈ $(space_symbol)")
        else
            haskey(context._expression_names, identifier) && push!(variable_strings, "  $(rpad(display_name, 10)) = $(structure_string)")
        end
    end
    
    !isempty(oracle_strings) && println(io, "Oracles:\n", join(oracle_strings, "\n"), "\n")
    !isempty(variable_strings) && println(io, "Variables:\n", join(variable_strings, "\n"), "\n")
    !isempty(transition_strings) && println(io, "Transitions:\n", join(transition_strings, "\n"), "\n")

    println(io, "Compiler Trace")
    total_trace_width::Int = sum(values(TRACE_COLUMN_WIDTHS)) + 12
    println(io, "─"^total_trace_width)
    
    print(io, 
        rpad("[ID]", TRACE_COLUMN_WIDTHS.id), 
        rpad("Name", TRACE_COLUMN_WIDTHS.name), 
        rpad("Type", TRACE_COLUMN_WIDTHS.type), "| ",
        rpad("Depends On", TRACE_COLUMN_WIDTHS.depends_on - 2), "| ",
        rpad("Used By", TRACE_COLUMN_WIDTHS.used_by - 2), "| ",
        "Structure\n"
    )
    println(io, "-"^total_trace_width)
    
    for (identifier, expression) in sorted_expressions
        trace_name::String = get(context._expression_names, identifier, "_")
        type_string::String = _clean_type_name(expression)
        structure_string::String = _format_structure(expression, context)
        
        dependency_identifiers::Vector{UInt32} = UInt32[dependency_node._node_id for dependency_node in dependencies(expression)]
        used_by_identifiers::Vector{UInt32} = UInt32[dependent_node._node_id for dependent_node in forward_edges[identifier]]
        
        print(io, 
            rpad("[$(identifier._node_id)]", TRACE_COLUMN_WIDTHS.id),
            rpad(trace_name, TRACE_COLUMN_WIDTHS.name),
            rpad(type_string, TRACE_COLUMN_WIDTHS.type), "| ",
            rpad(_format_identifier_array(dependency_identifiers), TRACE_COLUMN_WIDTHS.depends_on - 2), "| ",
            rpad(_format_identifier_array(used_by_identifiers), TRACE_COLUMN_WIDTHS.used_by - 2), "| ",
            structure_string, "\n"
        )
    end
    return nothing
end

print_algorithm(context::AlgorithmContext)::Nothing = print_algorithm(stdout, context)
show(io::IO, ::MIME"text/plain", context::AlgorithmContext)::Nothing = print_algorithm(io, context)
show(io::IO, context::AlgorithmContext)::Nothing = print_algorithm(io, context)