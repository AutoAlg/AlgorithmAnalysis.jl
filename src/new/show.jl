import Base: show, print

const TRACE_COLUMN_WIDTHS = (id = 5, alias = 14, type = 50, ssa_labeled = 28, ssa_raw = 24)

function _try_derive_alias(identifier::ExpressionID, context::AlgorithmContext)::Union{String, Nothing}
    haskey(context._expression_aliases, identifier) && return context._expression_aliases[identifier]
    
    target_expression::NewExpression = context._expressions[identifier]
    expression_dependencies::Vector{ExpressionID} = dependencies(target_expression)
    
    isempty(expression_dependencies) && return nothing
    
    for dependency_identifier in expression_dependencies
        _try_derive_alias(dependency_identifier, context) === nothing && return nothing
    end
    
    return _ssa_printer(target_expression, context, true)
end

function _ssa_name(identifier::ExpressionID, context::AlgorithmContext, use_aliases::Bool)::String
    if use_aliases
        derived_alias::Union{String, Nothing} = _try_derive_alias(identifier, context)
        derived_alias !== nothing && return derived_alias
    end
    return "%$(identifier._node_id)"
end

_ssa_printer(variable::NewR, context::AlgorithmContext, use_aliases::Bool)::String = "NewR()"
_ssa_printer(variable::NewRⁿ, context::AlgorithmContext, use_aliases::Bool)::String = "NewRⁿ()"
_ssa_printer(oracle::SSCFunction, context::AlgorithmContext, use_aliases::Bool)::String = "SSC(m=$(oracle.m), L=$(oracle.L))"
_ssa_printer(gradient::SSCGradient, context::AlgorithmContext, use_aliases::Bool)::String = "SSCGradient($(_ssa_name(gradient.function_of, context, use_aliases)))"
_ssa_printer(transition::StateTransition, context::AlgorithmContext, use_aliases::Bool)::String = "$(_ssa_name(transition.current_id, context, use_aliases)) => $(_ssa_name(transition.next_id, context, use_aliases))"
_ssa_printer(evaluation::OracleEvaluation, context::AlgorithmContext, use_aliases::Bool)::String = "$(_ssa_name(evaluation.oracle_id, context, use_aliases))($(_ssa_name(evaluation.input_id, context, use_aliases)))"

function _ssa_printer(decomposition::LinearDecomposition, context::AlgorithmContext, use_aliases::Bool)::String
    isempty(decomposition.terms) && return "0"
    
    sorted_terms::Vector{Pair{ExpressionID, Float64}} = sort(collect(decomposition.terms), by = pair -> pair.first._node_id)
    formatted_parts::Vector{String} = String[]
    
    for (term_id, coefficient) in sorted_terms
        coefficient == 0.0 && continue
        term_ssa_name::String = _ssa_name(term_id, context, use_aliases)
        
        if isempty(formatted_parts)
            push!(formatted_parts, coefficient == 1.0 ? term_ssa_name : coefficient == -1.0 ? "-$(term_ssa_name)" : "$(coefficient) * $(term_ssa_name)")
        else
            operator::String = coefficient > 0.0 ? " + " : " - "
            absolute_coefficient::Float64 = abs(coefficient)
            push!(formatted_parts, operator * (absolute_coefficient == 1.0 ? term_ssa_name : "$(absolute_coefficient) * $(term_ssa_name)"))
        end
    end
    
    isempty(formatted_parts) && return "0"
    return join(formatted_parts)
end

function show(io::IO, expression::NewExpression)::Nothing
    context::Union{AlgorithmContext, Nothing} = try_get_algorithm_context()
    if context !== nothing
        print(io, _ssa_name(expression.id, context, true))
    else
        print(io, string(typeof(expression)))
    end
    return nothing
end

_clean_type_name(expression::NewExpression)::String = replace(string(typeof(expression)), r"^(?:[A-Za-z0-9_]+\.)+" => "")

function print_algorithm(io::IO, context::AlgorithmContext)::Nothing
    sorted_expressions::Vector{Pair{ExpressionID, NewExpression}} = sort(collect(context._expressions), by = pair -> pair.first._node_id)
    
    println(io, "\nCompiler Trace [State ID: $(context._state_id)]")
    total_trace_width::Int = sum(values(TRACE_COLUMN_WIDTHS)) + 9
    println(io, "─"^total_trace_width)
    
    print(io, 
        rpad("ID ", TRACE_COLUMN_WIDTHS.id), 
        rpad("Alias", TRACE_COLUMN_WIDTHS.alias), 
        rpad("Type", TRACE_COLUMN_WIDTHS.type), "| ",
        rpad("Labeled SSA", TRACE_COLUMN_WIDTHS.ssa_labeled - 2), "| ",
        "SSA\n"
    )
    println(io, "-"^total_trace_width)
    
    for (identifier, expression) in sorted_expressions
        is_explicit_alias::Bool = haskey(context._expression_aliases, identifier)
        derived_alias::Union{String, Nothing} = _try_derive_alias(identifier, context)
        
        alias_string::String = if is_explicit_alias
            derived_alias
        elseif derived_alias !== nothing
            "*" * derived_alias
        else
            "_"
        end
        
        type_string::String = _clean_type_name(expression)
        
        ssa_instruction_labeled::String = _ssa_printer(expression, context, true)
        ssa_instruction_raw::String = _ssa_printer(expression, context, false)
        
        left_side_labeled::String = "$(_ssa_name(identifier, context, true)) = $(ssa_instruction_labeled)"
        left_side_raw::String = "%$(identifier._node_id) = $(ssa_instruction_raw)"
        
        print(io, 
            rpad("%$(identifier._node_id)", TRACE_COLUMN_WIDTHS.id),
            rpad(alias_string, TRACE_COLUMN_WIDTHS.alias),
            rpad(type_string, TRACE_COLUMN_WIDTHS.type), "| ",
            rpad(left_side_labeled, TRACE_COLUMN_WIDTHS.ssa_labeled - 2), "| ",
            left_side_raw, "\n"
        )
    end
    println(io, "─"^total_trace_width, "\n")
    return nothing
end

print_algorithm(context::AlgorithmContext)::Nothing = print_algorithm(stdout, context)
show(io::IO, ::MIME"text/plain", context::AlgorithmContext)::Nothing = print_algorithm(io, context)
show(io::IO, context::AlgorithmContext)::Nothing = print_algorithm(io, context)
print(io::IO, context::AlgorithmContext)::Nothing = print_algorithm(io, context)