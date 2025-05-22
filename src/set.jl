############################################################################################
# STRUCTURES
############################################################################################
# """
#     Structures
# """
# struct Structures
#     structures::Dict{Symbol, Object}

#     Structures() = new(Dict{Symbol, Object}())
# end

# (s::Structures)(x::Symbol) = get(s.structures, x, missing)

# push!(s::Structures, x::Symbol, y::Object) = push!(s.structures, x => y)

# objects(s::Structures) = values(s.structures)

# length(s::Structures) = length(s.structures)
# isempty(s::Structures) = length(s.structures) == 0

# # iterate over structures
# iterate(s::Structures) = iterate(s.structures)
# iterate(s::Structures, state::Int) = iterate(s.structures, state)


############################################################################################

const _CACHE = IdDict{DataType, Space}()

clear_cache(::DataType) = delete!(_CACHE, N)

structures(s::Space) = hasfield(typeof(s), :structures) ? s.structures : Structures()
hasstructures(s::Space) = length(structures(s)) > 0
(s::Space)(x::Symbol) = structures(s)(x)

iterate(T::Type{<:Tuple{Vararg{Space}}}) = iterate(T,1)
function iterate(T::Type{<:Tuple{Vararg{Space}}}, state::Int)
    state > length(T) ? nothing : ( T.parameters[state], state+1 )
end
length(T::Type{<:Tuple{Vararg{Space}}}) = length(T.parameters)


# iterate(T::Type{<:Tuple{Vararg{Property}}}) = iterate(T,1)
# function iterate(T::Type{<:Tuple{Vararg{Property}}}, state::Int)
#     state > length(T) ? nothing : ( T.parameters[state], state+1 )
# end
# length(T::Type{<:Tuple{Vararg{Property}}}) = length(T.parameters)


############################################################################################
"""
    ∅ <: Space

The empty space.
"""
struct ∅ <: Space end

elements(::∅) = Objects()
label(::∅) = :∅

"""
    Universe

The universe, which is the class of all sets.
"""
abstract type Universe end


############################################################################################

elements(s::Space) = s.elements
elements(s::Type{<:Space}) = elements(instance(s))

isempty(s::Space) = isempty(elements(s))
isempty(s::Type{<:Space}) = isempty(elements(s))

length(s::Space) = length(elements(s))
length(s::Type{<:Space}) = length(elements(s))

# iterate over spaces
iterate(T::Space) = iterate(elements(T))
iterate(T::Space, state::Int) = iterate(elements(T), state)

iterate(T::Type{<:Space}) = iterate(elements(T))
iterate(T::Type{<:Space}, state::Int) = iterate(elements(T), state)


############################################################################################

abstract type BasicSet <: Space end

instance(T::Type{<:Space}) = T()

"""
    @set A, B, ...

Define one or more sets of objects. Each symbol is used to define a set type and singleton constructor.
"""
macro set(ex)
    _set(ex)
end

function _set(s::Symbol)
    quote
        struct $(esc(s)) <: BasicSet
            label::Label
            elements::Objects{$(esc(s))}

            function $(esc(s))()
                get!(_CACHE, $(esc(s)) ) do
                    new( $(QuoteNode(s)), Objects{$(esc(s))}() )
                end
            end
        end
    end
end

function _set(expr::Expr)
    if expr.head == :block
        Expr(:block, [ _set(arg) for arg ∈ expr.args ]...)
    elseif expr.head == :tuple
        Expr(:block, [ _set(arg) for arg ∈ expr.args ]...)
    else
        error("Invalid expression for @set macro")
    end
end

elements(S::BasicSet) = S.elements
elements(S::Type{<:BasicSet}) = elements(S())


############################################################################################

"""
    @var a ∈ A, b ∈ B, ...

Define one or more objects in given sets.
"""
macro var(ex)
    _var(ex)
end

