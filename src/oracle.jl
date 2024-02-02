# Oracle (o,o',o'',...)
#  - AbstractOperator: o: X → Y
#    - Operator**
#    - AbstractFunction
#      - Map**
#      - ConstantMap**
#      - AbstractLinearMap: tranpose o': Y → X (Map)
#        - LinearMap*
#        - AbstractSymmetricLinearMap: o' = o: X → X
#          - SymmetricLinearMap*
#        - AbstractSkewSymmetricLinearMap: o' = -o: X → X
#          - SkewSymmetricLinearMap*
#      - AbstractFunctional: o: X → R
#        - Functional*
#        - AbstractSubdifferentiableFunctional: subdifferential o': X ⇉ X (Operator)
#          - SubdifferentiableFunctional*
#          - AbstractDifferentiableFunctional: gradient o': X → X (Map)
#            - DifferentiableFunctional*
#            - AbstractTwiceDifferentiableFunctional: hessian o'': X → X ⊗ X (Map)
#              - TwiceDifferentiableFunctional*
#              - QuadraticFunctional*


############################################################################################
# Oracles

const Associations = Dict{Type{<:Wrapper}, Oracle}

"""
    Operator{X,Y}()

An operator from `X` to `Y`.

An operator is a multi-valued function, so each element of `X` maps to a subset of `Y`.
"""
mutable struct Operator{X,Y} <: AbstractOperator{X,Y}
    label::String
    properties::Properties
    relation::Set{Pair{X,Y}}
    
    Operator{X,Y}() where {X,Y} = new{X,Y}("", Properties(), Set{Pair{X,Y}}())
end

"""
    Map{X,Y}()

A map from `X` to `Y`.

A map is a single-valued function, so each element of `X` maps to a single element of `Y`.
"""
mutable struct Map{X,Y} <: AbstractFunction{X,Y}
    label::String
    properties::Properties
    relation::Dict{X,Y}
    
    Map{X,Y}() where {X,Y} = new{X,Y}("", Properties(), Dict{X,Y}())
end

"""
    ConstantMap{X,Y}(value = missing)

A constant map from `X` to `Y`.

For a constant map, there is a unique element of `Y` such that any element of `X` maps to this element.
"""
mutable struct ConstantMap{X,Y} <: AbstractFunction{X,Y}
    label::String
    properties::Properties
    value::Union{Y,Missing}
    
    ConstantMap{X,Y}(value = missing) where {X,Y} = new{X,Y}("", Properties(), value)
end

"""
    LinearMap{X,Y}()
"""
mutable struct LinearMap{X,Y} <: AbstractLinearMap{X,Y}
    label::String
    properties::Properties
    value::Map{X,Y}
    associations::Associations
    
    LinearMap{X,Y}() where {X,Y} = new{X,Y}("", Properties([Linear()]), Map{X,Y}(), Dict(Transpose => Map{Y,X}()))
end

mutable struct SymmetricLinearMap{X} <: AbstractSymmetricLinearMap{X}
    label::String
    properties::Properties
    value::LinearMap{X,X}
    
    SymmetricLinearMap{X}() where {X} = new{X}("", Properties([Symmetric()]), LinearMap{X,X}())
end

mutable struct SkewSymmetricLinearMap{X} <: AbstractSkewSymmetricLinearMap{X}
    label::String
    properties::Properties
    value::LinearMap{X,X}
    
    SkewSymmetricLinearMap{X}() where {X} = new{X}("", Properties([SkewSymmetric()]), LinearMap{X,X}())
end

"""
    Functional{X}
"""
mutable struct Functional{X} <: AbstractFunctional{X}
    label::String
    properties::Properties
    value::Map
    
    Functional{X}() where {F<:Field, X<:VectorSpace{F}} = new{X}("", Properties(), Map{X,F}())
end

mutable struct SubdifferentiableFunctional{X} <: AbstractSubdifferentiableFunctional{X}
    label::String
    properties::Properties
    value::Functional{X}
    associations::Associations
    
    SubdifferentiableFunctional{X}() where {X} = new{X}("", Properties(), Functional{X}(), Dict(Subdifferential => Operator{X,X}()))
end

