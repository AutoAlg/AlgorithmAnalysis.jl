import Base: +, -, *, adjoint, ^

export Scale, Product, Sum, *

struct Scale{S <: Space} <: Variable{S}
    id::ExpressionID
    scalar::Float64
    scaled::ExpressionID
end

Scale{S}(scalar::Float64, scaled::Variable{S}) where {S <: Space} = register!(Scale{S}(allocate_id!(), scalar, scaled.id))

*(scalar::Float64, scaled::Variable{S}) where {S <: Space} = Scale{S}(scalar, scaled)

struct Sum{S <: Space} <: Variable{S}
    id::ExpressionID
    expressions::Vector{ExpressionID}
end

Sum{S}(left::Variable{S}, right::Variable{S}) where {S <: Space} = register!(Sum{S}(allocate_id!(), [left.id, right.id]))
function Sum{S}(v1::Variable{S}, v2::Variable{S}, rest::Variable{S}...) where {S <: Space}
    ids::Vector{ExpressionID} = [v1.id, v2.id]

    for r in rest
        push!(ids, r.id)
    end

    return register!(Sum{S}(allocate_id!(), ids))
end

+(left::Variable{S}, right::Variable{S}) where {S <: Space} = Sum{S}(left, right)
-(left::Variable{S}, right::Variable{S}) where {S <: Space} = left + Scale{S}(-1.0, right)

struct Product{S <: Space} <: Variable{S}
    id::ExpressionID
    left::ExpressionID
    right::ExpressionID
end

Product{S}(left::Variable{RealSpace}, right::Variable{RealSpace}) where {S <: RealSpace} = register!(Product{S}(allocate_id!(), left.id, right.id))

*(left::Variable{RealSpace}, right::Variable{RealSpace}) = Product{RealSpace}(left, right)


adjoint(v::Variable{S}) where {S <: Space} = Transpose{S}(v)

*(v_prime::Variable{DualSpace{S}}, v::Variable{S}) where {S <: Space} = InnerProduct{S}(v_prime, v)

function ^(v::Variable{S}, power::Int)::Variable{RealSpace} where {S <: Space}
    if power != 2
        error("non squares are unrepresentable")
    end
    
    return v'*v
end