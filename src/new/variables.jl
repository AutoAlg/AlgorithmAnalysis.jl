
abstract type AbstractSpace end

# TODO: are there better names for these?
struct RealSpace <: AbstractSpace end
struct RealVectorSpace <: AbstractSpace end

abstract type AbstractVariable{S <: AbstractSpace} <: NewExpression end
abstract type NewOracle     <: NewExpression end # TODO: should an oracle hold it's types i.e an Oracle{AbstractSpace, AbstractSpace}?

# TODO: is a better name for this SingularlyValuedVariable?
abstract type ConcretelyValuedVariable{S} <: AbstractVariable{S} end


struct Variable{S <: AbstractSpace} <: ConcretelyValuedVariable{S}
    id::ExpressionID
end
Variable{S}() where {S <: AbstractSpace} = register!(Variable{S}(allocate_id()))

# TODO: migrate to R and Rⁿ
const NewR  = Variable{RealSpace}
const NewRⁿ = Variable{RealVectorSpace}