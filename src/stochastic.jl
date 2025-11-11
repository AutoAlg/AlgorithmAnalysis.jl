import Base: show, IO, convert, promote_rule

export GaussianRV, expectation, centered, tr_covariance, expected_inner_product

# TODO: figure out RV naming issues with subfields
# TODO: move stuff out of this file


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
        # We need to find the Field (F) and Space (T) types
        # from the components of the decomposition.
        first_comp = first(keys(weights(decomp)))
        
        # 1. Create the new mean component by summing the means
        #    (This uses the recursive 'expectation' helper)
        new_mean_decomp = mapreduce(p -> last(p) * expectation(first(p)), +, weights(decomp))
        
        # 2. Create the new centered component
        #    (This uses the recursive 'centered' helper)
        new_centered_decomp = mapreduce(p -> last(p) * centered(first(p)), +, weights(decomp))

        # 3. Create a new "base" GaussianRV to hold the results
        g_new = GaussianRV{F, T}("Decomp") 
        
        # 4. Assign the new (decomposed) components
        g_new.mean = new_mean_decomp
        g_new.centered = new_centered_decomp
        
        # 5. Store the original decomposition in the .value field
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
    # This just calls the recursive helper from Step 2
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
    # 1. Calls promote(e1, e2) -> (g_lifted, e2)
    # 2. Calls +(g_lifted, e2)
    +(promote(e1, e2)...)
end

# Catches: GaussianRV + Rⁿ
function Base.:+(e1::GaussianRV{F, T}, e2::T) where {F<:Field, T<:InnerProductSpace{F}}
    # 1. Calls promote(e1, e2) -> (e1, g_lifted)
    # 2. Calls +(e1, g_lifted)
    +(promote(e1, e2)...)
end

function Base.:+(e1::T, e2::T) where {T<:GaussianRV}
    if iszero(e1)
        return e2
    elseif iszero(e2)
        return e1
    end
    
    # Create a LinearDecomposition, just like the
    # + function for AbstractVectorSpace
    decomp = selfdecomp(e1) + selfdecomp(e2)

    # This will call the T(decomp) constructor,
    # which we'll add in the next step.
    return T(decomp) 
end


function Base.:-(e1::T, e2::GaussianRV{F, T}) where {F<:Field, T<:InnerProductSpace{F}}
    -(promote(e1, e2)...)
end

# Catches: GaussianRV - Rⁿ
function Base.:-(e1::GaussianRV{F, T}, e2::T) where {F<:Field, T<:InnerProductSpace{F}}
    -(promote(e1, e2)...)
end

# Handles: GaussianRV - GaussianRV
function Base.:-(e1::T, e2::T) where {T<:GaussianRV}
    # This just re-uses the '+' and unary '-' methods
    e1 + (-e2)
end

# Handles: -GaussianRV
function Base.:-(e::T) where {T<:GaussianRV}
    # Relies on scalar multiplication
    -1 * e
end

# Handles: Number * GaussianRV
function Base.:*(a::Number, e::T) where {T<:GaussianRV}
    # Creates a decomposition and re-builds the
    # GaussianRV using your new constructor
    decomp = a * selfdecomp(e)
    return T(decomp)
end

# Handles: GaussianRV * Number
function Base.:*(e::T, a::Number) where {T<:GaussianRV}
    # Make it commutative
    a * e
end