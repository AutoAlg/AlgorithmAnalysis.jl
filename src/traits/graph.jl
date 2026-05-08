export MapTrait, Map, SingleValued, SetValued, →, ⇒
export graph, inputs, outputs, io, domain, codomain
export Graph, graphof, as_graph, as_pair, input, output

struct Graph <: Trait
    op::Object
    dict::Dict{Tuple{Object, Object}, Object}

    Graph(x::Object) = new(x, Dict{Tuple{Object, Object}, Object}())
end

graphof(s::Space) = graphof(get(s, Graph), s)
graphof(t::Graph, ::Space) = t.op
graphof(::Nothing, s::Space) = error("Space $s is not a graph.")

inputs(t::Graph) = Set(k[1] for k ∈ keys(t.dict))
outputs(t::Graph) = Set(k[2] for k ∈ keys(t.dict))

inputs(s::Space) = inputs(get(s, Graph))
outputs(s::Space) = outputs(get(s, Graph))

show(io::IO, t::Graph) = print(io, "Graph of $(t.op)")

abstract type MapTrait <: Trait end
abstract type Map <: MapTrait end

struct SingleValued <: Map
    domain::Space
    codomain::Space
    graph::Dict{Object, Space}

    SingleValued(X::Space, Y::Space) = new(X,Y,Dict{Object,Space}())
end

SingleValued(s::Space) = SingleValued(domain(s), codomain(s))

struct SetValued <: Map
    domain::Space
    codomain::Space
    graph::Dict{Object, Space}

    SetValued(X::Space, Y::Space) = new(X,Y,Dict{Object,Space}())
end

function →(X::Space, Y::Space)
    Space(Symbol(label(X), " → ", label(Y)), trait = SingleValued(X,Y))
end

function ⇒(X::Space, Y::Space)
    Space(Symbol(label(X), " ⇒ ", label(Y)), trait = SetValued(X,Y))
end

domain(s::Space) = domain(get(s, MapTrait), get(s, Subset), s)
domain(x::Object) = domain(space(x))
domain(t::Map, ::Nothing, ::Space) = domain(t)
domain(::Nothing, t::Subset, ::Space) = domain(t)
domain(t::Map) = t.domain

codomain(s::Space) = codomain(get(s, MapTrait), s)
codomain(x::Object) = codomain(space(x))
codomain(t::Map, ::Space) = codomain(t)
codomain(t::Map) = t.codomain

graph(x::Object) = graph(get(space(x), MapTrait), x)
graph(t::Map, x::Object) = get!(t.graph, x) do
    parent = domain(t) × codomain(t)
    label = Symbol("graph($x)")
    s = Space(label, traits = Traits([Subset(parent), Graph(x)]))
    parent.subsets[label] = s
    s
end

function as_graph(x::Object, y::Object)
    val = value(y)
    if !isa(val, Evaluation)
        error("$y is not an evaluation.")
    end
    if !(val.x === x)
        error("$y is not the output of an evaluation with input $x")
    end
    f = val.f
    g = graph(f)
    t = get(g, Graph)
    get!(t.dict, (x,y)) do
        p = Object(g)
        t.dict[(x,y)] = p
        p
    end
end

function as_pair(x::Object)
    t = get(x, Graph)
    if isnothing(t)
        error("Object $x is not a graph pair.")
    end
    xs = [k for (k, v) in t.dict if v === x]
    if length(xs) > 1
        error("Space $t contains multiple pairs for object $x: $xs")
    end
    if isempty(xs)
        error("Space $t contains no pairs for object $x")
    end
    first(xs)
end

inputs(f::Object) = [ value(p)[1] for p ∈ elements(graph(f)) ]
outputs(f::Object) = [ value(p)[2] for p ∈ elements(graph(f)) ]
io(f::Object) = inputs(f) ∪ outputs(f)

input(x::Object) = as_pair(x)[1]
output(x::Object) = as_pair(x)[2]

# (f::Object)(x::Object) = f(get(space(f), Map), x)
(f::Object)(xs::Object...) = f(as_product(xs...))

