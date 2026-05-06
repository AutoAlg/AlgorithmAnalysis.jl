
abstract type AbstractSpace end

# TODO: are there better names for these?
struct RealSpace <: AbstractSpace end
struct RealVectorSpace <: AbstractSpace end

abstract type AbstractVariable{S <: AbstractSpace} <: NewExpression end
abstract type NewOracle{Domain <: AbstractSpace, CoDomain <: AbstractSpace} <: NewExpression end

# TODO: is a better name for this SingularlyValuedVariable?
abstract type ConcretelyValuedVariable{S} <: AbstractVariable{S} end


struct Variable{S <: AbstractSpace} <: ConcretelyValuedVariable{S}
    id::ExpressionID
end
Variable{S}() where {S <: AbstractSpace} = register!(Variable{S}(allocate_id()))

# TODO: migrate to R and Rⁿ
const NewR  = Variable{RealSpace}
const NewRⁿ = Variable{RealVectorSpace}

struct OracleEvaluation{Domain <: AbstractSpace, CoDomain <: AbstractSpace} <: ConcretelyValuedVariable{CoDomain}
    id::ExpressionID
    oracle_id::ExpressionID
    input_id::ExpressionID
end

function OracleEvaluation(oracle::NewOracle{Domain, CoDomain}, input_variable::AbstractVariable{Domain}) where {Domain <: AbstractSpace, CoDomain <: AbstractSpace}
    ensure_expressions_are_bound_to_current_context(oracle, input_variable)
    return register!(OracleEvaluation{Domain, CoDomain}(allocate_id(), oracle.id, input_variable.id))
end

(oracle::NewOracle{Domain, CoDomain})(input_variable::AbstractVariable{Domain}) where {Domain <: AbstractSpace, CoDomain <: AbstractSpace} = OracleEvaluation(oracle, input_variable)


struct DualSpace{S <: AbstractSpace} <: AbstractSpace end

struct NewTranspose{S <: AbstractSpace} <: ConcretelyValuedVariable{DualSpace{S}}
    id::ExpressionID
    transposed_id::ExpressionID
end

function NewTranspose(variable::AbstractVariable{S}) where {S <: AbstractSpace}
    ensure_expressions_are_bound_to_current_context(variable)
    return register!(NewTranspose{S}(allocate_id(), variable.id))
end

struct NewInnerProduct{S <: AbstractSpace} <: ConcretelyValuedVariable{RealSpace}
    id::ExpressionID
    transpose_id::ExpressionID
    variable_id::ExpressionID
end

function NewInnerProduct(transpose_variable::AbstractVariable{DualSpace{S}}, variable::AbstractVariable{S}) where {S <: AbstractSpace}
    ensure_expressions_are_bound_to_current_context(transpose_variable, variable)
    return register!(NewInnerProduct{S}(allocate_id(), transpose_variable.id, variable.id))
end