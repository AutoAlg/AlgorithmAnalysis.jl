struct LinearDecomposition{S <: AbstractSpace} <: AbstractVariable{S}
    id::ExpressionID
    terms::Dict{ConcretelyValuedVariable{S}, Float64}
    
    LinearDecomposition{S}(terms::Dict{ConcretelyValuedVariable{S}, Float64}) where {S} = register!(new{S}(allocate_id(), terms))
end
