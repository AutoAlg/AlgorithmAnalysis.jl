struct SSCFunction <: NewOracle
    id::ExpressionID
    m::Float64
    L::Float64
    SSCFunction(m::Real, L::Real) = register!(new(allocate_id(), Float64(m), Float64(L)))
end

struct GradientOf{S} <: ConcretelyValuedVariable{S}
    id::ExpressionID
    f_id::ExpressionID
    x_id::ExpressionID
    
    function GradientOf(f::SSCFunction, x::AbstractVariable{RealVectorSpace})
        if !is_bound_to_current_context(f.id) || !is_bound_to_current_context(x.id)
            error("Cross-state evaluation is forbidden")
        end
        
        register!(new{RealVectorSpace}(allocate_id(), f.id, x.id))
    end
end

struct SSCGradient
    f::SSCFunction
end

(∇f::SSCGradient)(x::AbstractVariable{RealVectorSpace}) = GradientOf(∇f.f, x)
SSC(m::Real, L::Real) = (f = SSCFunction(m, L); (f, SSCGradient(f)))
