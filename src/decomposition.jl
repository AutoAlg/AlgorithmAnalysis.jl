############################################################################################
# DECOMPOSITION

"""
    EmptyDecomposition

An empty decomposition.
"""
struct EmptyDecomposition{T} <: Decomposition{T} end

Decomposition{T}() where{T} = EmptyDecomposition{T}()


"""
    LinearDecomposition

Decomposition of an expression as a linear function of other expressions.

# Fields
    weights::Dict{T, Number}

# Constructors
    LinearDecomposition{T}()
    LinearDecomposition{T}(x)
    LinearDecomposition{T}(weights)
"""
mutable struct LinearDecomposition{T} <: AbstractLinearDecomposition{T}
    label::String
    weights::Dict{T, DecompositionValue}

    LinearDecomposition{T}() where {T} = new{T}("",Dict{T,DecompositionValue}())

    LinearDecomposition(x::T) where {T} = new{T}("",Dict{T,DecompositionValue}(x=>1))

    function LinearDecomposition{T}(weights::Dict{<:T,<:DecompositionValue}) where {T}
        new{T}( "", Dict{T,DecompositionValue}(weights) )
    end
end

label(x::Decomposition) = x.label
label(::EmptyDecomposition) = "Empty decomposition"
label!(x::Decomposition, label::String) = (x.label=label; nothing)
label!(::EmptyDecomposition, label::String) = nothing

"Weights of a linear decomposition."
weights(x::LinearDecomposition) = x.weights

"Check if a decomposition is empty."
isempty(x::LinearDecomposition) = isempty(weights(x))
isempty(::EmptyDecomposition) = true

iszero(::Decomposition) = false

prune(d::Dict) = filter( p -> !iszero(first(p)) && !iszero(last(p)), d )

prune(x::LinearDecomposition{T}) where {T} = isempty(weights(x)) ? T(Zero()) : x

value(x::LinearDecomposition) = mapreduce( p->last(p)*value(first(p)), +, weights(x); init=Zero() )

function variables(x::LinearDecomposition)
    mapreduce( v -> !hasvalue(v) ? variables(v) : Expressions(), ∪, keys(weights(x)); init=Expressions())
end

function constant(x::LinearDecomposition)
    y = Zero()
    for (key,val) ∈ weights(x)
        if hasvalue(key)
            y += val * value(key)
        end
    end
    y
end

zero(::LinearDecomposition) = Zero()
