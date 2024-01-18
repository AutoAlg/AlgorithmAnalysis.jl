# Oracle (o,o',o'',...)
#  - AbstractOperator: o: X → Y
#    - Operator*
#    - AbstractFunction
#      - Map*
#      - ConstantMap*
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

# some constraint properties dictate what dual operators are available (e.g., linear implies that o' is the adjoint)
# some constraint properties simplify the structure of the oracle (e.g., symmetric implies o' = o)
# other properties don't do either (e.g., monotone)

# Relations
#  - MultiValuedRelation
#  - SingleValuedRelation
#  - ConstantRelation


############################################################################################
# Concrete oracles

mutable struct Operator{X,Y} <: AbstractOperator{X,Y}
    label::String
    properties::Properties
    value::Relation{X,Y}
    
    Operator{X,Y}() where {X,Y} = new{X,Y}("", Properties(), Relation{X,Y}())
end

mutable struct Map{X,Y} <: AbstractFunction{X,Y}
    label::String
    properties::Properties
    value::Relation{X,Y}
    
    Map{X,Y}() where {X,Y} = new{X,Y}("", Properties(), Relation{X,Y}())
end

mutable struct ConstantMap{X,Y} <: AbstractFunction{X,Y}
    label::String
    properties::Properties
    value::Relation{X,Y}
    
    ConstantMap{X,Y}() where {X,Y} = new{X,Y}("", Properties(), Relation{X,Y}())
end

"""
    LinearMap{X,Y}
"""
mutable struct LinearMap{X,Y} <: AbstractLinearMap{X,Y}
    label::String
    properties::Properties
    value::Map{X,Y}
    transpose::Map{Y,X}
    
    LinearMap{X,Y}() where {X,Y} = new{X,Y}("", Properties([Linear()]), Map{X,Y}(), Map{Y,X}())
end

mutable struct SymmetricLinearMap{X} <: AbstractSymmetricLinearMap{X}
    label::String
    properties::Properties
    value::LinearMap{X,X}
    
    SymmetricLinearMap{X}() where {X} = new{X}("", Properties([Linear(),Symmetric()]), LinearMap{X,X}())
end

mutable struct SkewSymmetricLinearMap{X} <: AbstractSkewSymmetricLinearMap{X}
    label::String
    properties::Properties
    value::LinearMap{X,X}
    
    SkewSymmetricLinearMap{X}() where {X} = new{X}("", Properties([Linear(),SkewSymmetric()]), LinearMap{X,X}())
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
    subdifferential::Operator{X,X}
    
    SubdifferentiableFunctional{X}() where {X} = new{X}("", Properties(), Functional{X}(), Operator{X,X}())
end

mutable struct DifferentiableFunctional{X} <: AbstractDifferentiableFunctional{X}
    label::String
    properties::Properties
    value::Functional{X}
    gradient::Map{X,X}
    
    DifferentiableFunctional{X}() where {X} = new{X}("", Properties(), Functional{X}(), Map{X,X}())
end

mutable struct TwiceDifferentiableFunctional{X} <: AbstractTwiceDifferentiableFunctional{X}
    label::String
    properties::Properties
    value::Functional{X}
    gradient::Map{X,X}
    hessian::Map{X,SymmetricLinearMap{X}}
    
    TwiceDifferentiableFunctional{X}() where {X} = new{X}("", Properties(), Functional{X}(), Map{X,X}(), Map{X,SymmetricLinearMap{X}}())
end

mutable struct QuadraticFunctional{X} <: AbstractTwiceDifferentiableFunctional{X}
    label::String
    properties::Properties
    value::Functional{X}
    gradient::LinearMap{X,X} # Affine
    hessian::ConstantMap{X,SymmetricLinearMap{X}} # SymmetricLinearMap{X}
    
    QuadraticFunctional{X}() where {X} = new{X}("", Properties(), Functional{X}(), LinearMap{X,X}(), ConstantMap{X,SymmetricLinearMap{X}}())
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


function (::Type{T})(p::Pair) where {T<:Oracle}
    if T <: AbstractFunctional
        if p.second <: Scalar && p.first <: Point{p.second}
        T{Expression{p.first}}()
        else
        error("A functional must be a map from a vector space to its underlying field.")
        end
    else
        T{p.first,p.second}()
    end
end

(::Type{T})(X) where {T<:AbstractFunctional} = T{X}()


############################################################################################
# Methods

"""
    oracle(w)
    
Get the oracle associated with a wrapper.
"""
oracle(o::Oracle) = o
oracle(w::Wrapper{<:Oracle}) = unwrap(w)

