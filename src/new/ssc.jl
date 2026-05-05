struct SSCFunction <: NewOracle{RealVectorSpace, RealSpace}
    id::ExpressionID
    m::Float64
    L::Float64
end
SSCFunction(m::Real, L::Real) = register!(SSCFunction(allocate_id(), Float64(m), Float64(L)))

struct SSCGradient <: NewOracle{RealVectorSpace, RealVectorSpace}
    id::ExpressionID
    function_of::ExpressionID
end    
function SSCGradient(f::SSCFunction) 
    ensure_expressions_are_bound_to_current_context(f)

    register!(SSCGradient(allocate_id(), f.id))
end

struct SSCGradientOf{S} <: ConcretelyValuedVariable{S}
    id::ExpressionID
    ∇_id::ExpressionID
    x_id::ExpressionID
end

function SSCGradientOf(∇::SSCGradient, x::AbstractVariable{RealVectorSpace})
    ensure_expressions_are_bound_to_current_context(∇, x);
    
    register!(SSCGradientOf{RealVectorSpace}(allocate_id(), ∇.id, x.id))
end

(∇::SSCGradient)(x::AbstractVariable{RealVectorSpace}) = SSCGradientOf(∇, x)
# TODO: should this be a two way link with a two allocate_id calls followed by two register calls? 
SSC(m::Real, L::Real) = (f = SSCFunction(m, L); (f, SSCGradient(f)))
