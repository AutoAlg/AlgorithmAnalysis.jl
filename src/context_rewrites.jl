export rewrite

function rewriteInternal(
    old_id::ExpressionID,
    resolved::Dict{ExpressionID, ExpressionID},
    rule::Function, #(old_id, resolved, old_ctx, new_ctx) -> new_id
    old_ctx::AlgorithmContext,
    new_ctx::AlgorithmContext
)::Nothing
    if haskey(resolved, old_id)
        return
    end

    shouldBeExpression::Expression = old_ctx.expressions[old_id]

    for child::ExpressionID in dependencies(shouldBeExpression)
        rewriteInternal(child, resolved, rule, old_ctx, new_ctx)
    end

    resolved[old_id] = rule(old_id, resolved, old_ctx, new_ctx)

    return nothing
end

struct RewriteResult
    new_context::AlgorithmContext
    new_roots::Vector{ExpressionID}
    mappings::Dict{ExpressionID, ExpressionID}
end

function rewrite(
    roots::Vector{ExpressionID},
    ctx::AlgorithmContext,
    rule::Function #(old_id, resolved, old_ctx, new_ctx) -> new_id
    )::RewriteResult

    resolved = Dict{ExpressionID, ExpressionID}()
    new_context = AlgorithmContext()

    with_context(new_context) do
        for r in roots
            rewriteInternal(r, resolved, rule, ctx, new_context)
        end
    end

    return RewriteResult(new_context, [resolved[r] for r in roots], resolved)
end


function eliminate_unreachable_expressions(
    roots::Vector{ExpressionID},
    ctx::AlgorithmContext
)::RewriteResult
    function rule(old_id::ExpressionID, mappings::Dict{ExpressionID, ExpressionID}, old_ctx::AlgorithmContext, new_ctx::AlgorithmContext)::ExpressionID
        return replace_expression_context_with_alias_transfer(old_ctx.expressions[old_id], mappings, old_ctx).id
    end

    return rewrite(roots, ctx, rule)
end