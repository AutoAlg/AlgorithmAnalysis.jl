export ExpressionID, AlgorithmContext, is_bound_to, allocate_id!, register!, ensure_expressions_are_bound_to_current_context

const get_next_context_id = let id = Threads.Atomic{UInt32}(0)
    () -> Threads.atomic_add!(id, UInt32(1))
end

struct ExpressionID
    context_id::UInt32
    expression_id::UInt32
end

abstract type Expression end

mutable struct AlgorithmContext
    const context_id::UInt32
    next_expression_id::UInt32
    expressions::Dict{ExpressionID,Expression}
    expression_aliases::Dict{ExpressionID,String}

    AlgorithmContext() = new(get_next_context_id(), UInt32(0), Dict{ExpressionID, Expression}(), Dict{ExpressionID, String}())
    AlgorithmContext(context_id::UInt32, next_expression_id::UInt32, expressions::Dict{ExpressionID, Expression}, aliases::Dict{ExpressionID, String}) = new(context_id, next_expression_id, expressions, aliases)

end



const SCOPED_ALGORITHM_CONTEXT = Base.ScopedValues.ScopedValue{Union{AlgorithmContext,Nothing}}(nothing)
with_context(f, ctx::AlgorithmContext) = Base.ScopedValues.with(f, SCOPED_ALGORITHM_CONTEXT => ctx)
function get_algorithm_context()::AlgorithmContext
    maybe_algorithm_context = SCOPED_ALGORITHM_CONTEXT[]
    if isnothing(maybe_algorithm_context)
        error("Tried and failed to acquire an algorithm context")
    end

    return maybe_algorithm_context::AlgorithmContext
end

is_bound_to(id::ExpressionID, ctx::AlgorithmContext) = id.context_id == ctx.context_id

function allocate_id!(ctx::AlgorithmContext=get_algorithm_context())::ExpressionID
    id = ExpressionID(ctx.context_id, ctx.next_expression_id)
    ctx.next_expression_id += 1
    return id
end

function register!(e::E, ctx::AlgorithmContext=get_algorithm_context())::E where {E<:Expression}
    if haskey(ctx.expressions, e.id)
        error("Duplicate Insertion of $(e.id)")
    end

    ctx.expressions[e.id] = e
    return e
end

function ensure_expressions_are_bound_to_current_context(es::Expression...)
    ctx = get_algorithm_context()

    for e in es
        if !is_bound_to(e.id, ctx)
            error("Expression $(e) was not bound to current context!")
        end
    end
end


function set_alias!(e::E, alias::String, ctx::AlgorithmContext = get_algorithm_context()) where {E <: Expression}
    if !hasfield(E, :id)
        error("all subtypes of NewExpression must have a field id")
    end

    if haskey(ctx.expression_aliases, e.id)
        error("cannot doubly alias $(e.id). previous alias is $(ctx.expression_aliases[e.id]) and desired new alias is $(alias)")
    end

    if length(alias) == 0
        error("Don't assign a variable the alias of the empty string")
    end

    if alias[1] == '*'
        error("Variable aliases cannot start with an asterisk")
    end

    ctx.expression_aliases[e.id] = alias
end

try_get_alias(id::ExpressionID, ctx::AlgorithmContext = get_algorithm_context())::Union{String, Nothing} = get(ctx.expression_aliases, id, nothing)
