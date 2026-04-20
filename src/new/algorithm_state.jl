using Base.ScopedValues

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
end

is_bound_to(id::ExpressionID, ctx::AlgorithmContext)::Bool = id._state_id == ctx._state_id

Base.:(==)(a::NewExpression, b::NewExpression)::Bool = a.id == b.id
Base.hash(e::NewExpression, h::UInt)::UInt = hash(e.id, h)





const ALGORITHM_CONTEXT = ScopedValue{AlgorithmContext}()
get_algorithm_context()::AlgorithmContext = ALGORITHM_CONTEXT[]

function allocate_id(ctx::AlgorithmContext = get_algorithm_context())::ExpressionID
    id = ctx._next_valid_node_id

    ctx._next_valid_node_id += 1

    return ExpressionID(ctx._state_id, id)
end

is_bound_to_current_context(id::ExpressionID) = is_bound_to(id, get_algorithm_context())

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