function _var(expr::Expr)
    if expr.head == :tuple
        Expr(:block, [ _var(arg) for arg ∈ expr.args ]...)
    elseif expr.head == :call && (expr.args[1] == :(∈) || expr.args[1] == :in)
        a = esc(expr.args[2])
        A = esc(expr.args[3])
        quote
            $a = sample($A, $(QuoteNode(expr.args[2])))
            nothing
        end
    else
        error("@sample expects `a ∈ A`")
    end
end


############################################################################################
# INTERSECTION
############################################################################################

struct SetIntersection{T<:Tuple{Vararg{Space}}} <: Space
    elements::Objects{SetIntersection{T}}

    SetIntersection{T}() where {T<:Tuple{Vararg{Space}}} = get!(_CACHE, SetIntersection{T}) do
        new{T}( Objects{SetIntersection{T}}() )
    end
end

spaces(::Type{SetIntersection{T}}) where T = T

function ∩(T1::Type{<:Space}, T2::Type{<:Space})
    t1 = T1 <: SetIntersection ? spaces(T1) : Tuple{T1}
    t2 = T2 <: SetIntersection ? spaces(T2) : Tuple{T2}
    T = sort(unique(collect(t1 ∪ t2)), by = x -> string(x))
    SetIntersection{Tuple{T...}}
end

elements(::Type{SetIntersection{T}}) where T = mapreduce(elements, ∩, T) 


############################################################################################
# UNION
############################################################################################

struct SetUnion{T<:Tuple{Vararg{Space}}} <: Space
    elements::Objects{SetUnion{T}}

    SetUnion{T}() where {T<:Tuple{Vararg{Space}}} = get!(_CACHE, SetUnion{T}) do
        new{T}( Objects{SetUnion{T}}() )
    end
end

spaces(::Type{SetUnion{T}}) where T = T

function ∪(T1::Type{<:Space}, T2::Type{<:Space})
    t1 = T1 <: SetUnion ? spaces(T1) : Tuple{T1}
    t2 = T2 <: SetUnion ? spaces(T2) : Tuple{T2}
    T = sort(unique(collect(t1 ∪ t2)), by = x -> string(x))
    SetUnion{Tuple{T...}}
end


############################################################################################
"""
    Powerset <: Space

The powerset of a set of objects.
"""
struct Powerset{T<:Space} <: Space end

base(::Powerset{T}) where T = T


############################################################################################
# SUBSET
############################################################################################
abstract type AbstractSubset{T<:Space} <: Space end

parent(::AbstractSubset{T}) where T = T

"""
    Subset{T} <: Space

A subset of a space of objects.
"""
mutable struct Subset{T<:Space} <: AbstractSubset{T}
    label::Label
    elements::Objects{T}
    predicate::Function

    function Subset{T}(label::Label = missing) where {T<:Space}
        new{T}( label, Objects{T}(), () -> false )
    end
end


############################################################################################
# CARTESIAN PRODUCT
############################################################################################

struct CartesianProduct{T<:Tuple{Vararg{Space}}} <: Space
    elements::Objects{CartesianProduct{T}}

    function CartesianProduct{T}() where {T<:Tuple{Vararg{Space}}}
        get!(_CACHE, CartesianProduct{T}) do
            new{T}( Set{TupleDecomposition{T}}() )
        end
    end
end

"""
    TupleDecomposition{T} <: Decomposition{T}

A decomposition of an object as a tuple of objects in space `T`.
"""
struct TupleDecomposition{T<:Tuple{Vararg{Space}}} <: Decomposition{CartesianProduct{T}}
    value::Tuple{Vararg{Object}}

    function TupleDecomposition(val::Vararg{Object})
        # if Tuple{(space(a) for a ∈ val)...} <: cartesian_to_tuple(T)
        #     error("Invalid TupleDecomposition type $T for value with type $(typeof(val))")
        # end
        # new{T}(val)
        T = Tuple{(space(a) for a ∈ val)...}
        new{T}(val)
    end
end

function convert(::Type{Object{CartesianProduct{T}}}, x::Tuple{Vararg{Object}}) where T
    TupleDecomposition(x...)
end

