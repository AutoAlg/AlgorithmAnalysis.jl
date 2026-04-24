struct LinearDecomposition{S <: AbstractSpace} <: AbstractVariable{S}
    id::ExpressionID
    terms::Dict{ExpressionID, Float64}
end

LinearDecomposition{S}(terms::Dict{ExpressionID, Float64}) where {S} = register!(LinearDecomposition{S}(allocate_id(), terms))