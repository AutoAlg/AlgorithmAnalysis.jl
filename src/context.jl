export ExpressionID, AlgorithmContext, is_bound_to, allocate_id!, register!, ensure_expressions_are_bound_to_current_context

struct ExpressionID
    context_id::Uint32
    expression_id::Uint32
end

abstract type Expression end

mutable struct AlgorithmContext
    const context_id::Uint32
    next_expression_id::Uint32
    expressions::Dict{ExpressionID,Expression}
    expression_aliases::Dict{ExpressionID,String}
end

const SCOPED_ALGORITHM_CONTEXT = Base.ScopedValues{Union{AlgorithmContext,Nothing}}(nothing)
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
    if haskey(ctx.expressions, e.expression_id)
        error("Duplicate Insertion of $(e.expression_id)")
    end

    ctx.expressions[e.expression_id] = e
    return e
end

function ensure_expressions_are_bound_to_current_context(es::Expression...)
    ctx = get_algorithm_context()

    for e in es
        if !is_bound_to(e.expression_id, ctx)
            error("Expression $(e) was not bound to current context!")
        end
    end
end