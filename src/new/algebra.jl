import Base: +, -, *, =>

_to_dict(v::ConcretelyValuedVariable, scale::Float64=1.0) = Dict{ExpressionID, Float64}(v.id => scale)

_to_dict(d::LinearDecomposition, scale::Float64=1.0) = Dict{ExpressionID, Float64}(id => v * scale for (id, v) in d.terms)

function _merge_terms(a::Dict{ExpressionID, Float64}, b::Dict{ExpressionID, Float64}, b_scale::Float64=1.0)
    res = copy(a)
    for (id, val) in b
        res[id] = get(res, id, 0.0) + val * b_scale
    end
    return res
end

*(α::Real, v::ConcretelyValuedVariable{S}) where {S} = LinearDecomposition{S}(_to_dict(v, Float64(α)))
*(α::Real, d::LinearDecomposition{S}) where {S}      = LinearDecomposition{S}(_to_dict(d, Float64(α)))
*(v::ConcretelyValuedVariable{S}, α::Real) where {S} = α * v
*(d::LinearDecomposition{S}, α::Real) where {S}      = α * d

+(l::ConcretelyValuedVariable{S}, r::ConcretelyValuedVariable{S}) where {S} = LinearDecomposition{S}(_merge_terms(_to_dict(l), _to_dict(r)))
+(l::ConcretelyValuedVariable{S}, r::LinearDecomposition{S}) where {S}      = LinearDecomposition{S}(_merge_terms(_to_dict(l), r.terms))
+(l::LinearDecomposition{S},      r::ConcretelyValuedVariable{S}) where {S} = r + l
+(l::LinearDecomposition{S},      r::LinearDecomposition{S}) where {S}      = LinearDecomposition{S}(_merge_terms(l.terms, r.terms))

-(l::ConcretelyValuedVariable{S}, r::ConcretelyValuedVariable{S}) where {S} = LinearDecomposition{S}(_merge_terms(_to_dict(l), _to_dict(r, -1.0)))
-(l::ConcretelyValuedVariable{S}, r::LinearDecomposition{S}) where {S}      = LinearDecomposition{S}(_merge_terms(_to_dict(l), r.terms, -1.0))
-(l::LinearDecomposition{S},      r::ConcretelyValuedVariable{S}) where {S} = LinearDecomposition{S}(_merge_terms(l.terms, _to_dict(r, -1.0)))
-(l::LinearDecomposition{S},      r::LinearDecomposition{S}) where {S}      = LinearDecomposition{S}(_merge_terms(l.terms, r.terms, -1.0))