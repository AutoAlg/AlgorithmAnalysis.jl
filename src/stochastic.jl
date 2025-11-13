import Base: show, IO, convert, promote_rule

export GaussianRV, IntervalRange, expectation, variance, get_covariance, set_bulk_covariances!

mutable struct GaussianRV{F<:Field, T<:InnerProductSpace{F}} <: InnerProductSpace{AbstractRandomVariable{F,F}}
    label::String
    value::VectorValue{GaussianRV{F, T}}
    constraints::Constraints
    oracles::Oracles
    next::State{GaussianRV{F, T}}
    associations::Associations
    mean::T

    # TOOO: does this make sense
    function GaussianRV{F, T}(label, value, constraints, oracles, next_state) where {F<:Field, T<:InnerProductSpace{F}}
        return new{F, T}(label, value, constraints, oracles, next_state, Dict(), T())
    end

    function GaussianRV{F, T}(mean::T=T()) where {F<:Field, T<:InnerProductSpace{F}}
        self = new{F, T}("N(label(mean))", missing, Constraints(), Oracles(), missing, Dict(Dual => LinearFunctional{GaussianRV{F, T}}()), mean)
        return self
    end

end
is_random(::GaussianRV) = true

adjoint(g::GaussianRV{T}) where {T} = Dual{typeof(g)}(g)

Base.promote_rule(::Type{GaussianRV{F, T}}, ::Type{T}) where {F<:Field, T<:InnerProductSpace{F}} = GaussianRV{F, T}
Base.convert(::Type{GaussianRV{F, T}}, v::T) where {F<:Field, T<:InnerProductSpace{F}} = GaussianRV{F, T}(v)
function GaussianRV{F, T}(decomp::LinearDecomposition{GaussianRV{F, T}}) where {F<:Field, T<:InnerProductSpace{F}}
    new_mean = T() 
    for (g_component, weight) in weights(decomp)
        new_mean += weight * g_component.mean
    end

    self = GaussianRV{F, T}(new_mean)
    
    self.value = decomp
    
    return self
end


function show(io::IO, ::MIME"text/plain", g::GaussianRV{F, T}) where {F<:Field, T<:InnerProductSpace{F}}
    println(io, "Gaussian random variable in $(T)")
    if (!isempty(g.label)) 
        println(io, "  Label: ", g.label)
    end
    
    println(io, "  Mean: ", g.mean)

    isdefined(g, :vecs) && print(io, "\n Value: $(g.vecs) ⊗ $(g.vecs)")
    !isempty(label(g)) && print(io, "\n  Label: ", label(g))
    hasvalue(g) && print(io, "\n  Value: ", value(g))
    hasdecomposition(g) && print(io, "\n  Decomposition: ", decomposition(g))
    !isempty(constraints(g)) && print(io, "\n  Constraints: ", join(constraints(g), ", "))
    !isempty(oracles(g)) && print(io, "\n  Oracles: ", join(oracles(g), ", "))
    !ismissing(next(g)) && print(io, "\n  Next: ", next(g))
    !isempty(associations(g)) && print(io, "\n  Associations: ", join(associations(g),", "))

end


expectation(e::GaussianRV) = e.mean