"""
    suboracle(o)
    
Get the suboracle associated with a (complex) oracle.

# Examples
```julia-repl
julia> 
```
"""
suboracle(o::Union{Map,Operator,ConstantMap}) = o
suboracle(o::Oracle) = o.value
suboracle(w::Wrapper{<:Oracle}) = unwrap(w)

"""
    relation(o)
    
Get the relation associated with an oracle.
"""
relation(o::Union{Map,Operator,ConstantMap}) = o.value
relation(o::Oracle) = relation(o.value)
relation(w::Wrapper{<:Oracle}) = relation(suboracle(w))

"""
    samples(o)

Get the samples associated with an oracle.
"""
samples(o::OracleOrWrapper) = samples(relation(o))


############################################################################################
# Iterate

length(o::OracleOrWrapper) = length(samples(o))

iterate(o::OracleOrWrapper) = iterate(samples(o))
iterate(o::OracleOrWrapper, state::Int) = iterate(samples(o), state)


############################################################################################
# Sample

"""
    sample(o, x, [label])

Sample an oracle (or its wrapper) at a point in its domain.

If the relation is single-valued and it has already been sampled at `x`, then the corresponding
point in the codomain is returned. Otherwise, a new point is sampled using `Y(label)`.

For linear maps, `*` may also be used to denote sampling.

# Examples
```julia-repl
julia> A = LinearFunctional{Rⁿ}()
julia> x = Rⁿ()
julia> A(x) == A*x  # true
```
"""
function sample end

sample(o::OracleOrWrapper, x) = sample(suboracle(o), x)

# sample the oracle at a new point in its domain
_sample(o::Oracle, x, Y) = (y=Y(); push!(samples(o), x => y); y)

sample(o::Operator{<:X,Y}, x::X) where {X,Y} = _sample(o, x, Y)

sample(o::Map{<:X,Y}, x::X) where {X,Y} = x ∈ inputs(relation(o)) ? relation(o)(x) : _sample(o, x, Y)

sample(o::ConstantMap{<:X,Y}, x::X) where {X,Y} = !isempty(samples(o)) ? last(collect(relation(o))[1]) : _sample(o, x, Y)

sample(o::AbstractLinearFunctional{X}, x::X) where {F<:Field, X<:InnerProductSpace{F}} = (y=_sample(o, x, F); label!(y, "⟨" * label(o') * "," * label(x) * "⟩"); y)

# Sample a linear function of linear functionals by taking a linear combination of samples of each functional
function sample(o::LinearDecomposition{T}, x::X) where {F<:Field,X<:VectorSpace{F},T<:AbstractLinearFunctional{X}}
    mapreduce( p -> (y=F(); push!(samples(first(p)), x=>y); last(p)*y), +, weights(o) )
end

# Overload () to denote sampling
(o::OracleOrWrapper)(x) = sample(o,x)

# For linear maps, also use * to denote sampling
*(o::Union{AbstractLinearMap,AbstractLinearFunctional,Wrapper{<:AbstractLinearMap},Wrapper{<:AbstractLinearFunctional}}, x) = sample(o,x)


############################################################################################
# Properties

label(o::Oracle) = o.label
label!(o::Oracle, label::String) = (o.label = label)

properties(o::OracleOrWrapper) = oracle(o).properties

∈(o::OracleOrWrapper, class::Property) = push!(properties(o), class)
∈(o::OracleOrWrapper, properties::Properties) = map(class -> o ∈ class, properties)

"""
    allproperties(o)
    
Get all properties of an oracle (including its suboracles and relation).
"""
allproperties(o::Union{Map,Operator,ConstantMap}) = properties(o) ∪ properties(o.value)
allproperties(o::Oracle) = properties(o) ∪ allproperties(o.value)
allproperties(w::Wrapper{<:Oracle}) = properties(oracle(w)) ∪ allproperties(suboracle(w))


############################################################################################
# Inputs / outputs

inputs(o::OracleOrWrapper) = Set(first(p) for p ∈ oracle(o))
outputs(o::OracleOrWrapper) = Set(last(p) for p ∈ oracle(o))

domain(::AbstractOperator{X,Y}) where {X,Y} = X
codomain(::AbstractOperator{X,Y}) where {X,Y} = Y

inputs_outputs(o::OracleOrWrapper) = (pairs=collect(samples(o)); ([first(p) for p ∈ pairs], [last(p) for p ∈ pairs]))

domain(o::Wrapper{<:Oracle}) = domain(oracle(o))
codomain(o::Wrapper{<:Oracle}) = codomain(oracle(o))


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
