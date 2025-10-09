import Base: show

export GaussianRV, expectation, variance

# mutability is attached at the type level not the value level like with a const&
mutable struct GaussianRV{T<:AbstractVectorSpace} <: AbstractVectorSpace
    label::String # this is the thing that is reached into by the @algorithm macro
    # ngl, below this I am straight up just copying
    value::VectorValue{GaussianRV{T}} 
    constraints::Constraints
    oracles::Oracles
    next::State{GaussianRV{T}}
    
    mean::T
    variance::T
    # TODO: add list of covs

    # TODO: should this be ∈ based
    function GaussianRV{T}(mean::Expression, variance::Expression) where {T<:Expression}
        label = "N($(mean.label), $(variance.label))"
        new{T}(label, missing, Constraints(), Oracles(), missing, mean, variance)
    end
end


function show(io::IO, ::MIME"text/plain", g::GaussianRV)
    println(io, "GaussianRV variable in $(typeof(g))")
    !isempty(g.label) && println(io, "  Label: ", g.label)
    
    println(io, "  Mean: ", g.mean)
    println(io, "  Variance: ", g.variance)
end


is_any_subexpressions_random_variable(e::GaussianRV) = true
is_any_subexpressions_random_variable(e::Expression) = hasdecomposition(e) ? any(is_random, keys(weights(e))) : false
is_deterministic(e::Expression) = !is_any_subexpressions_random_variable(e)

function expectation(e::Expression)
    if is_deterministic(e)
        return e.value
    end

    if is_any_subexpressions_random_variable(e)
        sum = zero(T)
        for (w, v) in weights(e)
            sum += w * expectation(v);
        end
        return sum
    end

    return e
end

expectation(e::GaussianRV) = g.mean

function variance(X::Expression)
    μ = expectation(X)
    return expectation((X - μ)^2)
end
variance(g::GaussianRV) = g.variance

function Base.:+(e1::T, e2::GaussianRV{T}) where {T<:AbstractVectorSpace}
    new = deepcopy(e2);
    new.mean += e1;
    new.label = "($(e1.label) + $(e2.label))"
    return new
end
Base.:+(e1::GaussianRV{T}, e2::T) where {T<:AbstractVectorSpace} = e2 + e1

function +(e1::GaussianRV{T}, e2::GaussianRV{T}) where {T}
    rv = GaussianRV{T}(e1.mean + e2.mean, e1.variance + e2.variance) # TODO add cov to this
    rv.label = "($(e1.label) + $(e2.label))"

    return rv
end

Base.:-(e1::GaussianRV{T}, e2::T) where {T<:AbstractVectorSpace} = e1 + -e2
Base.:-(e1::T, e2::GaussianRV{T}) where {T<:AbstractVectorSpace} = e1 + (-1 * e2)
Base.:-(e1::GaussianRV{T}, e2::GaussianRV{T}) where {T<:AbstractVectorSpace} = e1 + (-1 * e2)

function Base.:*(s::Number, g::GaussianRV{T}) where {T<:AbstractVectorSpace}
    rv = GaussianRV{T}(s * g.mean, s^2 * g.variance)
    rv.label = "($s * $(label(g)))"
    return rv
end


function *(g1::GaussianRV, g2::GaussianRV{T}) where {T}
    error("more complex because its not a gaussian")
end


function *(g::GaussianRV{T}, s::Rⁿ) where {T}
    error("TODO does this make sense do this")
end