function (f::Object)(x::Object)
    g = graph(f)
    t = get(g, Graph)
    ys = [ k[2] for (k, _) in t.dict if k[1] === x ]
    if length(ys) > 1
        error("Graph $t contains multiple pairs for object $x: $ys")
    elseif length(ys) == 1
        return first(ys)
    elseif isempty(ys)
        y = sample(codomain(f))
        p = Object(g)
        value!(y, Evaluation(f, x))
        value!(p, (x,y))
        t.dict[(x,y)] = p
        return y
    end
end

# function (f::Object)(t::Map, x::Object)
#     # ps = filter( p -> p[1] === x, Set(elements(graph(f))) )
#     # if isone(length(ps))
#     #     return first(ps)[2]
#     # end
#     # y = sample(codomain(f))
#     # # graph(f).elements[allocate_id(graph(f))] = as_product(x,y)
#     # # graph(f)(as_product(x,y))
#     # # t.dict[(x,y)] = Object(graph(f))
#     # value!(y, Evaluation(f, x))
#     # return y
# end

getindex(f::Object, x::Object) = getindex(get(f, Map), f, x)

function getindex(::Map, f::Object, x::Object)
    @assert domain(space(f)) == space(x) "$x is not in the domain of $f"
    graph(f)[1]
end

show(io::IO, t::SingleValued) = print(io, "Function $(t.domain) → $(t.codomain)")
show(io::IO, t::SetValued) = print(io, "Relation $(t.domain) ⇒ $(t.codomain)")



# function getindex(op::Object{<:AbstractSetValuedMap{X,Y}}, x::Object{X}) where {X, Y}
#     filtered = filter( t -> t[1] === x, elements(graph(op)) )
#     mapped = map( t -> t[2], collect(filtered) )
#     Objects{Y}(mapped)
# end

# inv(f::Object{T}) where {X, Y, T<:AbstractSetValuedMap{X,Y}} = get!(T().inv, f) do
#     f⁻¹ = Atom{Y ⇒ X}(Symbol(label(f), "⁻¹"))
#     for (x,y) ∈ graph(f)
#         push!(graph(f⁻¹), TupleDecomposition(y,x))
#     end
#     get!( instance(Y ⇒ X).inv, f⁻¹ ) do
#         f
#     end
#     f⁻¹
# end


# ############################################################################################
# # SINGLE-VALUED MAP
# ############################################################################################

# function getindex(op::Object{<:AbstractSingleValuedMap{X,Y}}, x::Object{X}) where {X, Y}
#     filtered = filter( t -> t[1] === x, elements(graph(op)) )
#     isempty(filtered) ? missing : first(filtered)[2]
# end

# export inverse

# function inverse(op::Object{<:AbstractSingleValuedMap{X,Y}}, y::Object{Y}) where {X, Y}
#     filtered = filter( t -> t[2] === y, elements(graph(op)) )
#     isempty(filtered) ? missing : first(filtered)[1]
# end

# # ∘(::Type{SingleValuedMap{X,Y}}, ::Type{SingleValuedMap{Y,Z}}) where {X,Y,Z} = SingleValuedMap{X,Z}


# ############################################################################################
# # EVALUATION
# ############################################################################################

# """
#     f(x)

# Evaluate a map at a point in its domain.

# If the map is single-valued and it has already been sampled at `x`, then the
# corresponding point in the codomain is returned. Otherwise, a new point is sampled using
# `Y()`, and a default label is used for the sample. A label may be specified for the sampled 
# point, or it defaults to an intuitive label.

# **Important:** Do not call `sample` directly. Instead, use `o(x)` to sample an oracle at a
# point. For linear maps, `o*x` may also be used to denote sampling.

# # Examples
# ```julia-repl
# julia> A = LinearFunctional{Rⁿ}()
# julia> x = Rⁿ()
# julia> isequal(A(x), A*x)  # true
# ```
# """
# function evaluate end

# # For f(x1,x2,...), collect the arguments into an element of the Cartesian product space
# (f::Object)(x::Vararg{Object}) = f(as_space(x))