value(x::TupleDecomposition) = x.value
space(::TupleDecomposition{T}) where T = T
constraints(x::TupleDecomposition) = mapreduce(constraints, ∪, value(x))
next(x::TupleDecomposition) = next.(value(x))
elements(x::TupleDecomposition) = value(x)
elements(x::TupleDecomposition, ind::Int) = value(x)[ind]
getindex(x::TupleDecomposition, ind::Int) = value(x)[ind]

length(x::TupleDecomposition) = length(elements(x))
isempty(x::TupleDecomposition) = isempty(elements(x))
iterate(x::TupleDecomposition) = iterate(elements(x))
iterate(x::TupleDecomposition, state::Int) = iterate(elements(x), state)

spaces(::Type{CartesianProduct{T}}) where T = T

function ×(T1::Type{<:Space}, T2::Type{<:Space})
    t1 = T1 <: CartesianProduct ? spaces(T1) : Tuple{T1}
    t2 = T2 <: CartesianProduct ? spaces(T2) : Tuple{T2}
    T = Tuple{fieldtypes(t1)...,fieldtypes(t2)...}
    CartesianProduct{T}
end


" Convert Tuple{A, B} to Tuple{Object{A}, Object{B}} "
function cartesian_to_tuple(::Type{T}) where {T<:Tuple{Vararg{Space}}}
    Tuple{ ( Object{t} for t ∈ fieldtypes(T) )... }
end

" Convert Tuple{Object{A}, Object{B}} to Tuple{A, B} "
function tuple_to_cartesian(::Type{T}) where {T<:Tuple{Vararg{Object}}}
    Tuple{ ( space(t) for t ∈ fieldtypes(T) )... }
end

elements(T::Type{<:CartesianProduct}, ind::Int) = Set{T}( x[ind] for x ∈ elements(T) )
elements(S::Subset{<:CartesianProduct}, ind::Int) = elements.(elements(S), ind)


############################################################################################
# GRAPH
############################################################################################

const Graph{X<:Space, Y<:Space} = Subset{CartesianProduct{Tuple{X,Y}}}

inputs(g::Graph{X,Y}) where {X,Y} = Objects{X}(elements(g, 1))
outputs(g::Graph{X,Y}) where {X,Y} = Objects{Y}(elements(g, 2))


############################################################################################
# FUNCTION SPACE
############################################################################################

abstract type AbstractFunctionSpace{X<:Space, Y<:Space} <: Space end

domain(::Type{<:AbstractFunctionSpace{X,Y}}) where {X,Y} = X
codomain(::Type{<:AbstractFunctionSpace{X,Y}}) where {X,Y} = Y

function graph(f::Object{<:AbstractFunctionSpace{X,Y}}) where {X,Y}
    get!(instance(space(f)).graph, f) do
        Graph{X,Y}()
    end
end

inputs(f::Object{<:AbstractFunctionSpace}) = inputs(graph(f))
outputs(f::Object{<:AbstractFunctionSpace}) = outputs(graph(f))


struct OperatorSpace{X<:Space, Y<:Space} <: AbstractFunctionSpace{X, Y}
    elements::Objects{OperatorSpace{X,Y}}
    graph::Dict{Object{OperatorSpace{X,Y}}, Graph{X,Y}}
    inv::Dict{Object{OperatorSpace{X,Y}}, Object{OperatorSpace{Y,X}}}

    OperatorSpace{X,Y}() where {X,Y} = get!(_CACHE, OperatorSpace{X,Y}) do
        new{X,Y}(
            Objects{OperatorSpace{X,Y}}(),
            Dict{Object{OperatorSpace{X,Y}}, Graph{X,Y}}(),
            Dict{Object{OperatorSpace{X,Y}}, Object{OperatorSpace{Y,X}}}()
        )
    end
end

