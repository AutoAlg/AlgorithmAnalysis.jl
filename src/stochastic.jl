import Base: show, IO, convert, promote_rule

export GaussianRV, expectation, centered, tr_covariance, expected_inner_product

# TODO: figure out RV naming issues with subfields
# TODO: move stuff out of this file
# split into two things
# mean is make the average value returned equal the mean
# variance is a bound on the relative size difference between all of those values
# i.e for like 4 samples if you had a variance of 0.1 and a mean of 0 [-0.1, 0, 0.1, 0] 
# is a valid solution, 


# Defines a GaussianRV, denoted v in the documentation
mutable struct GaussianRV{F<:Field, T<:InnerProductSpace{F}} <: Expression
    label::String
    value::VectorValue{GaussianRV{F, T}}
    constraints::Constraints
    oracles::Oracles
    next::State{GaussianRV{F, T}}
    associations::Associations
    
    mean::T     # E[v]
    centered::T # v - E[v]
    # v = mean + centered
    # v = E[v] + v - E[v]
    # v = v

    function GaussianRV{F, T}(::Zero) where {F<:Field, T<:InnerProductSpace{F}}

        self = new{F, T}("ZERO GAUSSIAN", missing, Constraints(), Oracles(), missing, Dict(), 
                         zero(T), zero(T))
        return self
    end


    function GaussianRV{F, T}(label::String = "GaussianRV") where {F<:Field, T<:InnerProductSpace{F}}
        mean_vec = T()
        centered_vec = T()

        # TODO: sort out naming with this
        label!(mean_vec, label * "_μ")      
        label!(centered_vec, label * "_c") 

        self = new{F, T}(label, missing, Constraints(), Oracles(), missing, Dict(), 
                         mean_vec, centered_vec)
        return self
    end


    function GaussianRV{F, T}(decomp::LinearDecomposition{<:GaussianRV})  where {F<:Field, T<:InnerProductSpace{F}}      
        g_new = GaussianRV{F, T}("Decomp") 
        g_new.mean = expectation(decomp)
        g_new.centered = centered(decomp)
        g_new.value = decomp 
        return g_new
    end
end


expectation(e::InnerProductSpace) = e
centered(e::InnerProductSpace) = zero(e)

expectation(g::GaussianRV) = g.mean
centered(g::GaussianRV) = g.centered

function expectation(e::Expression)
    if hasdecomposition(e)
        mapreduce(p -> last(p) * expectation(first(p)), +, weights(e))
    else
        e
    end
end

function centered(e::Expression)
    if hasdecomposition(e)
        mapreduce(p -> last(p) * centered(first(p)), +, weights(e))
    else
        zero(e)
    end
end


function show(io::IO, ::MIME"text/plain", g::GaussianRV{F, T}) where {F<:Field, T<:VectorSpace{F}}
    println(io, "Gaussian random variable in $(T)")
    if (!isempty(g.label)) 
        println(io, "  Label: ", g.label)
    end
    
    println(io, "  Mean: ", g.mean)
    println(io, "  Centered: ", g.centered)

    hasvalue(g) && print(io, "\n  Value: ", value(g))
    hasdecomposition(g) && print(io, "\n  Decomposition: ", decomposition(g))
    !isempty(constraints(g)) && print(io, "\n  Constraints: ", join(constraints(g), ", "))
    !isempty(oracles(g)) && print(io, "\n  Oracles: ", join(oracles(g), ", "))
    !ismissing(next(g)) && print(io, "\n  Next: ", next(g)) 
    !isempty(associations(g)) && print(io, "\n  Associations: ", join(associations(g),", "))

end


"""
    tr_covariance(g1::Expression, g2::Expression)

Returns the symbolic expression for Tr(Cov(g1, g2)),
which is E[(g1-E[g1])' * (g2-E[g2])].
"""
function tr_covariance(g1::Expression, g2::Expression)
    return centered(g1)' * centered(g2)
end

