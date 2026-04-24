using Base.ScopedValues
import Base: deepcopy_internal

const get_global_state_id = let id = Threads.Atomic{UInt32}(0)
    () -> Threads.atomic_add!(id, UInt32(1))
end




struct ExpressionID
    _state_id::UInt32
    _node_id::UInt32
end

abstract type NewExpression end

mutable struct AlgorithmContext
    const _state_id::UInt32    
    _next_valid_node_id::UInt32

    _expressions::Dict{ExpressionID, NewExpression}
    _expression_names::Dict{ExpressionID, String}

    AlgorithmContext() = new(get_global_state_id(), UInt32(0), Dict{ExpressionID, NewExpression}(), Dict{ExpressionID, String}())
    AlgorithmContext(state_id::UInt32, next_id::UInt32, expressions::Dict{ExpressionID, NewExpression}, names::Dict{ExpressionID, String}) = new(state_id, next_id, expressions, names)
end


is_bound_to(id::ExpressionID, ctx::AlgorithmContext)::Bool = id._state_id == ctx._state_id

Base.:(==)(a::NewExpression, b::NewExpression)::Bool = a.id == b.id
Base.hash(e::NewExpression, h::UInt)::UInt = hash(e.id, h)



const ALGORITHM_CONTEXT = ScopedValue{Union{AlgorithmContext, Nothing}}(nothing)

function try_get_algorithm_context()::Union{AlgorithmContext, Nothing}
    return ALGORITHM_CONTEXT[]
end

function get_algorithm_context()::AlgorithmContext
    algorithm_context::Union{AlgorithmContext, Nothing} = try_get_algorithm_context()
    if algorithm_context === nothing
        error("No active AlgorithmContext. Evaluation must occur within a `with_context(ctx)` block.")
    end
    return algorithm_context
end

function with_context(execution_block::Function, target_context::AlgorithmContext)
    return with(execution_block, ALGORITHM_CONTEXT => target_context)
end


function allocate_id(ctx::AlgorithmContext = get_algorithm_context())::ExpressionID
    id = ctx._next_valid_node_id

    ctx._next_valid_node_id += 1

    return ExpressionID(ctx._state_id, id)
end

function ensure_expressions_are_bound_to_current_context(expressions::NewExpression...)::Nothing
    active_context::AlgorithmContext = get_algorithm_context()
    for abstract_expression in expressions
        if !is_bound_to(abstract_expression.id, active_context)
            error("Cross-state validation failed. Node $(abstract_expression.id) is not bound to the active context.")
        end
    end
    return nothing
end


function register!(expr::E, ctx::AlgorithmContext = get_algorithm_context())::E where {E <: NewExpression}
    if !hasfield(E, :id)
        error("All subtypes of NewExpression must have a field id!")
    end

    if haskey(ctx._expressions, expr.id)
        error("Cannot doubly insert $(expr.id)")
    end

    ctx._expressions[expr.id] = expr

    return expr
end

function set_name!(expr::E, name::String, ctx::AlgorithmContext = get_algorithm_context())::Nothing where {E <: NewExpression}
    if !hasfield(E, :id)
        error("All subtypes of NewExpression must have a field id!")
    end

    if haskey(ctx._expression_names, expr.id)
        error("Cannot doubly name $(expr.id) | Previous name is $(ctx._expression_names[expr.id]) and desired new name is $(name)")
    end

    ctx._expression_names[expr.id] = name

    return nothing
end

try_get_name(id::ExpressionID, ctx::AlgorithmContext = get_algorithm_context())::Union{String, Nothing} = get(ctx._expression_names, id, nothing)




# TODO: i'm not happy with this, this should really be an explicit interface and require the use of an extra inner constructor.

deepcopy_internal(::AlgorithmContext, ::IdDict) = error("A deepcopy of an AlgorithmContext is unpresentable and erroneous, you probably want to use `clone` instead.")

function _deep_translate_ids(identifier::ExpressionID, target_state_id::UInt32)::ExpressionID
    return ExpressionID(target_state_id, identifier._node_id)
end

function _deep_translate_ids(value::Any, target_state_id::UInt32)::Any
    value_type::DataType = typeof(value)
    
    if isprimitivetype(value_type) || value_type === String || value_type === Symbol
        return value
    end

    if value isa Array
        return value_type([_deep_translate_ids(element, target_state_id) for element in value])
    end

    if value isa Dict
        translated_dictionary = value_type()
        for (dictionary_key, dictionary_value) in value
            translated_dictionary[_deep_translate_ids(dictionary_key, target_state_id)] = _deep_translate_ids(dictionary_value, target_state_id)
        end
        return translated_dictionary
    end

    field_count::Int = fieldcount(value_type)
    if field_count == 0
        return value
    end

    reconstructed_fields::Vector{Any} = Vector{Any}(undef, field_count)
    for field_index in 1:field_count
        reconstructed_fields[field_index] = _deep_translate_ids(getfield(value, field_index), target_state_id)
    end

    return value_type(reconstructed_fields...)
end

function clone(source_context::AlgorithmContext)::AlgorithmContext
    if ALGORITHM_CONTEXT[] !== nothing
        error("don't call clone with an active context.")
    end

    target_state_id::UInt32 = get_global_state_id()
    target_next_node_id::UInt32 = source_context._next_valid_node_id
    
    target_expressions::Dict{ExpressionID, NewExpression} = Dict{ExpressionID, NewExpression}()
    target_names::Dict{ExpressionID, String} = Dict{ExpressionID, String}()
    
    for (source_identifier, abstract_expression) in source_context._expressions
        target_identifier::ExpressionID = _deep_translate_ids(source_identifier, target_state_id)
        target_expressions[target_identifier] = _deep_translate_ids(abstract_expression, target_state_id)
    end
    
    for (source_identifier, expression_name) in source_context._expression_names
        target_identifier::ExpressionID = _deep_translate_ids(source_identifier, target_state_id)
        target_names[target_identifier] = expression_name
    end
    
    return AlgorithmContext(target_state_id, target_next_node_id, target_expressions, target_names)
end