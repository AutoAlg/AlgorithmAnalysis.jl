
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

"""
    ExpectationOperator

The structure which defines the relation between a random variable and its expected value
"""
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


"""
    𝔼

A global instantiation of ExpectationOperator to allow for more ergonomic
expression of expectations.

# Examples
```julia
@algorithm begin
    x = RandomR() # define a random variable with an unconstrained mean
    y = RandomR() # define another random variable with an unconstrained mean

    z = 2x + y # produce another random variable whose mean is dependent on the means of x and y

    @test isequal(𝔼(z), 𝔼(y) + 2 * 𝔼(x)) # demonstration of the linearity of expectation
    @test isequal(z, -(-z))
end
```
"""
const 𝔼 = ExpectationOperator()
"""
    E

    see [`𝔼`](@ref)
"""
const E = 𝔼;

# TODO fix priting of w - E(w)
# TODO: fix isequal(E(w+k), E(w) + E(k))


"""
    covariance

The function which calculates the covariance of random variables using the standard relation
Cov(x, y) = 𝔼((x - 𝔼(x))' * (y - 𝔼(y)))
"""
covariance(x::Expression, y::Expression) = E((x - E(x))' * (y - E(y)))