mutable struct DifferentiableFunctional{X} <: AbstractDifferentiableFunctional{X}
    label::String
    properties::Properties
    value::Functional{X}
    associations::Associations
    
    DifferentiableFunctional{X}() where {X} = new{X}("", Properties(), Functional{X}(), Dict(Gradient => Map{X,X}()))
end

mutable struct TwiceDifferentiableFunctional{X} <: AbstractTwiceDifferentiableFunctional{X}
    label::String
    properties::Properties
    value::Functional{X}
    associations::Associations
    
    TwiceDifferentiableFunctional{X}() where {X} = new{X}("", Properties(), Functional{X}(), Dict(Gradient => Map{X,X}(), Hessian => Map{X,SymmetricLinearMap{X}}()))
end

mutable struct QuadraticFunctional{X} <: AbstractTwiceDifferentiableFunctional{X}
    label::String
    properties::Properties
    value::Functional{X}
    associations::Associations
    
    QuadraticFunctional{X}() where {X} = new{X}("", Properties(), Functional{X}(), Dict(Gradient => LinearMap{X,X}(), Hessian => SymmetricLinearMap{X}()))
end

mutable struct LinearFunctional{X} <: AbstractLinearFunctional{X}
    label::String
    properties::Properties
    value::Functional{X}
    dual::Union{X,Missing}
    
    # linear functionals are always the dual of a vector
    LinearFunctional{X}() where {X} = new{X}("", Properties([Linear()]), Functional{X}(), missing)
    LinearFunctional{X}(x::X) where {X} = new{X}("", Properties([Linear()]), Functional{X}(), x)
end

mutable struct ZeroFunctional{X} <: AbstractLinearFunctional{X}
    label::String
    properties::Properties
    
    ZeroFunctional{X}() where {X} = new{X}("", Properties([Linear()]))
end

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
    oracle(w)

Get the oracle associated with a wrapper.

# Examples
```julia-repl
julia> A = LinearOperator{Rⁿ}()
julia> oracle(A') == A.transpose  # true
```
"""
oracle(o::Oracle) = o
oracle(w::Wrapper{<:Oracle}) = unwrap(w)

"""
    superoracle(o)

Get the suproracle associated with an oracle (or its wrapper).

# Examples
```julia-repl
julia> A = Map{Rⁿ,Rᵐ}();     # an oracle
julia> superoracle(A) == A   # true
julia> superoracle(A') == A  # true
```
"""
superoracle(o::Oracle) = o
superoracle(w::Wrapper{<:Oracle}) = w.parent

"""
    suboracle(o)

Get the suboracle associated with an oracle (or its wrapper).

- For simple oracles (such as [`Operator`](@ref), [`Map`](@ref), [`ConstantMap`](@ref)), returns the oracle itself.
- For compound oracles, returns the suboracle `o.value`.

# Examples
```julia-repl
julia> A = Map{Rⁿ,Rᵐ}();        # a simple oracle
julia> suboracle(A) == A        # true
julia> B = LinearMap{Rⁿ,Rᵐ}();  # a compound oracle
julia> suboracle(B) == B.value  # true
```
"""
suboracle(o::Union{Map,Operator,ConstantMap,ZeroFunctional}) = o
suboracle(o::Oracle) = o.value
suboracle(w::Wrapper{<:Oracle}) = unwrap(w)

"""
    suboracles(o)

Get a vector of suboracles associated with an oracle (or its wrapper).
"""
function suboracles(o::OracleOrWrapper)
    v = Vector{Oracle}()
    while true
        push!(v, oracle(o))
        isequal(oracle(o), suboracle(o)) && break
        o = suboracle(o)
    end
    v
end

"""
    associations(o)

Get the set of oracles associated with the oracle `o`.
"""
associations(o::OracleOrWrapper) = hasproperty(oracle(o), :associations) ? oracle(o).associations : Associations()

"""
    samples(o)

Get the samples associated with an oracle (or its wrapper).

