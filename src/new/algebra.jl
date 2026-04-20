import Base: +, -, *

_to_dict(v::ConcretelyValuedVariable{S}, scale::Float64=1.0) where {S} = Dict{ConcretelyValuedVariable{S}, Float64}(v => scale)
_to_dict(d::LinearDecomposition{S}, scale::Float64=1.0) where {S} = Dict{ConcretelyValuedVariable{S}, Float64}(k => v * scale for (k, v) in d.terms)

function _merge_terms(a::Dict{ConcretelyValuedVariable{S}, Float64}, b::Dict{ConcretelyValuedVariable{S}, Float64}, b_scale::Float64=1.0) where {S}
    res = copy(a)
    for (k, v) in b
        res[k] = get(res, k, 0.0) + v * b_scale
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
