"""
    Operator{X,Y}()

An operator from `X` to `Y`.

An operator is a multi-valued function, so each element of `X` maps to a subset of `Y`.
"""
mutable struct Operator{X,Y} <: AbstractOperator{X,Y}
    label::String
    relation::MultiValuedRelation{X,Y}
    
    Operator{X,Y}() where {X,Y} = new{X,Y}("Operator{$X,$Y}", MultiValuedRelation{X,Y}())
end

"""
    Map{X,Y}()

A map from `X` to `Y`.

A map is a single-valued function, so each element of `X` maps to a single element of `Y`.
"""
mutable struct Map{X,Y} <: AbstractFunction{X,Y}
    label::String
    relation::SingleValuedRelation{X,Y}
    associations::Associations
    
    Map{X,Y}() where {X,Y} = new{X,Y}("Map{$X,$Y}", SingleValuedRelation{X,Y}(), Associations())
end

"""
    ConstantMap{X,Y}

A constant map from `X` to `Y`.

For a constant map, there is a unique element of `Y` such that any element of `X` maps to this element.
"""
mutable struct ConstantMap{X,Y} <: AbstractFunction{X,Y}
    label::String
    relation::ConstantRelation{X,Y}
    
    ConstantMap{X,Y}(value = missing) where {X,Y} = new{X,Y}("ConstantMap{$X,$Y}", ConstantRelation{X,Y}(value))
end

"""
    LinearMap{X,Y}()
"""
mutable struct LinearMap{X,Y} <: AbstractLinearMap{X,Y}
    label::String
    relation::SingleValuedRelation{X,Y}
    associations::Associations
    
    LinearMap{X,Y}() where {X,Y} = new{X,Y}("LinearMap{$X,$Y}", SingleValuedRelation{X,Y}(), Dict(Transpose => Map{Y,X}()))
end

"""
    SymmetricLinearMap{X}
"""
mutable struct SymmetricLinearMap{X} <: AbstractSymmetricLinearMap{X}
    label::String
    relation::SingleValuedRelation{X,X}
    
    SymmetricLinearMap{X}() where {X} = new{X}("SymmetricLinearMap{$X}", SingleValuedRelation{X,X}())
end

"""
    SkewSymmetricLinearMap{X}
"""
mutable struct SkewSymmetricLinearMap{X} <: AbstractSkewSymmetricLinearMap{X}
    label::String
    relation::SingleValuedRelation{X,X}
    
    SkewSymmetricLinearMap{X}() where {X} = new{X}("SkewSymmetricLinearMap{$X}", SingleValuedRelation{X,X}())
end

"""
    Functional{X}
"""
mutable struct Functional{X} <: AbstractFunctional{X}
    label::String
    relation::SingleValuedRelation{X,<:Field}
    
    Functional{X}() where {F<:Field, X<:VectorSpace{F}} = new{X}("Functional{$X}", SingleValuedRelation{X,F}())
end

"""
    SubdifferentiableFunctional{X}
"""
mutable struct SubdifferentiableFunctional{X} <: AbstractSubdifferentiableFunctional{X}
    label::String
    relation::SingleValuedRelation{X,<:Field}
    associations::Associations
    
    SubdifferentiableFunctional{X}() where {F<:Field, X<:VectorSpace{F}} = new{X}("SubdifferentiableFunctional{$X}", SingleValuedRelation{X,F}(), Dict(Subdifferential => Operator{X,X}()))
end

