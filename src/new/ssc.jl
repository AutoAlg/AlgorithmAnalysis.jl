struct SSCFunction <: NewOracle
    id::ExpressionID
    m::Float64
    L::Float64

    SSCFunction(m::Real, L::Real) = register!(new(allocate_id(), Float64(m), Float64(L)))
end

struct SSCGradient <: NewOracle
    id::ExpressionID
    function_of::ExpressionID
    
    SSCGradient(f::SSCFunction) = register!(new(allocate_id(), f.id))
end

struct SSCGradientOf{S} <: ConcretelyValuedVariable{S}
    id::ExpressionID
    ∇_id::ExpressionID
    x_id::ExpressionID
    
    function SSCGradientOf(∇::SSCGradient, x::AbstractVariable{RealVectorSpace})
        if !is_bound_to_current_context(∇.id) || !is_bound_to_current_context(x.id)
            error("Cross-state evaluation is forbidden")
        end
        
        register!(new{RealVectorSpace}(allocate_id(), ∇.id, x.id))
    end
end


(∇::SSCGradient)(x::AbstractVariable{RealVectorSpace}) = SSCGradientOf(∇, x)
SSC(m::Real, L::Real) = (f = SSCFunction(m, L); (f, SSCGradient(f)))
