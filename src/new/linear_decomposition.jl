struct LinearDecomposition{S <: AbstractSpace} <: AbstractVariable{S}
    id::ExpressionID
    terms::Dict{ExpressionID, Float64}
end

LinearDecomposition{S}(terms::Dict{ExpressionID, Float64}) where {S <: AbstractSpace} = register!(LinearDecomposition{S}(allocate_id(), terms))