struct FunctionSpace{X<:Space, Y<:Space} <: AbstractFunctionSpace{X, Y}
    elements::Objects{FunctionSpace{X,Y}}
    graph::Dict{Object{FunctionSpace{X,Y}}, Graph{X,Y}}
    inv::Dict{Object{FunctionSpace{X,Y}}, Object{OperatorSpace{Y,X}}}

    FunctionSpace{X,Y}() where {X,Y} = get!(_CACHE, FunctionSpace{X,Y}) do
        new{X,Y}(
            Objects{FunctionSpace{X,Y}}(),
            Dict{Object{FunctionSpace{X,Y}}, Graph{X,Y}}(),
            Dict{Object{FunctionSpace{X,Y}}, Object{OperatorSpace{Y,X}}}()
        )
    end
end


→(X::Type{<:Space}, Y::Type{<:Space}) = FunctionSpace{X,Y}
⇒(X::Type{<:Space}, Y::Type{<:Space}) = OperatorSpace{X,Y}


# function getindex(op::Object{OperatorSpace{X,Y}}, x::Object{X}) where {X, Y}
#     filtered = filter( t -> value(t)[1] === x, elements(graph(op)))
#     if has_structure(op, Functional())
#         if isempty(filtered)
#             missing
#         else
#             first(filtered)[2]
#         end
#     else
#         mapped = map( t -> t[2], collect(filtered))
#         Objects{Y}(mapped)
#     end
# end

# function (op::Object{OperatorSpace{X,Y}})(x::Object{X}) where {X<:Space, Y<:Space}
#     if has_structure(op, Functional()) && x ∈ inputs(op)
#         op[x]
#     else
#         y = sample(Y, Symbol(label(op), "(", label(x), ")"))
#         push!(graph(op), TupleDecomposition(x,y))
#         y
#     end
# end

inv(f::Object{T}) where {X, Y, T<:AbstractFunctionSpace{X,Y}} = get!(T().inv, f) do
    f⁻¹ = Atom{Y ⇒ X}(Symbol(label(f), "⁻¹"))
    for (x,y) ∈ graph(f)
        push!(graph(f⁻¹), TupleDecomposition(y,x))
    end
    if T <: OperatorSpace
        get!( (Y ⇒ X)().inv, f⁻¹ ) do
            f
        end
    end
    f⁻¹
end








############################################################################################
# SAMPLE
############################################################################################
sample(T::Type{<:Space}, label::Symbol) = Atom{T}(label)
sample(S::Subset, label::Symbol) = (a = sample(parent(S), label); push!(S, a); a)

function sample(::Type{CartesianProduct{T}}, label::Symbol) where T
    x = Tuple( sample(t, Symbol(label, subscript(i))) for (i,t) ∈ enumerate(fieldtypes(T)) )
    y = TupleDecomposition(x...)
    push!(CartesianProduct{T}, y)
    y
end


############################################################################################
# PUSH
############################################################################################
push!(T::Type{<:Space}, x::Object) = push!(elements(T), x)
push!(S::Subset, x) = push!(elements(S), x)
push!(T::Type{<:CartesianProduct}, x::Tuple{Vararg{Object}}) = push!(elements(T), x)

# TODO: does not work!
push!(::Type{SetIntersection{T}}, x::Object) where T = map(t -> push!(t, x), fieldtypes(T))


############################################################################################
# NATURAL NUMBERS
############################################################################################

struct N <: Space
    zero::Object{N}
    elements::Objects{N}
    successor::Object{OperatorSpace{N, N}}

    N() = get!(_CACHE, N) do
        zero = Atom{N}(Symbol(0), false)
        elements = Objects{N}()
        push!(elements, zero)
        successor = Atom{OperatorSpace{N, N}}(:S)
        new( zero, elements, successor )
    end
end

label(::N) = "Natural numbers"
zero(::Type{N}) = N().zero
successor(::Type{N}) = N().successor

function +(a::Object{N}, b::Int)
    if b == 1
        N().successor(a)
    elseif b > 1
        N().successor(a) + (b-1)
    else
        error("Natural numbers are nonnegative")
    end
end

function +(a::Object{N}, b::Object{N})
    if b === zero(N)
        a
    elseif a === zero(N)
        b
    elseif b ∈ outputs(successor(N))

    else
        error("Unknown")
    end
