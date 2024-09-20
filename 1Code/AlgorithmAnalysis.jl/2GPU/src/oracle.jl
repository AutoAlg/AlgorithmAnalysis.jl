"""
    Operator{X,Y}()

An operator from `X` to `Y`.

An operator is a multi-valued function, so each element of `X` maps to a subset of `Y`.
"""
mutable struct Operator{X,Y} <: AbstractOperator{X,Y}
    label::String
    properties::Properties
    relation::MultiValuedRelation{X,Y}
    
    Operator{X,Y}() where {X,Y} = new{X,Y}("Operator{$X,$Y}", Properties(), MultiValuedRelation{X,Y}())
end

"""
    Map{X,Y}()

A map from `X` to `Y`.

A map is a single-valued function, so each element of `X` maps to a single element of `Y`.
"""
mutable struct Map{X,Y} <: AbstractFunction{X,Y}
    label::String
    properties::Properties
    relation::SingleValuedRelation{X,Y}
    
    Map{X,Y}() where {X,Y} = new{X,Y}("Map{$X,$Y}", Properties(), SingleValuedRelation{X,Y}())
end

"""
    ConstantMap{X,Y}(value = missing)

A constant map from `X` to `Y`.

For a constant map, there is a unique element of `Y` such that any element of `X` maps to this element.
"""
mutable struct ConstantMap{X,Y} <: AbstractFunction{X,Y}
    label::String
    properties::Properties
    relation::ConstantRelation{X,Y}
    
    ConstantMap{X,Y}(value = missing) where {X,Y} = new{X,Y}("ConstantMap{$X,$Y}", Properties(), ConstantRelation{X,Y}(value))
end

"""
    LinearMap{X,Y}()
"""
mutable struct LinearMap{X,Y} <: AbstractLinearMap{X,Y}
    label::String
    properties::Properties
    relation::SingleValuedRelation{X,Y}
    associations::Associations
    
    LinearMap{X,Y}() where {X,Y} = new{X,Y}("LinearMap{$X,$Y}", Properties([Linear()]), SingleValuedRelation{X,Y}(), Dict(Transpose => Map{Y,X}()))
end

mutable struct SymmetricLinearMap{X} <: AbstractSymmetricLinearMap{X}
    label::String
    properties::Properties
    relation::SingleValuedRelation{X,X}
    
    SymmetricLinearMap{X}() where {X} = new{X}("SymmetricLinearMap{$X}", Properties([Symmetric()]), SingleValuedRelation{X,X}())
end

mutable struct SkewSymmetricLinearMap{X} <: AbstractSkewSymmetricLinearMap{X}
    label::String
    properties::Properties
    relation::SingleValuedRelation{X,X}
    
    SkewSymmetricLinearMap{X}() where {X} = new{X}("SkewSymmetricLinearMap{$X}", Properties([SkewSymmetric()]), SingleValuedRelation{X,X}())
end

"""
    Functional{X}
"""
mutable struct Functional{X} <: AbstractFunctional{X}
    label::String
    properties::Properties
    relation::SingleValuedRelation{X,<:Field}
    
    Functional{X}() where {F<:Field, X<:VectorSpace{F}} = new{X}("Functional{$X}", Properties(), SingleValuedRelation{X,F}())
end

mutable struct SubdifferentiableFunctional{X} <: AbstractSubdifferentiableFunctional{X}
    label::String
    properties::Properties
    relation::SingleValuedRelation{X,<:Field}
    associations::Associations
    
    SubdifferentiableFunctional{X}() where {F<:Field, X<:VectorSpace{F}} = new{X}("SubdifferentiableFunctional{$X}", Properties(), SingleValuedRelation{X,F}(), Dict(Subdifferential => Operator{X,X}()))
end

mutable struct DifferentiableFunctional{X} <: AbstractDifferentiableFunctional{X}
    label::String
    properties::Properties
    relation::SingleValuedRelation{X,<:Field}
    associations::Associations
    
    DifferentiableFunctional{X}() where {F<:Field, X<:VectorSpace{F}} = new{X}("DifferentiableFunctional{$X}", Properties(), SingleValuedRelation{X,F}(), Dict(Gradient => Map{X,X}()))
end

mutable struct TwiceDifferentiableFunctional{X} <: AbstractTwiceDifferentiableFunctional{X}
    label::String
    properties::Properties
    relation::SingleValuedRelation{X,<:Field}
    associations::Associations
    
    TwiceDifferentiableFunctional{X}() where {F<:Field, X<:VectorSpace{F}} = new{X}("TwiceDifferentiableFunctional{$X}", Properties(), SingleValuedRelation{X,F}(), Dict(Gradient => Map{X,X}(), Hessian => Map{X,SymmetricLinearMap{X}}()))
end

mutable struct QuadraticFunctional{X} <: AbstractTwiceDifferentiableFunctional{X}
    label::String
    properties::Properties
    relation::SingleValuedRelation{X,<:Field}
    associations::Associations
    
    QuadraticFunctional{X}() where {F<:Field, X<:VectorSpace{F}} = new{X}("QuadraticFunctional{$X}", Properties(), SingleValuedRelation{X,F}(), Dict(Gradient => LinearMap{X,X}(), Hessian => SymmetricLinearMap{X}()))
end