The set of samples is a `Relation`. Iterating an oracle iterates over its samples.
"""
samples(o::Operator) = Relation(o.relation)
samples(o::Map) = Relation(o.relation)
samples(o::ConstantMap) = o.value
samples(o::ZeroFunctional{X}) where {F<:Field, X<:VectorSpace{F}} = Relation{X,F}()
samples(o::Oracle) = samples(o.value)
samples(w::Wrapper{<:Oracle}) = samples(suboracle(w))

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
description(o::Functional) = "Function on $(domain(o))"
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

If the relation is single-valued and it has already been sampled at `x`, then the corresponding
point in the codomain is returned. Otherwise, a new point is sampled using `Y()`, and a
default label is used for the sample. A label may be specified for the sampled point, or
it defaults to an intuitive label.

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

# by default, sample the suboracle (specialized for primitive oracles)
sample(o::OracleOrWrapper, x, l::String = "") = sample(suboracle(o), x, l)

sample(o::Operator{<:X,Y}, x::X, l::String = "") where {X,Y} = (y=Y(isempty(l) ? label(o)*"("*label(x)*")" : l); push!(samples(o), x => y); y)

sample(o::Map{<:X,Y}, x::X, l::String = "") where {X,Y} = haskey(o.relation, x) ? o.relation[x] : (y=Y(isempty(l) ? label(o)*"("*label(x)*")" : l); push!(o.relation, x=>y); y)

sample(o::ConstantMap{<:X,Y}, x::X, l::String = "") where {X,Y} = !ismissing(o.value) ? o.value : (y=Y(isempty(l) ? label(o) : l); o.value=y; y)

sample(o::ZeroFunctional{X}, x::X) where {F<:Field, X<:InnerProductSpace{F}} = F(0)

function sample(o::AbstractLinearFunctional{X}, x::X) where {F<:Field, X<:InnerProductSpace{F}}
    
    # if x is zero, then return the scalar zero
    if iszero(x)
        F(Zero())
        
    # else if x has an empty decomposition, sample it directly
    elseif isempty(decomposition(x))
        sample(suboracle(o), x, isequal(x,o') ? "|"*label(x)*"|²" : "⟨"*label(o')*","*label(x)*"⟩")
        
    # otherwise, sample each element of the decomposition
    else
        mapreduce( p -> last(p)*sample(suboracle(o), first(p), isequal(first(p),o') ? "|"*label(o')*"|²" : "⟨"*label(o')*","*label(first(p))*"⟩"), +, weights(selfdecomp(x)); init=F(0) )
    end
end

# Sample a linear function of linear functionals by taking a linear combination of samples of each functional
function sample(o::LinearDecomposition{T}, x::X) where {F<:Field, X<:VectorSpace{F}, T<:AbstractLinearFunctional{X}}
    mapreduce( p -> last(p)*sample(first(p), x), +, weights(o); init=F(0) )
end

# Overload () to denote sampling
(o::OracleOrWrapper)(x) = sample(o,x)

# For linear maps, also use * to denote sampling
*(o::Union{AbstractLinearMap,AbstractLinearFunctional,Wrapper{<:AbstractLinearMap},Wrapper{<:AbstractLinearFunctional}}, x) = sample(o,x)


############################################################################################
# Properties

properties(o::OracleOrWrapper) = oracle(o).properties

∈(o::OracleOrWrapper, property::Property) = push!(properties(o), property)
∈(o::OracleOrWrapper, properties::Properties) = map(property -> o ∈ property, properties)

"""
    allproperties(o)
    
Get all properties of an oracle (including suboracles).
"""
allproperties(o::OracleOrWrapper) = mapreduce(properties, ∪, suboracles(o); init=Properties())


############################################################################################
# Inputs / outputs

inputs(o::OracleOrWrapper) = Set(first(p) for p ∈ oracle(o))
outputs(o::OracleOrWrapper) = Set(last(p) for p ∈ oracle(o))

domain(::AbstractOperator{X,Y}) where {X,Y} = X
codomain(::AbstractOperator{X,Y}) where {X,Y} = Y
codomain(::AbstractFunctional{X}) where {F<:Field, X<:VectorSpace{F}} = F

inputs_outputs(o::OracleOrWrapper) = (pairs=collect(samples(o)); ([first(p) for p ∈ pairs], [last(p) for p ∈ pairs]))

domain(w::Wrapper{<:Oracle}) = domain(oracle(w))
codomain(w::Wrapper{<:Oracle}) = codomain(oracle(w))


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
