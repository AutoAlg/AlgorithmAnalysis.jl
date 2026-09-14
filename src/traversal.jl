export get_all_reachable_ids_from_roots

function visit_children!(id::ExpressionID, seen::Set{ExpressionID}, ctx::AlgorithmContext)
    if id in seen
        return
    else

        push!(seen, id)

        for d in dependencies(ctx.expressions[id])
            visit_children!(d, seen, ctx)
        end
    end
end

function get_all_reachable_ids_from_roots(roots::Vector{ExpressionID}, ctx::AlgorithmContext)
    seen = Set{ExpressionID}()

    for r in roots
        visit_children!(r, seen, ctx)
    end

    return seen
end
