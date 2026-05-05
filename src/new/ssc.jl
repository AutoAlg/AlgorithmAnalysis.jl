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
    return register!(SSCGradient(allocate_id(), f.id))
end

SSC(m::Real, L::Real) = (f = SSCFunction(m, L); (f, SSCGradient(f)))