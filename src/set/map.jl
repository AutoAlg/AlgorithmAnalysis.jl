############################################################################################
# GRAPH
############################################################################################

const Graph{X<:Space, Y<:Space} = Subset{CartesianProduct{Tuple{X,Y}}}

inputs(g::Graph{X,Y}) where {X,Y} = Objects{X}(elements(g, 1))
outputs(g::Graph{X,Y}) where {X,Y} = Objects{Y}(elements(g, 2))


############################################################################################
# MAP
############################################################################################

"""
    Map{X,Y}

A map is a relation between pairs of objects. Maps may be sampled at objects in their domain to produce output objects in their codomain. Maps may also have other associated maps; for instance, a linear map has an associated adjoint. Each map can be sampled at a point in its domain, and it can have a set of properties.

Some concrete instances are [`SingleValuedMap`](@ref) and [`SetValuedMap`](@ref).
"""
abstract type Map{X<:Space, Y<:Space} <: Space end
abstract type AbstractSingleValuedMap{X,Y} <: Map{X,Y} end
abstract type AbstractSetValuedMap{X,Y} <: Map{X,Y} end

domain(::Type{<:Map{X,Y}}) where {X,Y} = X
codomain(::Type{<:Map{X,Y}}) where {X,Y} = Y

domain(::Object{<:Map{X,Y}}) where {X,Y} = X
codomain(::Object{<:Map{X,Y}}) where {X,Y} = Y

function graph(f::Object{<:Map{X,Y}}) where {X,Y}
    get!(instance(space(f)).graph, f) do
        Graph{X,Y}()
    end
end

inputs(f::Object{<:Map}) = inputs(graph(f))
outputs(f::Object{<:Map}) = outputs(graph(f))
io(f::Object{<:Map}) = inputs(f) ∪ outputs(f)

# ∘(::Type{T1}, ::Type{T2}) where {X,Y,Z,T1<:Map{X,Y},T2<:Map{Y,Z}} = T{X,Z}


############################################################################################
# SET-VALUED MAP
############################################################################################

struct SetValuedMap{X<:Space, Y<:Space} <: AbstractSetValuedMap{X, Y}
    elements::Objects{SetValuedMap{X,Y}}
    graph::Dict{Object{SetValuedMap{X,Y}}, Graph{X,Y}}
    inv::Dict{Object{SetValuedMap{X,Y}}, Object{SetValuedMap{Y,X}}}

    SetValuedMap{X,Y}() where {X,Y} = get!(_CACHE, SetValuedMap{X,Y}) do
        new{X,Y}(
            Objects{SetValuedMap{X,Y}}(),
            Dict{Object{SetValuedMap{X,Y}}, Graph{X,Y}}(),
            Dict{Object{SetValuedMap{X,Y}}, Object{SetValuedMap{Y,X}}}()
        )
    end
end

⇒(X::Type{<:Space}, Y::Type{<:Space}) = SetValuedMap{X,Y}

function getindex(op::Object{<:AbstractSetValuedMap{X,Y}}, x::Object{X}) where {X, Y}
    filtered = filter( t -> value(t)[1] === x, elements(graph(op)))
    mapped = map( t -> t[2], collect(filtered))
    Objects{Y}(mapped)
end

inv(f::Object{T}) where {X, Y, T<:AbstractSetValuedMap{X,Y}} = get!(T().inv, f) do
    f⁻¹ = Atom{Y ⇒ X}(Symbol(label(f), "⁻¹"))
    for (x,y) ∈ graph(f)
        push!(graph(f⁻¹), TupleDecomposition(y,x))
    end
    get!( (Y ⇒ X)().inv, f⁻¹ ) do
        f
    end
    f⁻¹
end


############################################################################################
# SINGLE-VALUED MAP
############################################################################################

struct SingleValuedMap{X<:Space, Y<:Space} <: AbstractSingleValuedMap{X, Y}
    elements::Objects{SingleValuedMap{X,Y}}
    graph::Dict{Object{SingleValuedMap{X,Y}}, Graph{X,Y}}

    SingleValuedMap{X,Y}() where {X,Y} = get!(_CACHE, SingleValuedMap{X,Y}) do
        new{X,Y}(
            Objects{SingleValuedMap{X,Y}}(),
            Dict{Object{SingleValuedMap{X,Y}}, Graph{X,Y}}()
        )
    end
end

→(X::Type{<:Space}, Y::Type{<:Space}) = SingleValuedMap{X,Y}

