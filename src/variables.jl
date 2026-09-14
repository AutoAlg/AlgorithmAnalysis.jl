export Space, RealSpace, RealVectorSpace, Variable

abstract type Space end

abstract type RealSpace <: Space end
abstract type RealVectorSpace <: Space end

abstract type Variable{S<:Space} <: Expression end
abstract type Oracle{Domain<:Space,CoDomain<:Space} <: Expression end


struct ConcretelyValuedVariable{S<:Space} <: Variable{S}
    id::ExpressionID
end
ConcretelyValuedVariable{S}() where {S<:Space} = register!(ConcretelyValuedVariable{S}(allocate_id!()))

const R = ConcretelyValuedVariable{RealSpace};
const Rⁿ = ConcretelyValuedVariable{RealVectorSpace};

struct OracleEvaluation{Domain<:Space,CoDomain<:Space} <: Variable{CoDomain}
    id::ExpressionID
    oracle_id::ExpressionID
    input_id::ExpressionID
end

function OracleEvaluation(oracle::Oracle{D,CD}, input::Variable{D}) where {D<:Space,CD<:Space}
    ensure_expressions_are_bound_to_current_context(oracle, input)
    return register!(OracleEvaluation{D,CD}(allocate_id!(), oracle.id, input.id))
end

(oracle::Oracle{D,CD})(input::Variable{D}) where {D<:Space,CD<:Space} = OracleEvaluation(oracle, input)

struct DualSpace{S<:Space} <: Space end

struct Transpose{S<:Space} <: Variable{DualSpace{S}}
    id::ExpressionID
    transposed_id::ExpressionID
end

function Transpose{S}(variable::Variable{S}) where {S<:Space}
    ensure_expressions_are_bound_to_current_context(variable)
    return register!(Transpose{S}(allocate_id!(), variable.id))
end


struct InnerProduct{S<:Space} <: Variable{RealSpace}
    id::ExpressionID
    left::ExpressionID
    right::ExpressionID
end

function InnerProduct{S}(left::Variable{DualSpace{S}}, right::Variable{S}) where {S<:Space}
    ensure_expressions_are_bound_to_current_context(left, right)
    return register!(InnerProduct{S}(allocate_id!(), left.id, right.id))
end