mutable struct LinearFunctional{X} <: AbstractLinearFunctional{X}
    label::String
    properties::Properties
    relation::SingleValuedRelation{X,<:Field}

    function LinearFunctional{X}() where {F<:Field, X<:VectorSpace{F}}
        new{X}("LinearFunctional{$X}", Properties([Linear()]), SingleValuedRelation{X,F}())
    end
end

mutable struct ZeroFunctional{X} <: AbstractLinearFunctional{X}
    label::String
    properties::Properties
    relation::SingleValuedRelation{X,<:Field}
    
    ZeroFunctional{X}() where {X} = new{X}("ZeroFunctional{$X}", Properties())  # [Linear()]
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
    oracle(o)

Get the oracle associated with a wrapper.

# Examples
```julia-repl
julia> A = LinearOperator{Rⁿ}()
julia> oracle(A') == A.transpose  # true
```
"""
# oracle(o::Oracle) = o
# oracle(w::Wrapper{<:Oracle}) = unwrap(w)

"""
    relation(o)

The relation associated with an oracle (or its wrapper).
"""
relation(o::OracleOrWrapper) = unwrap(o).relation

"""
    associations(o)

Get the set of oracles associated with the oracle `o`.
"""
function associations(o::OracleOrWrapper)
    hasproperty(unwrap(o), :associations) ? unwrap(o).associations : Associations()
end

"""
    samples(o)

Get the samples associated with an oracle (or its wrapper).

The set of samples is a `Relation`. Iterating an oracle iterates over its samples.
"""
samples(o::OracleOrWrapper) = samples(relation(o))

"""
    description(o)

Get a description of an oracle (or its wrapper).
"""
description(w::W) where {W<:Wrapper{<:Oracle}} = "$(string(Base.typename(W).wrapper)) of $(label(w.parent))"
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

length(o::OracleOrWrapper) = length(samples(o))

iterate(o::OracleOrWrapper) = iterate(samples(o))
iterate(o::OracleOrWrapper, state::Int) = iterate(samples(o), state)


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

sample(w::Wrapper, x, l::String = "") = sample(unwrap(w), x, l)

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
        F(Zero())
        
    # else if x has an empty decomposition, sample it directly
    elseif isempty(decomposition(x))
        y = sample(relation(o), x)
        label!(y, defaultlabel(o,x))
        push!(x.oracles, o)
        push!(y.oracles, o)
        y
        
    # otherwise, sample each element of the decomposition
    else
        y = F(Zero())
        for (key,value) ∈ weights(selfdecomp(x))
            y0 = sample(relation(o), key)
            label!(y0, defaultlabel(o, key))
            push!(key.oracles, o)
            push!(y0.oracles, o)
            y += value*y0
        end
        y
    end
end

# function sample(o::AbstractLinearFunctional{X}, x::X) where {F<:Field, X<:InnerProductSpace{F}}
    
#     if iszero(x) || iszero(o)
#         F(0)
#     else
#         y = sample(relation(o), x)
#         label!(y, isempty(label) ? defaultlabel(o,x) : label)
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
(o::OracleOrWrapper)(x) = sample(o,x)

# For linear maps, also use * to denote sampling
*(o::Union{OrWrapper{AbstractLinearMap},OrWrapper{AbstractLinearFunctional},Dual}, x) = sample(o,x)

function *(o::Dual{X}, x::X) where {F<:Field, X<:VectorSpace{F}}

    if iszero(o) || iszero(x)
        F(Zero())
    else
        y = F(Zero())
        for (key1,val1) ∈ weights(selfdecomp(o')), (key2,val2) ∈ weights(selfdecomp(x))
            orc = unwrap(key1')
            y0 = sample(relation(orc), key2)
            label!(y0, defaultlabel(key1', key2))
            push!(key2.oracles, orc)
            push!(y0.oracles, orc)
            y += val1 * val2 * y0
        end
        y
    end
end


############################################################################################
# Properties

properties(o::OracleOrWrapper) = unwrap(o).properties

∈(o::OracleOrWrapper, property::Property) = push!(properties(o), property)
∈(o::OracleOrWrapper, properties::Properties) = map(property -> o ∈ property, properties)


############################################################################################
# Inputs / outputs

inputs(o::OracleOrWrapper) = Set(first(p) for p ∈ unwrap(o))
outputs(o::OracleOrWrapper) = Set(last(p) for p ∈ unwrap(o))

inputs(s::Set{<:OracleOrWrapper}) = mapreduce(inputs, ∪, s)
outputs(s::Set{<:OracleOrWrapper}) = mapreduce(outputs, ∪, s)

domain(::AbstractOperator{X,Y}) where {X,Y} = X
codomain(::AbstractOperator{X,Y}) where {X,Y} = Y
codomain(::AbstractFunctional{X}) where {F<:Field, X<:VectorSpace{F}} = F

function inputs_outputs(o::OracleOrWrapper)
    pairs = collect(samples(o))
    ([first(p) for p ∈ pairs], [last(p) for p ∈ pairs])
end

domain(w::Wrapper{<:Oracle}) = domain(unwrap(w))
codomain(w::Wrapper{<:Oracle}) = codomain(unwrap(w))


############################################################################################
# Hierarchy

AbstractTrees.children(d::Union{DataType,UnionAll}) = InteractiveUtils.subtypes(d)

"""
    hierarchy(datatype)
    
Print the subtype hierarchy of a datatype.

# Examples
```julia-repl
julia> hierarchy(Oracle)
```
"""
hierarchy(d::DataType) = AbstractTrees.print_tree(d; maxdepth=10)
