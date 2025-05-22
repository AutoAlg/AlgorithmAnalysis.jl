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


struct SetValuedMap{X<:Space, Y<:Space} <: Map{X, Y}
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

struct SingleValuedMap{X<:Space, Y<:Space} <: Map{X, Y}
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
⇒(X::Type{<:Space}, Y::Type{<:Space}) = SetValuedMap{X,Y}


function getindex(op::Object{SingleValuedMap{X,Y}}, x::Object{X}) where {X, Y}
    filtered = filter( t -> value(t)[1] === x, elements(graph(op)))
    if isempty(filtered)
        missing
    else
        first(filtered)[2]
    end
end

function getindex(op::Object{SetValuedMap{X,Y}}, x::Object{X}) where {X, Y}
    filtered = filter( t -> value(t)[1] === x, elements(graph(op)))
    mapped = map( t -> t[2], collect(filtered))
    Objects{Y}(mapped)
end


"""
    f(x)

Evaluate a function or operator at a point in its domain.

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
function evaluate end

# For f(x1,x2,...), collect the arguments into an element of the Cartesian product space
(f::Object)(x::Vararg{Object}) = f(x())


function (op::Object{SingleValuedMap{X,Y}})(x::Object{X}) where {X<:Space, Y<:Space}
    if x ∈ inputs(op)
        op[x]
    else
        y = sample(Y, Symbol(label(op), "(", label(x), ")"))
        push!(graph(op), TupleDecomposition(x,y))
        y
    end
end

function (op::Object{SetValuedMap{X,Y}})(x::Object{X}) where {X<:Space, Y<:Space}
    y = sample(Y, Symbol(label(op), "(", label(x), ")"))
    push!(graph(op), TupleDecomposition(x,y))
    y
end


inv(f::Object{T}) where {X, Y, T<:SetValuedMap{X,Y}} = get!(T().inv, f) do
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
# OPERATOR
############################################################################################
const Operator{X<:Space} = SingleValuedMap{X, X}
const BinaryOperator{X<:Space} = SingleValuedMap{CartesianProduct{Tuple{X,X}}, X}
# const NaryOperator{X<:Space} = SingleValuedMap{CartesianPower{X}, X}

arity(::Operator) = 1
arity(::BinaryOperator) = 2
