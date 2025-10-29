import Base: show, IO, convert, promote_rule

export GaussianRV, IntervalRange, expectation, variance, get_covariance, set_bulk_covariances!

# TODO: inner product of a random variabele g'*g | ' - adjoint |  transpose is the adjoin, find the transpose of a random variable
# TODO: rv transpose goes into the wrapper, but then the wrapper needs to be able to be evaluated, how?? for eventually typing g'*g
# TODO: make the wrapper and then wriate a function that goes from the OrWrapper * a T and then ues that to claucatated what is desried 
mutable struct IntervalRange{T}
    min::T
    max::T
end
IntervalRange{T}(t::T) where {T} = IntervalRange{T}(t, t)
function label(r::IntervalRange{T}) where {T} 
    if (isequal(r.min, r.max)) 
        return "[$(sprint(show, r.min))]"
    else
        return "[$(sprint(show, r.min)), $(sprint(show, r.max))]"
    end
end
    
    

Base.:+(l::IntervalRange{T}, r::IntervalRange{T}) where {T} = IntervalRange(l.min + r.min, l.max + r.max)
Base.:+(l::T, r::IntervalRange{T}) where {T} = +(promote(l,r)...)
Base.:+(l::IntervalRange{T}, r::T) where {T} = +(promote(l,r)...)
function Base.:*(scalar::Number, r::IntervalRange{T}) where {T}
    if scalar >= 0
        return IntervalRange(scalar * r.min, scalar * r.max);
    else
        return IntervalRange(scalar * r.max, scalar * r.min);
    end
end
Base.:zero(::Type{IntervalRange{T}}) where {T} = IntervalRange(zero(T), zero(T))
Base.:show(io::IO, r::IntervalRange{T}) where {T} = print(io, "[$(r.min), $(r.max)]")

Base.convert(::Type{IntervalRange{T}}, x::T) where {T} = IntervalRange(x, x)
Base.promote_rule(::Type{IntervalRange{T}}, ::Type{T}) where {T} = IntervalRange{T}


mutable struct GaussianRV{T<:AbstractVectorSpace} <: AbstractVectorSpace
    label::String
    value::VectorValue{GaussianRV{T}} 
    constraints::Constraints
    oracles::Oracles
    next::State{GaussianRV{T}}
    
    mean::IntervalRange{T}
    covariances::Dict{GaussianRV{T}, IntervalRange{F}} where {F<:Field, T<:VectorSpace{F}}

    function GaussianRV{T}(mean::IntervalRange{T}, variance::IntervalRange{F}, label::String ="N($(label(mean)), $(label(variance)))") where {F<:Field, T<:VectorSpace{F}}
        self = new{T}(label, missing, Constraints(), Oracles(), missing, mean, Dict{GaussianRV{T}, IntervalRange{F}}())
        self.covariances[self] = variance

        return self
    end

    function GaussianRV{T}(mean::T, variance::F, label = "N($(label(mean)), $(label(variance)))") where {F<:Field, T<:VectorSpace{F}}
        return GaussianRV{T}(IntervalRange(mean, mean), IntervalRange(variance, variance));
    end

    function GaussianRV{T}(mean::T, variance::IntervalRange{F}, label = "N($(label(mean)), $(label(variance)))") where {F<:Field, T<:VectorSpace{F}}
        return GaussianRV{T}(IntervalRange(mean, mean), variance);
    end


    function GaussianRV{T}(mean::IntervalRange{T}, variance::F, label = "N($(label(mean)), $(label(variance)))") where {F<:Field, T<:VectorSpace{F}}
        return GaussianRV{T}(mean, IntervalRange(variance, variance));
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
        if (!isequal(rv, g))
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

function set_bulk_covariances!(pairs::Vector{Pair{Tuple{GaussianRV{T}, GaussianRV{T}}, IntervalRange{F}}}) where {F<:Field, T<:VectorSpace{F}}
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

function set_covariance_unchecked!(g1::GaussianRV{T}, g2::GaussianRV{T}, cov::IntervalRange{F}) where {F<:Field, T<:VectorSpace{F}}
    g1.covariances[g2] = cov;
    g2.covariances[g1] = cov;
end

function get_covariance(g1::GaussianRV{T}, g2::GaussianRV{T}) where {F<:Field, T<:VectorSpace{F}}
    if haskey(g1.covariances, g2)
        return g1.covariances[g2]
    end

    return zero(IntervalRange{F})
end

variance(g::GaussianRV) = get_covariance(g, g)

function gather_related_rvs(rvs::GaussianRV{T}...) where {T<:AbstractVectorSpace}
    related_rvs = Set{GaussianRV{T}}();

    for rv in rvs
        union!(related_rvs, keys(rv.covariances))
    end

    return related_rvs
end

function Base.:+(e1::IntervalRange{T}, e2::GaussianRV{T}) where {T<:AbstractVectorSpace}
    new_rv = GaussianRV{T}(e1 + e2.mean, variance(e2), "($(label(e1)) + $(label(e2)))")

    for other_rv in gather_related_rvs(e2)
        if !isequal(other_rv, new_rv)
            set_covariance_unchecked!(new_rv, other_rv, get_covariance(e2, other_rv))
        end    
    end

    return new_rv
end
Base.:+(e1::GaussianRV{T}, e2::IntervalRange{T}) where {T<:AbstractVectorSpace} = e2 + e1
Base.:+(e1::GaussianRV{T}, e2::T) where {T<:AbstractVectorSpace} = e1 + convert(IntervalRange{T}, e2)
Base.:+(e1::T, e2::GaussianRV{T}) where {T<:AbstractVectorSpace} = e2 + e1

function +(e1::GaussianRV{T}, e2::GaussianRV{T}) where {T<:AbstractVectorSpace}
    new_rv = GaussianRV{T}(
        e1.mean + e2.mean,
        variance(e1) + variance(e2) + 2 * get_covariance(e1, e2),
        "($(e1.label) + $(e2.label))"
    )

    # Cov(e1 + e2, other_rv) = Cov(e1, other_rv) + Cov(e2, other_rv)
    for other_rv in gather_related_rvs(e1, e2)
        if !isequal(other_rv, new_rv)           
            set_covariance_unchecked!(
                new_rv,
                other_rv,
                get_covariance(e1, other_rv) + get_covariance(e2, other_rv)
            )
        end
    end

    return new_rv
end
Base.:-(g1::GaussianRV{T}, g2::GaussianRV{T}) where {T<:AbstractVectorSpace} = g1 + (-1 * g2) 
Base.:-(e1::GaussianRV{T}, e2::IntervalRange{T})             where {T<:AbstractVectorSpace} = e1 + (-1 * e2)
Base.:-(e1::IntervalRange{T},             e2::GaussianRV{T}) where {T<:AbstractVectorSpace} = e1 + (-1 * e2)

function Base.:*(s::Number, g::GaussianRV{T}) where {T<:AbstractVectorSpace}
    new_rv = GaussianRV{T}(s * g.mean, s*s * variance(g), "($s * $(label(g)))")

    # Cov(rv, other_rv) = s * Cov(g, other_rv)
    for other_rv in gather_related_rvs(g)
        if !isequal(other_rv, new_rv)
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