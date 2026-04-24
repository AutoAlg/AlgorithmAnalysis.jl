import Base: =>

struct StateTransition{S} <: NewExpression
    id::ExpressionID
    current_id::ExpressionID
    next_id::ExpressionID
end
function StateTransition(current::AbstractVariable{S}, next_var::AbstractVariable{S}) where {S}        
    if !is_bound_to_current_context(current.id) || !is_bound_to_current_context(next_var.id)
        error("Cross-state transition is forbidden")
    end
    
    register!(StateTransition{S}(allocate_id(), current.id, next_var.id))
end

=>(current::AbstractVariable{S}, next_var::AbstractVariable{S}) where {S} = StateTransition(current, next_var)