function getindex(op::Object{<:AbstractSingleValuedMap{X,Y}}, x::Object{X}) where {X, Y}
    filtered = filter( t -> value(t)[1] === x, elements(graph(op)))
    if isempty(filtered)
        missing
    else
        first(filtered)[2]
    end
end

# ∘(::Type{SingleValuedMap{X,Y}}, ::Type{SingleValuedMap{Y,Z}}) where {X,Y,Z} = SingleValuedMap{X,Z}


############################################################################################
# EVALUATION
############################################################################################

"""
    f(x)

Evaluate a map at a point in its domain.

If the map is single-valued and it has already been sampled at `x`, then the
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
function evaluate end

# For f(x1,x2,...), collect the arguments into an element of the Cartesian product space
(f::Object)(x::Vararg{Object}) = f(TupleDecomposition(x...))


function (op::Object{<:AbstractSingleValuedMap{X,Y}})(x::Object{X}) where {X<:Space, Y<:Space}
    if x ∈ inputs(op)
        op[x]
    else
        L = ismissing(label(x)) ? missing : Symbol(label(op), "(", label(x), ")")
        y = sample(Y, L)
        push!(graph(op), TupleDecomposition(x,y))
        y
    end
end

function (op::Object{<:AbstractSetValuedMap{X,Y}})(x::Object{X}) where {X<:Space, Y<:Space}
    L = ismissing(label(x)) ? missing : Symbol(label(op), "(", label(x), ")")
    y = sample(Y, L)
    push!(graph(op), TupleDecomposition(x,y))
    y
end


############################################################################################
# OPERATOR
############################################################################################
const Operator{X<:Space} = SingleValuedMap{X, X}
const BinaryOperator{X<:Space} = SingleValuedMap{CartesianProduct{Tuple{X,X}}, X}
# const NaryOperator{X<:Space} = SingleValuedMap{CartesianPower{X}, X}

arity(::Operator) = 1
arity(::BinaryOperator) = 2


############################################################################################
# LINEAR
############################################################################################

abstract type AbstractLinearMap{X, Y} <: AbstractSingleValuedMap{X, Y} end

struct LinearMap{X<:Space, Y<:Space} <: AbstractLinearMap{X, Y}
    elements::Objects{LinearMap{X,Y}}
    graph::Dict{Object{LinearMap{X,Y}}, Graph{X,Y}}
    adjoint::Dict{Object{LinearMap{X,Y}}, Object{LinearMap{Y,X}}}

    LinearMap{X,Y}() where {X,Y} = get!(_CACHE, LinearMap{X,Y}) do
        new{X,Y}(
            Objects{LinearMap{X,Y}}(),
            Dict{Object{LinearMap{X,Y}}, Graph{X,Y}}(),
            Dict{Object{LinearMap{X,Y}}, Object{LinearMap{Y,X}}}()
        )
    end
end

############################################################################################
# SYMMETRIC
############################################################################################

abstract type AbstractSymmetricLinearMap{X} <: AbstractLinearMap{X, X} end

struct SymmetricLinearMap{X<:Space} <: AbstractSymmetricLinearMap{X}
    elements::Objects{SymmetricLinearMap{X}}
    graph::Dict{Object{SymmetricLinearMap{X}}, Graph{X,X}}

    SymmetricLinearMap{X}() where X = get!(_CACHE, SymmetricLinearMap{X}) do
        new{X}(
            Objects{SymmetricLinearMap{X}}(),
            Dict{Object{SymmetricLinearMap{X}}, Graph{X,X}}()
        )
    end
end

############################################################################################
# SKEW-SYMMETRIC
############################################################################################

abstract type AbstractSkewSymmetricLinearMap{X} <: AbstractLinearMap{X, X} end

struct SkewSymmetricLinearMap{X<:Space} <: AbstractSkewSymmetricLinearMap{X}
    elements::Objects{SkewSymmetricLinearMap{X}}
    graph::Dict{Object{SkewSymmetricLinearMap{X}}, Graph{X,X}}

    SkewSymmetricLinearMap{X}() where X = get!(_CACHE, SkewSymmetricLinearMap{X}) do
        new{X}(
            Objects{SkewSymmetricLinearMap{X}}(),
            Dict{Object{SkewSymmetricLinearMap{X}}, Graph{X,X}}()
        )
    end
end



# abstract type Functional{T<:VectorSpace} <: AbstractFunction{T, Field} end
# abstract type LinearFunctional{T} <: DifferentiableFunctional{T} end

