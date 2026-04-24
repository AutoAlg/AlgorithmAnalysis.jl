struct SSCFunction <: NewOracle
    id::ExpressionID
    m::Float64
    L::Float64
end
SSCFunction(m::Real, L::Real) = register!(SSCFunction(allocate_id(), Float64(m), Float64(L)))

struct SSCGradient <: NewOracle
    id::ExpressionID
    function_of::ExpressionID
end    
SSCGradient(f::SSCFunction) = register!(SSCGradient(allocate_id(), f.id))

struct SSCGradientOf{S} <: ConcretelyValuedVariable{S}
    id::ExpressionID
    ∇_id::ExpressionID
    x_id::ExpressionID
end

function SSCGradientOf(∇::SSCGradient, x::AbstractVariable{RealVectorSpace})
    if !is_bound_to_current_context(∇.id) || !is_bound_to_current_context(x.id)
        error("Cross-state evaluation is forbidden")
    end
    
    register!(SSCGradientOf{RealVectorSpace}(allocate_id(), ∇.id, x.id))
end

(∇::SSCGradient)(x::AbstractVariable{RealVectorSpace}) = SSCGradientOf(∇, x)
SSC(m::Real, L::Real) = (f = SSCFunction(m, L); (f, SSCGradient(f)))
