
abstract type AbstractSpace end

struct RealSpace <: AbstractSpace end
struct RealVectorSpace <: AbstractSpace end

abstract type AbstractVariable{S <: AbstractSpace} <: NewExpression end
abstract type NewOracle     <: NewExpression end

abstract type ConcretelyValuedVariable{S} <: AbstractVariable{S} end


struct Variable{S <: AbstractSpace} <: ConcretelyValuedVariable{S}
    id::ExpressionID
    Variable{S}() where {S <: AbstractSpace} = register!(new{S}(allocate_id()))
end

const NewR  = Variable{RealSpace}
const NewRⁿ = Variable{RealVectorSpace}