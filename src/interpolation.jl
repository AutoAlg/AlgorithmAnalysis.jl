

function generate_interpolation_constraint(
    f::SSCFunction, 
    ∇f::SSCGradient, 
    x::Variable{RealVectorSpace}, 
    y::Variable{RealVectorSpace})::Constraint
    if (∇f.function_of != f.id)
        error("don't do this please")
    end
    
    return f(x) >= 
        f(y) +
        (∇f(y)' * (x-y)) +
        (f.m) / 2.0 * ((x-y)'*(x-y)) + 
        (1/(2 * (f.L - f.m) )) * (∇f(x) - ∇f(y) - f.m * (x - y))'* (∇f(x) - ∇f(y) - f.m * (x - y))

end