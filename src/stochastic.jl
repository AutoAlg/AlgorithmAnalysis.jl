import Base: show

export GaussianRV, expectation, variance, get_covariance, set_bulk_covariances!

mutable struct GaussianRV{T<:AbstractVectorSpace} <: AbstractVectorSpace
    label::String
    value::VectorValue{GaussianRV{T}} 
    constraints::Constraints
    oracles::Oracles
    next::State{GaussianRV{T}}
    
    mean::T
    covariances::Dict{GaussianRV{T}, T}

    function GaussianRV{T}(mean::T, variance::T, label::String ="N($(mean.label), $(variance.label))") where {T<:Expression}
        self = new{T}(label, missing, Constraints(), Oracles(), missing, mean, Dict{GaussianRV{T}, T}())
        self.covariances[self] = variance

        return self
    end
end


function show(io::IO, ::MIME"text/plain", g::GaussianRV{T}) where {T<:AbstractVectorSpace}
    println(io, "Gaussian random variable in $(T)")
    if (!isempty(g.label)) 
        println(io, "  Label: ", g.label)
    end
    
    println(io, "  Mean: ", g.mean)
    println(io, "  Variance: ", variance(g))
    for (rv, cov) in g.covariances
        if (rv !== g)
            println(io, "  Covariance(self, $(rv.label)) = ", cov)
        end
    end
end


# is_any_subexpressions_random_variable(e::GaussianRV) = true
# is_any_subexpressions_random_variable(e::Expression) = hasdecomposition(e) ? any(is_random, keys(weights(e))) : false
# is_deterministic(e::Expression) = !is_any_subexpressions_random_variable(e)

# function expectation(e::Expression)
#     if is_deterministic(e)
#         return e.value
#     end

#     if is_any_subexpressions_random_variable(e)
#         sum = zero(T)
#         for (w, v) in weights(e)
#             sum += w * expectation(v);
#         end
#         return sum
#     end

#     return e
# end

expectation(e::GaussianRV) = e.mean

function set_bulk_covariances!(pairs::Vector{Pair{Tuple{GaussianRV{T}, GaussianRV{T}}, T}}) where {T<:AbstractVectorSpace}
    for ((rv1, rv2), _) in pairs
        if length(rv1.covariances) != 1
            error("$(rv1.label) is not IID. All covariant variables must be initialized together. It has $(length(rv1.covariances)) covariance entries.");
        end

        if length(rv2.covariances) != 1
            error("$(rv2.label) is not IID. All covariant variables must be initialized together. It has $(length(rv2.covariances)) covariance entries.");
        end
    end

    for ((rv1, rv2), desired_cov) in pairs
        set_covariance_unchecked!(rv1, rv2, desired_cov);
    end
end

function set_covariance_unchecked!(g1::GaussianRV{T}, g2::GaussianRV{T}, cov::T) where {T<:AbstractVectorSpace}
    g1.covariances[g2] = cov;
    g2.covariances[g1] = cov;
end

function get_covariance(g1::GaussianRV{T}, g2::GaussianRV{T}) where {T<:AbstractVectorSpace}
    if haskey(g1.covariances, g2)
        return g1.covariances[g2]
    end

    return zero(T)
end

variance(g::GaussianRV) = get_covariance(g, g)

function gather_related_rvs(rvs::GaussianRV{T}...) where {T<:AbstractVectorSpace}
    related_rvs = Set{GaussianRV{T}}();

    for rv in rvs
        union!(related_rvs, keys(rv.covariances))
    end

    return related_rvs
end

function Base.:+(e1::T, e2::GaussianRV{T}) where {T<:AbstractVectorSpace}
    new_rv = GaussianRV{T}(e1 + e2.mean, variance(e2), "($(e1.label) + $(e2.label))")

    # Cov(e1 + constant, other_rv) = Cov(e1, other_rv)
    for other_rv in gather_related_rvs(e2)
        if other_rv !== new_rv
            set_covariance_unchecked!(new_rv, other_rv, get_covariance(e2, other_rv))
        end    
    end

    return new_rv
end
Base.:+(e1::GaussianRV{T}, e2::T) where {T<:AbstractVectorSpace} = e2 + e1

function +(e1::GaussianRV{T}, e2::GaussianRV{T}) where {T}
    new_rv = GaussianRV{T}(
        e1.mean + e2.mean,
        variance(e1) + variance(e2) + 2 * get_covariance(e1, e2),
        "($(e1.label) + $(e2.label))"
    )

    # Cov(e1 + e2, other_rv) = Cov(e1, other_rv) + Cov(e2, other_rv)
    for other_rv in gather_related_rvs(e1, e2)
        if other_rv !== new_rv              
            set_covariance_unchecked!(
                new_rv,
                other_rv,
                get_covariance(e1, other_rv) + get_covariance(e2, other_rv)
            )
        end
    end

    return new_rv
end
Base.:-(g1::GaussianRV{T}, g2::GaussianRV{T}) where {T<:AbstractVectorSpace} = g1 +(-1 * g2) 
Base.:-(e1::GaussianRV{T}, e2::T)             where {T<:AbstractVectorSpace} = e1 + -e2
Base.:-(e1::T,             e2::GaussianRV{T}) where {T<:AbstractVectorSpace} = e1 + (-1 * e2)

function Base.:*(s::Number, g::GaussianRV{T}) where {T<:AbstractVectorSpace}
    new_rv = GaussianRV{T}(s * g.mean, s^2 * variance(g), "($s * $(label(g)))")

    # Cov(rv, other_rv) = s * Cov(g, other_rv)
    for other_rv in gather_related_rvs(g)
        if other_rv !== new_rv 
            set_covariance_unchecked!(new_rv, other_rv, s * get_covariance(g, other_rv))
        end
    end
    return new_rv
end


function *(g1::GaussianRV, g2::GaussianRV{T}) where {T}
    error("A Gaussian times a Gaussian is not a Gaussian")
end


function *(g::GaussianRV{T}, s::Rⁿ) where {T}
    error("TODO does this make sense do this")
end