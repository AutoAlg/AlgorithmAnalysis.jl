import Base: =>

struct StateTransition{S} <: NewExpression
    id::ExpressionID
    current_id::ExpressionID
    next_id::ExpressionID
end
function StateTransition(current::AbstractVariable{S}, next_var::AbstractVariable{S}) where {S <: AbstractSpace}        
    ensure_expressions_are_bound_to_current_context(current, next_var); 

    register!(StateTransition{S}(allocate_id(), current.id, next_var.id))
end

=>(current::AbstractVariable{S}, next_var::AbstractVariable{S}) where {S <: AbstractSpace} = StateTransition(current, next_var)
