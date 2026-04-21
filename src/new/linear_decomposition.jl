struct LinearDecomposition{S <: AbstractSpace} <: AbstractVariable{S}
    id::ExpressionID
    terms::Dict{ExpressionID, Float64}
    
    LinearDecomposition{S}(terms::Dict{ExpressionID, Float64}) where {S} = register!(new{S}(allocate_id(), terms))
end