end


############################################################################################
# Iteration over an abstract Cartesian product space

# length(T::AbstractCartesianProduct) = length(spaces(T))
# isempty(T::AbstractCartesianProduct) = iszero(length(T))
# iterate(T::AbstractCartesianProduct) = iterate(T,1)
# function iterate(T::AbstractCartesianProduct, state::Int)
#     state > length(T) ? nothing : ( spaces(T)[state], state+1 )
# end

# isempty(::Object{<:CartesianProduct{T}}) where T = iszero(length(T))
# length(::Object{<:CartesianProduct{T}}) where T = length(T)
# iterate(x::Object{<:CartesianProduct{T}}) where T = iterate(x,1)
# function iterate(x::Object{<:CartesianProduct{T}}, state::Int) where T
#     state > length(x) ? nothing : ( value(x)[state], state+1 )
# end


############################################################################################
# BINARY OPERATOR
############################################################################################

# mutable struct BinaryOperator <: Space
#     label::String
#     space::Space
#     samples::SingleValuedRelation{Object, SingleValuedRelation{Object, Object}}

#     function BinaryOperator(s::Space)
#         d = SingleValuedRelation{Object, SingleValuedRelation{Object,Object}}()
#         new( "", s, d )
#     end
# end

# space(s::BinaryOperator) = s.space
# domain(s::BinaryOperator) = space(s) × space(s)
# codomain(s::BinaryOperator) = space(s)
# relation(s::BinaryOperator) = s.samples


# # const Scaling{V<:VectorSpace, F<:Field} = AbstractFunction{CartesianProduct{Tuple{F,V}}, V}

# # field(::Type{Scaling{V,F}}) where {V,F} = F
# # vectorspace(::Type{Scaling{V,F}}) where {V,F} = V

# # const UnaryOperator{X<:Space} = AbstractFunction{X, X}
# # const BinaryOperator{X<:Space} = AbstractFunction{CartesianPower{X, 2}, X}
# # const NaryOperator{X<:Space} = AbstractFunction{CartesianPower{X}, X}

# # abstract type BinaryOperator{X<:Space} <: Space end
# # abstract type NaryOperator{X<:Space} <: Space end

# # arity(::UnaryOperator) = 1
# # arity(::BinaryOperator) = 2



############################################################################################
# REAL NUMBERS
############################################################################################

# """
#     Field <: Space

# A field.

# An element of a field is a scalar. A scalar is an object that can be an affine function of other scalars and inner products of points in an inner product space over the field.

# Use [`@field]`](@ref) to construct a field.
# """
# mutable struct Field <: Space
#     label::String
#     objects::Objects
#     structures::Structures

#     function Field(l::String)
#         K = new(l, Objects(), Structures())
#         op = K × K → K
#         push!(K.structures, :+, Atom(op, "+"))
#         push!(K.structures, :*, Atom(op, "*"))
#         K
#     end
# end

# """
#     R <: Field

# The field of real numbers.
# """
# const R = Field("R")


# # """
# #     𝓛{V}

# # Space of linear functionals on a vector space `V`.
# # """
# # struct 𝓛{V} <: LinearFunctional{V}
# #     # gradient::Object{AbstractFunction{𝓛{V},UnaryOperator{V}}}
# #     # relation::Object{AbstractFunction{𝓛{V},SingleValuedRelation}}
# #     gradient::Object
# #     relation::Object
# #     # relation::SingleValuedRelation{𝓛{V},SingleValuedRelation}

# #     function Base.reinterpret(::Type{𝓛{V}}) where V
# #         gradient = AbstractFunction{𝓛{V},UnaryOperator{V}}()
# #         gradient.labeler = x -> "∇$(label(x))"
# #         relation = AbstractFunction{𝓛{V},SingleValuedRelation}()
# #         new{V}(gradient, relation)
# #     end
# # end

