export replace_expression_context

function replace_expression_context(scale::Scale{S}, mappings::Dict{ExpressionID, ExpressionID})::Scale{S} where {S <: Space}
    register!(Scale{S}(allocate_id!(), scale.scalar, mappings[scale.scaled]))
end
function replace_expression_context(sum::Sum{S}, mappings::Dict{ExpressionID, ExpressionID})::Sum{S} where {S <: Space}
    new_expressions::Vector{ExpressionID} = map((old_id) -> mappings[old_id], sum.expressions)
   
    register!(Sum{S}(allocate_id!(), new_expressions))
end
function replace_expression_context(product::Product{S}, mappings::Dict{ExpressionID, ExpressionID})::Product{S} where {S <: Space}
    register!(Product{S}(allocate_id!(), mappings[product.left], mappings[product.right]))
end

function replace_expression_context(::Zero{S}, ::Dict{ExpressionID, ExpressionID})::Zero{S} where {S <: Space}
    register!(Zero{S}(allocate_id!()))
end


function replace_expression_context(::ConcretelyValuedVariable{S}, ::Dict{ExpressionID, ExpressionID})::ConcretelyValuedVariable{S} where {S <: Space}
    register!(ConcretelyValuedVariable{S}(allocate_id!()))
end
function replace_expression_context(oe::OracleEvaluation{D, CD}, mappings::Dict{ExpressionID, ExpressionID})::OracleEvaluation{D, CD} where {D <: Space, CD <: Space}
    register!(OracleEvaluation{D, CD}(allocate_id!(), mappings[oe.oracle_id], mappings[oe.input_id]))
end
function replace_expression_context(transpose::Transpose{S}, mappings::Dict{ExpressionID, ExpressionID})::Transpose{S} where {S <: Space}
    register!(Transpose{S}(allocate_id!(), mappings[transpose.transposed_id]))
end
function replace_expression_context(ip::InnerProduct{S}, mappings::Dict{ExpressionID, ExpressionID})::InnerProduct{S} where {S <: Space}
    register!(InnerProduct{S}(allocate_id!(), mappings[ip.left], mappings[ip.right]))
end


function replace_expression_context(f::SSCFunction, ::Dict{ExpressionID, ExpressionID})::SSCFunction
    register!(SSCFunction(allocate_id!(), f.m, f.L))
end
function replace_expression_context(gf::SSCGradient, mappings::Dict{ExpressionID, ExpressionID})::SSCGradient
    register!(SSCGradient(allocate_id!(), mappings[gf.function_of]))
end

function replace_expression_context(c::Constraint, mappings::Dict{ExpressionID, ExpressionID})::Constraint
    register!(Constraint(allocate_id!(), mappings[c.expression], c.op))
end


function replace_expression_context_with_alias_transfer(e::E, mappings::Dict{ExpressionID, ExpressionID}, old_context::AlgorithmContext)::E where {E <: Expression}
    new_e = replace_expression_context(e, mappings)

    if haskey(old_context.expression_aliases, e.id)
        set_alias!(new_e, old_context.expression_aliases[e.id])
    end

    return new_e
end