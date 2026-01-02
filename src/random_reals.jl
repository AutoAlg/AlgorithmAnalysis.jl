
import Base.:+, Base.:-, Base.:*

"""
    RandomR <: RandomField

The field of Random Variables over R whose mean is in R.
"""
@randomfield(RandomR, R)

function Base.convert(::Type{RandomR}, r::R)
    if hasdecomposition(r)
        # https://discourse.julialang.org/t/argument-destructuring-and-anonymous-functions/24893
        return mapreduce(((var, coefficient),) -> coefficient * convert(RandomR, var), +, weights(r); init=zero(RandomR))
    end

    randomR = RandomR(label(r))
    randomR.mean = r
    if hasvalue(r)
        randomR.value = value(r)
    end

    return randomR
end
RandomR(r::R) = convert(RandomR, r);
Base.promote_rule(::Type{RandomR}, ::Type{<:R}) = RandomR

+(x::R, y::RandomR) = convert(RandomR, x) + y
+(x::RandomR, y::R) = y + x
-(x::R, y::RandomR) = x + (-y)
-(x::RandomR, y::R) = x + (-y)

# TODO: this should probablel have the number + RandomR overloads like R

*(::RandomR, ::RandomR) = error("In the AlgorithmAnalysis.jl the inner produce of two scalar variables results in an expression that is not first order and is therefore not allowed")




"""
    RandomRⁿ

The field of Random Variables over Rⁿ whose mean is in Rⁿ and inner product is in R
"""
@randominnerproductspace RandomRⁿ, Rⁿ, RandomR

function Base.convert(::Type{RandomRⁿ}, r::Rⁿ)
    if hasdecomposition(r)
        return mapreduce(((var, coefficient),) -> coefficient * convert(RandomRⁿ, var), +, weights(r); init=zero(RandomRⁿ))
    end

    randomRn = RandomRⁿ(label(r))
    randomRn.mean = r
    if hasvalue(r)
        randomRn.value = value(r)
    end

    return randomRn
end
RandomRⁿ(r::Rⁿ) = convert(RandomRⁿ, r)
Base.promote_rule(::Type{RandomRⁿ}, ::Type{<:Rⁿ}) = RandomRⁿ

+(x::Rⁿ, y::RandomRⁿ) = convert(RandomRⁿ, x) + y
+(x::RandomRⁿ, y::Rⁿ) = y + x
-(x::Rⁿ, y::RandomRⁿ) = x + (-y)
-(x::RandomRⁿ, y::Rⁿ) = x + (-y)

# TODO: RandomR and RandomRⁿ operators

struct ExpectationOperator <: AbstractLinearMap{Expression,Expression}
    label::String
    properties::Properties
    relation::SingleValuedRelation{Expression,Expression}

    function ExpectationOperator()
        return new("not labeled", Properties([Linear()]), SingleValuedRelation{Expression,Expression}())
    end
end

(::ExpectationOperator)(r::R) = r
(::ExpectationOperator)(rn::Rⁿ) = rn

(::ExpectationOperator)(rn::RandomRⁿ) = rn.mean

function (op::ExpectationOperator)(e::RandomR)
    if hasdecomposition(e)
        mapreduce(p -> last(p) * op(first(p)), +, weights(e); init=Zero())
    else
        e.mean
    end
end

# TODO: what should this be named
# TODO: this needs operators for Rⁿ - R (mean offset)
covariance(x::Expression, y::Expression) = E((x - E(x))' * (y - E(y)))

const 𝔼 = ExpectationOperator()
const E = 𝔼;

# TODO fix priting of w - E(w)
# TODO: fix isequal(E(w+k), E(w) + E(k))