# function (op::Object{<:AbstractSingleValuedMap{X,Y}})(x::Object{X}) where {X<:Space, Y<:Space}
#     if x ∈ inputs(op)
#         if !ismissing(op[x])
#             op[x]
#         else
#             error("$x ∈ inputs($op), but $op[$x] is missing")
#         end
#     else
#         if !ismissing(op.labeler)
#             L = op.labeler(x)
#         elseif !ismissing(label(x)) && !ismissing(label(op))
#             L = Symbol(label(op), "(", label(x), ")")
#         else
#             L = missing
#         end
#         y = sample(Y, L)
#         push!(graph(op), as_space(x,y))
#         y
#     end
# end

# function (op::Object{<:AbstractSetValuedMap{X,Y}})(x::Object{X}) where {X<:Space, Y<:Space}
#     if !ismissing(op.labeler)
#         L = op.labeler(x)
#     elseif !ismissing(label(x)) && !ismissing(label(op))
#         L = Symbol(label(op), "(", label(x), ")")
#     else
#         L = missing
#     end
#     y = sample(Y, L)
#     push!(graph(op), as_space(x,y))
#     y
# end


# ############################################################################################
# # OPERATOR
# ############################################################################################
# const Operator{X<:Space} = SingleValuedMap{X, X}
# const BinaryOperator{X<:Space} = SingleValuedMap{CartesianProduct{Tuple{X,X}}, X}
# # const NaryOperator{X<:Space} = SingleValuedMap{CartesianPower{X}, X}

# arity(::Operator) = 1
# arity(::BinaryOperator) = 2


# ############################################################################################
# # LINEAR
# ############################################################################################

# abstract type AbstractLinearMap{X, Y} <: AbstractSingleValuedMap{X, Y} end

# struct LinearMap{X<:Space, Y<:Space} <: AbstractLinearMap{X, Y}
#     elements::Objects{LinearMap{X,Y}}
#     graph::Dict{Object{LinearMap{X,Y}}, Graph{X,Y}}
#     adjoint::Dict{Object{LinearMap{X,Y}}, Object{LinearMap{Y,X}}}

#     LinearMap{X,Y}() where {X,Y} = get!(_CACHE, LinearMap{X,Y}) do
#         new{X,Y}(
#             Objects{LinearMap{X,Y}}(),
#             Dict{Object{LinearMap{X,Y}}, Graph{X,Y}}(),
#             Dict{Object{LinearMap{X,Y}}, Object{LinearMap{Y,X}}}()
#         )
#     end
# end

# # For linear maps, also use * to denote sampling
# *(f::Object{<:AbstractLinearMap}, x::Object) = f(x)


# ############################################################################################
# # SYMMETRIC
# ############################################################################################

# abstract type AbstractSymmetricLinearMap{X} <: AbstractLinearMap{X, X} end

# struct SymmetricLinearMap{X<:Space} <: AbstractSymmetricLinearMap{X}
#     elements::Objects{SymmetricLinearMap{X}}
#     graph::Dict{Object{SymmetricLinearMap{X}}, Graph{X,X}}

#     SymmetricLinearMap{X}() where X = get!(_CACHE, SymmetricLinearMap{X}) do
#         new{X}(
#             Objects{SymmetricLinearMap{X}}(),
#             Dict{Object{SymmetricLinearMap{X}}, Graph{X,X}}()
#         )
#     end
# end

# ############################################################################################
# # SKEW-SYMMETRIC
# ############################################################################################

# abstract type AbstractSkewSymmetricLinearMap{X} <: AbstractLinearMap{X, X} end

# struct SkewSymmetricLinearMap{X<:Space} <: AbstractSkewSymmetricLinearMap{X}
#     elements::Objects{SkewSymmetricLinearMap{X}}
#     graph::Dict{Object{SkewSymmetricLinearMap{X}}, Graph{X,X}}

#     SkewSymmetricLinearMap{X}() where X = get!(_CACHE, SkewSymmetricLinearMap{X}) do
#         new{X}(
#             Objects{SkewSymmetricLinearMap{X}}(),
#             Dict{Object{SkewSymmetricLinearMap{X}}, Graph{X,X}}()
#         )
#     end
# end



# abstract type Functional{T<:VectorSpace} <: AbstractFunction{T, Field} end
# abstract type LinearFunctional{T} <: DifferentiableFunctional{T} end



# # ∘(::Type{T1}, ::Type{T2}) where {X,Y,Z,T1<:Map{X,Y},T2<:Map{Y,Z}} = T{X,Z}