# # const _𝓛 = Dict{VectorSpace,𝓛}()
# # instance(::Type{𝓛{V}}) where {V<:VectorSpace} = get(_𝓛, V, reinterpret(𝓛{V}))


# # """
# #     𝓕{V}

# # Space of differentiable functionals on a vector space `V`.
# # """
# # struct 𝓕{V} <: Functional{V}
# #     gradient::Object{AbstractFunction{𝓕{V},UnaryOperator{V}}}

# #     function Base.reinterpret(::Type{𝓕{V}}) where V
# #         grad = AbstractFunction{𝓕{V},UnaryOperator{V}}()
# #         grad.labeler = x -> "∇$(label(x))"
# #         new{V}(grad)
# #     end
# # end

# # const _𝓕 = Dict{VectorSpace,𝓕}()
# # instance(::Type{𝓕{V}}) where {V<:VectorSpace} = get(_𝓕, V, reinterpret(𝓕{V}))



# # """
# #     Rⁿ <: InnerProductSpace

# # A real inner product space.
# # """
# # struct Rⁿ <: InnerProductSpace{R}
# #     addition::Object{Addition{Rⁿ}}
# #     scaling::Object{Scaling{Rⁿ,R}}
# #     dual::Object{AbstractFunction{Rⁿ,Rⁿ'}}

# #     function Base.reinterpret(::Type{Rⁿ})
# #         f = Addition{Rⁿ}()
# #         g = Scaling{Rⁿ,R}()
# #         h = AbstractFunction{Rⁿ,Rⁿ'}()
# #         f ∈ Associative
# #         f ∈ Commutative
# #         h.labeler = x -> "$(label(x))'"
# #         new(f, g, h)
# #     end
# # end

# # const _Rⁿ = reinterpret(Rⁿ)
# # instance(::Type{Rⁿ}) = _Rⁿ
# # structures(::Type{Rⁿ}) = Atoms([
# #     instance(Rⁿ).addition, instance(Rⁿ).scaling, instance(Rⁿ).dual])

# # """
# #     Rᵐ <: InnerProductSpace

# # A real inner product space.
# # """
# # struct Rᵐ <: InnerProductSpace{R}
# #     addition::Object{Addition{Rᵐ}}
# #     scaling::Object{Scaling{Rᵐ,R}}

# #     function Base.reinterpret(::Type{Rᵐ})
# #         f = Addition{Rᵐ}()
# #         g = Scaling{Rᵐ,R}()
# #         f ∈ Associative
# #         f ∈ Commutative
# #         new(f, g)
# #     end
# # end

# # const _Rᵐ = reinterpret(Rᵐ)
# # instance(::Type{Rᵐ}) = _Rᵐ
# # structures(::Type{Rᵐ}) = Atoms([
# #     instance(Rᵐ).addition, instance(Rᵐ).scaling, instance(Rᵐ).dual])



# getfields(x) = Set( getfield(x,i) for i ∈ 1:fieldcount(typeof(x)) )

# # operators(::Type{<:Space}) = Operators()
# # operators(::Type{R}) = getfields(instance(R))


# isimplementable(::Any) = false
# isimplementable(::Type{Field}) = true
# isimplementable(::Type{<:Real}) = true
# # isimplementable(::Type{CartesianProduct{T}}) where T =
# #     isimplementable(T1) && isimplementable(T2)

# juliatype(::Any) = Union{}
# # juliatype(::Type{R}) = Real
# # juliatype(::Type{R × R}) = Tuple{Real, Real}

# algorithmtype(::Any) = Union{}
# # algorithmtype(::Type{Real}) = R
# # algorithmtype(::Type{Tuple{Real, Real}}) = R × R

# convert(::Type{<:Object}, x::Number) = Atom(R)

# # convert(::Type{<:Object{R}}, x::Real) = Atom{R}(x)
# # # convert(::Type{<:Expression{R}}, ::Zero) = R(0)
# # # convert(::Type{<:Expression{R}}, ::One) = R(1)

# promote_rule(::Type{<:Object}, ::Type{<:Number}) = Object

