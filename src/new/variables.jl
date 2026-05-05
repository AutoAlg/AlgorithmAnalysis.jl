
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