"""
    DifferentiableFunctional{X}
"""
mutable struct DifferentiableFunctional{X} <: AbstractDifferentiableFunctional{X}
    label::String
    constraints::Constraints
    relation::SingleValuedRelation{X,<:Field}
    associations::Associations
    
    function DifferentiableFunctional{X}() where {F<:Field, X<:VectorSpace{F}}
        f = new{X}("DifferentiableFunctional{$X}", Constraints(), SingleValuedRelation{X,F}(), Dict(Gradient => Map{X,X}()))
        push!(f'.associations, GradientOf => f)
        f
    end
end

"""
    SmoothStronglyConvexFunction{X}
"""
mutable struct SmoothStronglyConvexFunction{X} <: AbstractDifferentiableFunctional{X}
    id::UUIDs.UUID
    label::String
    constraints::Constraints
    relation::SingleValuedRelation{X,<:Field}
    associations::Associations
    strong_convexity::Number
    smoothness::Number
    
    function SmoothStronglyConvexFunction{X}(m::Number, L::Number) where {F<:Field, X<:VectorSpace{F}}
        f = new{X}(UUIDs.uuid1(Random.RandomDevice()), "SmoothStronglyConvexFunction{$X}", Constraints(), SingleValuedRelation{X,F}(), Dict(Gradient => Map{X,X}()), m, L)
        push!(f'.associations, GradientOf => f)
        f
    end
end

"""
    TwiceDifferentiableFunctional{X}
"""
mutable struct TwiceDifferentiableFunctional{X} <: AbstractTwiceDifferentiableFunctional{X}
    label::String
    constraints::Constraints
    relation::SingleValuedRelation{X,<:Field}
    associations::Associations
    
    TwiceDifferentiableFunctional{X}() where {F<:Field, X<:VectorSpace{F}} = new{X}("TwiceDifferentiableFunctional{$X}", Constraints(), SingleValuedRelation{X,F}(), Dict(Gradient => Map{X,X}(), Hessian => Map{X,SymmetricLinearMap{X}}()))
end

"""
    QuadraticFunctional{X}
"""
mutable struct QuadraticFunctional{X} <: AbstractTwiceDifferentiableFunctional{X}
    label::String
    relation::SingleValuedRelation{X,<:Field}
    associations::Associations
    
    QuadraticFunctional{X}() where {F<:Field, X<:VectorSpace{F}} = new{X}("QuadraticFunctional{$X}", SingleValuedRelation{X,F}(), Dict(Gradient => LinearMap{X,X}(), Hessian => SymmetricLinearMap{X}()))
end

"""
    LinearFunctional{X}
"""
mutable struct LinearFunctional{X} <: AbstractLinearFunctional{X}
    label::String
    relation::SingleValuedRelation{X,<:Field}
    associations::Associations
    value::Union{Decomposition, Missing}

    function LinearFunctional{X}() where {F<:Field, X<:VectorSpace{F}}
        new{X}("LinearFunctional{$X}", SingleValuedRelation{X,F}(), Associations(), missing)
    end

    function LinearFunctional{X}(decomp::Union{Decomposition, Missing}) where {F<:Field, X<:VectorSpace{F}}
        new{X}("", SingleValuedRelation{X,F}(), Associations(), decomp)
    end
end

"""
    ZeroFunctional{X}
"""
mutable struct ZeroFunctional{X} <: AbstractLinearFunctional{X}
    label::String
    relation::SingleValuedRelation{X,<:Field}

    ZeroFunctional{X}() where {F<:Field, X<:VectorSpace{F}} = new{X}("ZeroFunctional{$X}", SingleValuedRelation{X,F}())
end


iszero(o::Oracle) = false
iszero(o::ZeroFunctional) = true

# function (::Type{T})(p::Pair) where {T<:Oracle}
#     if T <: AbstractFunctional
#         if p.second <: Scalar && p.first <: Point{p.second}
#         T{Expression{p.first}}()
#         else
#         error("A functional must be a map from a vector space to its underlying field.")
#         end
#     else
#         T{p.first,p.second}()
#     end
# end

# (::Type{T})(X) where {T<:AbstractFunctional} = T{X}()


############################################################################################
# Methods

"""
    relation(o)

The relation associated with an oracle (or its wrapper).
"""
relation(o::Oracle) = o.relation

function associations(o::Oracle)
    hasproperty(o, :associations) ? o.associations : Associations()
end

"""
    samples(o)

Get the samples associated with an oracle (or its wrapper).

The set of samples is a `Relation`. Iterating an oracle iterates over its samples.
"""
samples(o::Oracle) = samples(relation(o))

description(o::Operator) = "Operator from $(domain(o)) to $(codomain(o))"
description(o::Map) = "Map from $(domain(o)) to $(codomain(o))"
description(o::ConstantMap) = "Constant map from $(domain(o)) to $(codomain(o))"
description(o::LinearMap) = "Linear map from $(domain(o)) to $(codomain(o))"
description(o::SymmetricLinearMap) = "Symmetric linear map from $(domain(o)) to $(codomain(o))"
description(o::SkewSymmetricLinearMap) = "Skew-symmetric linear map from $(domain(o)) to $(codomain(o))"
description(o::Functional) = "Functional on $(domain(o))"
description(o::DifferentiableFunctional) = "Differentiable functional on $(domain(o))"
description(o::SubdifferentiableFunctional) = "Subdifferentiable functional on $(domain(o))"
description(o::TwiceDifferentiableFunctional) = "Twice differentiable functional on $(domain(o))"
description(o::QuadraticFunctional) = "Quadratic functional on $(domain(o))"
description(o::LinearFunctional) = "Linear functional on $(domain(o))"
description(o::ZeroFunctional) = "Zero functional on $(domain(o))"


############################################################################################
# Iterate

length(o::Oracle) = length(samples(o))

iterate(o::Oracle) = iterate(samples(o))
iterate(o::Oracle, state::Int) = iterate(samples(o), state)


############################################################################################
# Sample

"""
    sample(o, x, l = "")

Sample an oracle (or its wrapper) at a point in its domain.

If the relation is single-valued and it has already been sampled at `x`, then the
corresponding point in the codomain is returned. Otherwise, a new point is sampled using
`Y()`, and a default label is used for the sample. A label may be specified for the sampled 
point, or it defaults to an intuitive label.

**Important:** Do not call `sample` directly. Instead, use `o(x)` to sample an oracle at a
point. For linear maps, `o*x` may also be used to denote sampling.

# Examples
```julia-repl
julia> A = LinearFunctional{Rⁿ}()
julia> x = Rⁿ()
julia> isequal(A(x), A*x)  # true
```
"""
function sample end

function sample(o::Oracle, x, l::String = "")
    if iszero(o) || iszero(x)
        return codomain(o)(Zero())
    end
    y = sample(relation(o), x)
    label!(y, isempty(l) ? defaultlabel(o,x) : l)
    push!(x.oracles, o)
    push!(y.oracles, o)
    y
end

sample(::ZeroFunctional{X}, ::X) where {F<:Field, X<:InnerProductSpace{F}} = F(Zero())

function sample(o::AbstractLinearFunctional{X}, x::X) where {F<:Field, X<:VectorSpace{F}}
    # if x is zero, then return the scalar zero
    if iszero(o) || iszero(x)
        return zero(F)
    # else if x is a variable, sample it directly
    elseif isvariable(x)
        y = sample(relation(o), x)
        label!(y, defaultlabel(o,x))
        # if hash(o') > hash(x)
        #     y = sample(relation(o), x)
        #     label!(y, defaultlabel(o,x))
        # else
        #     y = sample(relation(x), o)
        #     label!(y, defaultlabel(x,o))
        # end
        push!(x.oracles, o)
        push!(y.oracles, o)
    # otherwise, sample each element of the decomposition
    else
        y = zero(F)
        for (key,value) ∈ weights(selfdecomp(x))
            y0 = sample(relation(o), key)
            label!(y0, defaultlabel(o, key))
            y += value*y0
            # if hash(o') > hash(key)
            #     y0 = sample(relation(o), key)
            #     label!(y0, defaultlabel(o, key))
            #     y += value*y0
            # else
            #     y0 = sample(key, relation(o))
            #     label!(y0, defaultlabel(key, o))
            #     y += value*y0
            # end
            push!(key.oracles, o)
            push!(y0.oracles, o)
        end
    end
    y
end

# function sample(o::AbstractLinearFunctional{X}, x::X) where {F<:Field, X<:InnerProductSpace{F}}
    
#     if iszero(x) || iszero(o)
#         return zero(F)
#     else
#         yp = o.associations[DualOf]
#         y = sample(relation(o), x)
#         push!(x.oracles, o)
#         push!(y.oracles, o)
#         y
#     end
# end

# function sample(o::LinearDecomposition, x)
#     y = Zero()
#     for (key,value) ∈ weights(o)
#         y0 = sample(relation(key), x)
#         label!(y0, defaultlabel(key, x))
#         push!(key.oracles, o)
#         push!(y0.oracles, o)
#         y += value*y0
#     end
#     y
# end

# Sample a linear function of linear functionals by taking a linear combination of samples of each functional
# function sample(o::LinearDecomposition{T}, x::X) where {F<:Field, X<:VectorSpace{F}, T<:AbstractLinearFunctional{X}}
#     mapreduce( p -> last(p)*sample(first(p), x), +, weights(o); init=F(0) )
# end

# function sample(o::LinearDecomposition, x)
#     mapreduce( p -> last(p)*sample(first(p), x), +, weights(o); init=Zero() )
# end

# Overload () to denote sampling
# """
#     (o::Oracle)(x) = sample(o,x)
# This function overloads () to sample an oracle. To sample oracle `f'` at expression `x0`, use f'(x0)

# ```julia-repl
# julia> x0 = Rⁿ()
# julia> f = DifferentiableFunctional{Rⁿ}()
# julia> f'(x0)
# """
(o::Oracle)(x) = sample(o,x)

# For linear maps, also use * to denote sampling
# """
#     *(o::Union{OrWrapper{AbstractLinearMap},OrWrapper{AbstractLinearFunctional},OrWrapper{AbstractSymmetricLinearMap},Dual}, x) = sample(o,x)
# This function overloads * to sample a linear map oracle. To sample oracle `Σ'` at expression `x0`, use Σ*x0

# ```julia-repl
# julia> x0 = Rⁿ()
# julia> Σ = SymmetricLinearMap{Rⁿ}()
# julia> Σ*x0
# """

# TODO: take care of Dual
*(o::Union{AbstractLinearMap,AbstractLinearFunctional,AbstractSymmetricLinearMap}, x) = sample(o,x)

# function *(o::Dual{X}, x::X) where {F<:Field, X<:VectorSpace{F}}
#     if iszero(o) || iszero(x)
#         F(Zero())
#     else
#         y = F(Zero())
#         for (key1,val1) ∈ weights(selfdecomp(o')), (key2,val2) ∈ weights(selfdecomp(x))
#             # Inner product ordering done by hash
#             if hash(key2) < hash(key1)
#                 orc = key2'
#                 y0 = sample(relation(orc), key1)
#                 label!(y0, defaultlabel(key2', key1))
#                 push!(key1.oracles, orc)
#                 push!(y0.oracles, orc)
#                 y += val1 * val2 * y0
#             else
#                 orc = key1'
#                 y0 = sample(relation(orc), key2)
#                 label!(y0, defaultlabel(key1', key2))
#                 push!(key2.oracles, orc)
#                 push!(y0.oracles, orc)
#                 y += val1 * val2 * y0
#             end
#         end
#         y
#     end
# end


############################################################################################
# Inputs / outputs

inputs(o::Oracle) = Set(first(p) for p ∈ o)
outputs(o::Oracle) = Set(last(p) for p ∈ o)

inputs(s::Set{<:Oracle}) = mapreduce(inputs, ∪, s)
outputs(s::Set{<:Oracle}) = mapreduce(outputs, ∪, s)

domain(::AbstractOperator{X,Y}) where {X,Y} = X
codomain(::AbstractOperator{X,Y}) where {X,Y} = Y
codomain(::AbstractFunctional{X}) where {F<:Field, X<:VectorSpace{F}} = F

function inputs_outputs(o::Oracle)
    pairs = collect(samples(o))
    ([first(p) for p ∈ pairs], [last(p) for p ∈ pairs])
end

function get_oracle_input(e::Expression) # Get the oracle and the expression used to create en expression
    if !(e isa Gram) && hasproperty(e, :oracles) && hasmethod(oracles, Tuple{typeof(e)}) # Check if the expression has oracles
        if length((oracles(e))) > 0
            for o in oracles(e)
                io = inputs_outputs(o)
                index = findfirst(isequal(e), io[2])
                if !isnothing(index)  
                    return o, io[1][index] # Return the oracle and the sampled expression
                end
            end
        end
    end
    return missing, missing
    # error("No oracle had the expression $(e) as an output") # No oracle was found
end