# # +(x::Real, y::Expression{R}) = +(promote(x,y)...)
# # +(x::Expression{R}, y::Real) = y + x
# # -(x::Real, y::Expression{R}) = x + (-y)
# # -(x::Expression{R}, y::Real) = x + (-y)
# # *(x::Real, y::Expression{R}) = *(promote(x,y)...)
# # *(x::Expression{R}, y::Real) = R(y)*x
# # /(x::Real, y::Expression{R}) = /(promote(x,y)...)
# # /(x::Expression{R}, y::Real) = /(promote(x,y)...)

# # *(a::Real, x::Decomposition{R}) = R(a) * x
# # *(x::Real, y::Expression{<:VectorSpace{R}}) = R(x) * y
# # *(x::Real, y::Expression{<:LinearFunctional{<:VectorSpace{R}}}) = R(x) * y

# # # function *(X::Matrix{<:JuMP.AbstractJuMPScalar}, Y::Matrix{R})
# # #     if size(X)[2] != size(Y)[1]
# # #         error("Matrix dimensions do not agree for matrix multiplication, dimensions are $(size(X)) and $(size(Y))")
# # #     end
# # #     Z = Matrix{R}(undef, size(X)[1], size(Y)[2])
# # #     for i = 1:size(X)[1], j = 1:size(Y)[2]
# # #         Z[i,j] = R(0)
# # #         for k = 1:size(X)[2]
# # #             Z[i,j] += X[i,k]*Y[k,j]
# # #         end
# # #     end
# # #     Z
# # # end

# # zero(::Type{R}) = R(0)
# # one(::Type{R}) = R(1)

# # # zero(::Type{JuMP.GenericAffExpr}) = JuMP.AffExpr(0)

# # iszero(e::R) = e.value isa Zero || (e.value isa Number && iszero(e.value))
# # isone(e::R) = e.value isa One || (e.value isa Number && isone(e.value))

# # # value(::Zero{R}) = 0
# # # value(::One{R}) = 1


# """
#     Field <: Space

# An abstract field.

# An element of a field is a scalar. A scalar is an object that can be an affine function of other scalars and inner products of points in an inner product space over the field.

# Use [`@field]`](@ref) to construct a field.
# """
# abstract type Field <: Ring end

# """
#     VectorSpace{F<:Field} <: Space

# An abstract vector space.

# A vector is an object that can be a linear function of other vectors.
# """
# abstract type VectorSpace{F<:Field} <: Space end

# """
#     NormedVectorSpace{F<:Field} <: VectorSpace{F}

# An abstract normed vector space.
# """
# abstract type NormedVectorSpace{F<:Field} <: VectorSpace{F} end

# """
#     InnerProductSpace{F<:Field} <: NormedVectorSpace{F}

# An abstract inner product space. The inner product of two vectors produces a scalar, and the squared norm is the inner product of a vector with itself.
# """
# abstract type InnerProductSpace{F<:Field} <: NormedVectorSpace{F} end


############################################################################################
# OPERATORS
############################################################################################

# abstract type AbstractFunction{X,Y} <: Operator{X,Y} end
# abstract type LinearMap{X,Y} <: AbstractFunction{X,Y} end
# abstract type SymmetricLinearMap{X} <: LinearMap{X,X} end
# abstract type SkewSymmetricLinearMap{X} <: LinearMap{X,X} end
# abstract type DifferentiableFunction{X,Y} <: AbstractFunction{X,Y} end

# abstract type Functional{T<:VectorSpace} <: AbstractFunction{T, Field} end
# abstract type LocallyLipschitzFunctional{T} <: Functional{T} end
# abstract type SubdifferentiableFunctional{T} <: LocallyLipschitzFunctional{T} end
# abstract type DifferentiableFunctional{T} <: LocallyLipschitzFunctional{T} end
# abstract type TwiceDifferentiableFunctional{T} <: DifferentiableFunctional{T} end
# abstract type LinearFunctional{T} <: DifferentiableFunctional{T} end