"""
    expected_inner_product(g1::Expression, g2::Expression)

Returns the symbolic expression for E[g1' * g2].
"""
function expected_inner_product(g1::Expression, g2::Expression)
    # E[X]'E[Y]
    mean_prod = expectation(g1)' * expectation(g2)
    
    # Tr(Cov(X, Y))
    cov_prod = tr_covariance(g1, g2)
    
    # E[X'Y] = E[X]'E[Y] + Tr(Cov(X, Y))
    return mean_prod + cov_prod
end



# Promote a T -> GaussianRV{F, T}
Base.promote_rule(::Type{GaussianRV{F, T}}, ::Type{T}) where {F<:Field, T<:InnerProductSpace{F}} = GaussianRV{F, T}

function Base.convert(::Type{GaussianRV{F, T}}, e::T) where {F<:Field, T<:InnerProductSpace{F}}
    g = GaussianRV{F, T}(label(e))
    
    g.mean = e # E[e] is e
    
    g.centered = zero(e)  # e - E[e] = 0, since there is no random component
    
    return g
end

function Base.:+(e1::T, e2::GaussianRV{F, T}) where {F<:Field, T<:InnerProductSpace{F}}
    +(promote(e1, e2)...)
end

# Catches: GaussianRV + Rⁿ
function Base.:+(e1::GaussianRV{F, T}, e2::T) where {F<:Field, T<:InnerProductSpace{F}}
    +(promote(e1, e2)...)
end

function Base.:+(e1::T, e2::T) where {T<:GaussianRV}
    if iszero(e1)
        return e2
    elseif iszero(e2)
        return e1
    end
    
    decomp = selfdecomp(e1) + selfdecomp(e2)

    return T(decomp) 
end


function Base.:-(e1::T, e2::GaussianRV{F, T}) where {F<:Field, T<:InnerProductSpace{F}}
    -(promote(e1, e2)...)
end

function Base.:-(e1::GaussianRV{F, T}, e2::T) where {F<:Field, T<:InnerProductSpace{F}}
    -(promote(e1, e2)...)
end

function Base.:-(e1::T, e2::T) where {T<:GaussianRV}
    e1 + (-e2)
end

function Base.:-(e::T) where {T<:GaussianRV}
    -1 * e
end

function Base.:*(a::Number, e::T) where {T<:GaussianRV}
    decomp = a * selfdecomp(e)
    return T(decomp)
end

function Base.:*(e::T, a::Number) where {T<:GaussianRV}
    a * e
end


# E[X'Y] = E[X]'E[Y] + Tr(Cov(X, Y))
# E[⟨v_1, v_2⟩] = Tr(Cov(v_1, v_2)) + ⟨E[v_1], E[v_2]⟩
# E[v_1'v_2] = Tr(Cov(v_1, v_2)) + E[v_1]'E[v_2]
# v_1 = μ_1+c_1
# v_2 = μ_2+c_2
# E[(μ_1+c_1)'(μ_2+c_2)] = Tr(Cov(v_1, v_2)) + E[v_1]'E[v_2]
# E[μ_1'μ_2 + μ_1'c_2 + c_1'μ_2 + c_1'c_2] = Tr(Cov(v_1, v_2)) + E[v_1]'E[v_2]
# E[μ_1'μ_2] + E[μ_1'c_2] + E[c_1'μ_2] + E[c_1'c_2] = Tr(Cov(v_1, v_2)) + E[v_1]'E[v_2]
# E[μ_1'c_2] = μ_1'E[c_2] = μ_1'0 = 0
# E[μ_2'c_1] = μ_2'E[c_1] = μ_2'0 = 0
# E[μ_1'μ_2] + E[c_1'c_2] = Tr(Cov(v_1, v_2)) + E[v_1]'E[v_2]
# E[c_1'c_2] + E[μ_1'μ_2] = Tr(Cov(v_1, v_2)) + E[v_1]'E[v_2]
# E[c_1'c_2] = E[(v_1-μ_1)'(v_2-μ_2)] = Tr(Cov(v_1, v_2))
# E[μ_1'μ_2] = E[v_1]'E[v_2]

# use mean and centered component



# E[X'Y] = E[X]'E[Y] + Tr(Cov(X, Y))