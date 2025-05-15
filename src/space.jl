
############################################################################################
"""
    Structures
"""
struct Structures
    structures::Dict{Symbol, Object}

    Structures() = new(Dict{Symbol, Object}())
end

(s::Structures)(x::Symbol) = get(s.structures, x, missing)

push!(s::Structures, x::Symbol, y::Object) = push!(s.structures, x => y)

objects(s::Structures) = values(s.structures)

length(s::Structures) = length(s.structures)
isempty(s::Structures) = length(s.structures) == 0

# iterate over structures
iterate(s::Structures) = iterate(s.structures)
iterate(s::Structures, state::Int) = iterate(s.structures, state)

structures(s::Space) = hasfield(typeof(s), :structures) ? s.structures : Structures()
hasstructures(s::Space) = length(structures(s)) > 0
(s::Space)(x::Symbol) = structures(s)(x)


############################################################################################
"""
    Nil <: Space

The empty space.
"""
struct Nil <: Space end

objects(::Nil) = Objects()
label(::Nil) = "Nil"

# iterate over spaces
length(T::Space) = 1
isempty(T::Space) = false
iterate(T::Space) = iterate(T,1)
iterate(T::Space, state::Int) = state > 1 ? nothing : ( T, 2 )

push!(s::Space, x::Object) = push!(objects(s), x)

objects(s::Space) = s.objects
objects(s::Type{<:Space}) = objects(s())


############################################################################################

abstract type SetSpace <: Space end

sample(::Type{T}) where {T<:SetSpace} = Atom(T())

"""
    @set S

Define a set of objects.
"""
macro set(s::Symbol)
    str = String(s)
    quote
        struct $(esc(s)) <: SetSpace
            label::String
            objects::Objects
        end
        const $(Symbol("_", esc(s))) = $(esc(s))($str, Objects())
        $(esc(s))() = $(Symbol("_", esc(s)))
    end
end


############################################################################################
# """
#     SetSpace <: Space

# A set of objects with no particular structure.
# """
# mutable struct SetSpace <: Space
#     label::String
#     objects::Objects

#     SetSpace(label::String = "") = new(label, Objects())
# end


############################################################################################
"""
    Subset <: Space

A subset of a space of objects.
"""
mutable struct Subset{T<:SetSpace} <: Space
    label::String
    objects::Objects  # Subset{parent}

    Subset{T}(label::String = "") where T = new{T}(label, Objects())
end

parent(::Subset{T}) where T = T


############################################################################################
"""
    Powerset <: Space

The powerset of a set of objects.
"""
mutable struct Powerset <: Space
    label::String
    objects::Objects
    base::Space

    Powerset(base::Space, label::String = "") = new(label, Objects(), base)
end

base(s::Powerset) = s.base



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

abstract type AbstractFunction{X,Y} <: Operator{X,Y} end
abstract type LinearMap{X,Y} <: AbstractFunction{X,Y} end
abstract type SymmetricLinearMap{X} <: LinearMap{X,X} end
abstract type SkewSymmetricLinearMap{X} <: LinearMap{X,X} end
abstract type DifferentiableFunction{X,Y} <: AbstractFunction{X,Y} end

# abstract type Functional{T<:VectorSpace} <: AbstractFunction{T, Field} end
# abstract type LocallyLipschitzFunctional{T} <: Functional{T} end
# abstract type SubdifferentiableFunctional{T} <: LocallyLipschitzFunctional{T} end
# abstract type DifferentiableFunctional{T} <: LocallyLipschitzFunctional{T} end
# abstract type TwiceDifferentiableFunctional{T} <: DifferentiableFunctional{T} end
# abstract type LinearFunctional{T} <: DifferentiableFunctional{T} end


############################################################################################
# CARTESIAN PRODUCT
############################################################################################

struct CartesianProduct <: Space
    objects::Objects
    T::Tuple{Vararg{Space}}

    CartesianProduct(s::Tuple{Vararg{Space}}) = get!(_cache_cartesian_product, s) do
        new( Objects(), s )
    end
end

const _cache_cartesian_product = Dict{Tuple{Vararg{Space}}, CartesianProduct}()

label(T::CartesianProduct) = ""
label!(::CartesianProduct, ::String) = nothing

# struct CartesianPower <: AbstractCartesianProduct
#     objects::Objects
#     T::Space
#     N::Int

#     CartesianPower(s::Space, N::Int) = get!(_cache_cartesian_power, (s, N)) do
#         new( Objects(), s, N )
#     end
# end

# const _cache_cartesian_power = Dict{Tuple{Space,Int}, CartesianPower}()

# space(x::CartesianPower) = x.T
# power(x::CartesianPower) = x.N

spaces(x::CartesianProduct) = x.T
# spaces(x::CartesianPower) = NTuple{power(x), space(x)}

×(T1::Space, T2::Space) = CartesianProduct( (T1, T2) )
×(T1::CartesianProduct, T2::Space) = CartesianProduct( (T1..., T2) )
×(T1::Space, T2::CartesianProduct) = CartesianProduct( (T1, T2...) )
×(T1::CartesianProduct, T2::CartesianProduct) = CartesianProduct( (T1..., T2...) )

# function ×(T1::Space, T2::Space)
#     if isequal(T1,T2)
#         CartesianPower( T1, 2 )
#     else
#         CartesianProduct( (T1, T2) )
#     end
# end
# function ×(T1::CartesianPower, T2::Space)
#     if isequal(space(T1), T2)
#         CartesianPower(T2, power(T1)+1)
#     else
#         CartesianProduct( (T1, T2) )
#     end
# end
# function ×(T1::Space, T2::CartesianPower)
#     if isequal(T1, space(T2))
#         CartesianPower(T1, power(T2)+1)
#     else
#         CartesianProduct( (T1, T2) )
#     end
# end
# function ×(T1::CartesianPower, T2::CartesianPower)
#     if isequal(space(T1), space(T2))
#         CartesianPower(T1, power(T1)+power(T2))
#     else
#         CartesianProduct( (T1, T2) )
#     end
# end

# ×(::Type{T1}, ::Type{T2}) where {T3, T1<:CartesianProduct{T3}, T2<:Space} = CartesianProduct{Tuple{fieldtypes(T3)...,T2}}
# ×(::Type{T1}, ::Type{T2}) where {T3, T1<:Space, T2<:CartesianProduct{T3}} = CartesianProduct{Tuple{T1,fieldtypes(T3)...}}
# ×(::Type{T1}, ::Type{T2}) where {T3, T4, T1<:CartesianProduct{T3}, T2<:CartesianProduct{T4}} = CartesianProduct{Tuple{fieldtypes(T3)...,fieldtypes(T4)...}}



# struct CartesianProduct{T<:Tuple{Vararg{Space}}} <: Space end

# const CartesianPower{T, N} = CartesianProduct{NTuple{N,T}}

# spaces(::Type{CartesianProduct{T}}) where T = T

# ×(::Type{T}, ::Type{T}) where {T<:Space} = CartesianPower{T, 2}
# ×(::Type{CartesianPower{N, T}}, ::Type{T}) where {N<:Int, T<:Space} = CartesianPower{T, N+1}
# ×(::Type{T}, ::Type{CartesianPower{N, T}}) where {N<:Int, T<:Space} = CartesianPower{T, N+1}
# ×(::Type{CartesianPower{N1, T}}, ::Type{CartesianPower{N2, T}}) where {N1<:Int, N2<:Int, T<:Space} = CartesianPower{T, N1+N2}

# ×(::Type{T1}, ::Type{T2}) where {T1<:Space, T2<:Space} = CartesianProduct{Tuple{T1,T2}}
# ×(::Type{T1}, ::Type{T2}) where {T3, T1<:CartesianProduct{T3}, T2<:Space} = CartesianProduct{Tuple{fieldtypes(T3)...,T2}}
# ×(::Type{T1}, ::Type{T2}) where {T3, T1<:Space, T2<:CartesianProduct{T3}} = CartesianProduct{Tuple{T1,fieldtypes(T3)...}}
# ×(::Type{T1}, ::Type{T2}) where {T3, T4, T1<:CartesianProduct{T3}, T2<:CartesianProduct{T4}} = CartesianProduct{Tuple{fieldtypes(T3)...,fieldtypes(T4)...}}


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

# isempty(x::Object{<:CartesianPower}) = iszero(length(value(x)))
# length(x::Object{<:CartesianPower}) = length(value(x))
# iterate(x::Object{<:CartesianPower}) = iterate(x,1)
# function iterate(x::Object{<:CartesianPower}, state::Int)
#     state > length(x) ? nothing : ( value(x)[state], state+1 )
# end



# convert(::Type{Object}, x::Tuple{Vararg{T}}) where {T<:Object} = T(x)


# # convert a tuple of objects to a single object of the Cartesian product space
# function convert(::Type{<:CartesianProduct}, x::Tuple{Vararg{<:Object}}) 
#     Atom{CartesianProduct{Tuple{space.(x)...}}}(x)
# end

# function convert(::Type{CartesianPower{T}}, x::Tuple{Vararg{Object{T}}}) where T 
#     Object{CartesianPower{T}}(x)
# end



############################################################################################
# FUNCTION SPACE
############################################################################################

mutable struct FunctionSpace <: Space
    label::String
    domain::Space
    codomain::Space
    objects::Objects # Subset{Powerset{domain × codomain}}
    graph::Subset

    FunctionSpace(X::Space, Y::Space) = get!(_cache_function, (X,Y)) do
        new( "", X, Y, Objects(), Subset{X × Y}() )
    end
end

const _cache_function = Dict{Tuple{Space,Space}, FunctionSpace}()

graph(x::Object) = structures(space(x))(:graph)(x)

domain(T::FunctionSpace) = T.domain
codomain(T::FunctionSpace) = T.codomain
graph(s::FunctionSpace) = s.graph
spaces(T::FunctionSpace) = Spaces([domain(T), codomain(T)])

sample(s::FunctionSpace, x::Object) = sample(objects(s), x)

→(T1::Space, T2::Space) = FunctionSpace(T1,T2)



############################################################################################
# OPERATOR SPACE
############################################################################################

mutable struct OperatorSpace <: Space
    label::String
    domain::Space
    codomain::Space
    samples::MultiValuedRelation{Object, Object}
    labeler::Function

    function OperatorSpace(X::Space, Y::Space)
        new( "", X, Y, MultiValuedRelation{Object,Object}(), () -> "" )
    end
end

domain(T::OperatorSpace) = T.domain
codomain(T::OperatorSpace) = T.codomain
spaces(T::OperatorSpace) = Spaces([domain(T), codomain(T)])
relation(s::OperatorSpace) = s.samples

⇒(T1::Space, T2::Space) = OperatorSpace(T1,T2)


############################################################################################
# BINARY OPERATOR
############################################################################################

mutable struct BinaryOperator <: Space
    label::String
    space::Space
    samples::SingleValuedRelation{Object, SingleValuedRelation{Object, Object}}

    function BinaryOperator(s::Space)
        d = SingleValuedRelation{Object, SingleValuedRelation{Object,Object}}()
        new( "", s, d )
    end
end

space(s::BinaryOperator) = s.space
domain(s::BinaryOperator) = space(s) × space(s)
codomain(s::BinaryOperator) = space(s)
relation(s::BinaryOperator) = s.samples


# const Scaling{V<:VectorSpace, F<:Field} = AbstractFunction{CartesianProduct{Tuple{F,V}}, V}

# field(::Type{Scaling{V,F}}) where {V,F} = F
# vectorspace(::Type{Scaling{V,F}}) where {V,F} = V

# const UnaryOperator{X<:Space} = AbstractFunction{X, X}
# const BinaryOperator{X<:Space} = AbstractFunction{CartesianPower{X, 2}, X}
# const NaryOperator{X<:Space} = AbstractFunction{CartesianPower{X}, X}

# abstract type BinaryOperator{X<:Space} <: Space end
# abstract type NaryOperator{X<:Space} <: Space end

# arity(::UnaryOperator) = 1
# arity(::BinaryOperator) = 2


############################################################################################
# DOMAIN / CODOMAIN
############################################################################################

# domain(::TypeVar) = Union{}
# codomain(::TypeVar) = Union{}

# domain(::Operator{X,Y}) where {X,Y} = X
# codomain(::Operator{X,Y}) where {X,Y} = Y

# codomain(::Functional{V}) where {F<:Field, V<:VectorSpace{F}} = F

domain(e::Object) = domain(space(e))
codomain(e::Object) = codomain(space(e))

# domain(::BinaryOperator{T}) where T = T × T
# codomain(::BinaryOperator{T}) where T = T

# domain(::NaryOperator{T}) where T = CartesianPower{T}
# codomain(::NaryOperator{T}) where T = T

# domain(::Type{<:Object{CartesianPower{T}}}) where {T, N} = NTuple{N, T}


############################################################################################
# TYPES OF SPACES
############################################################################################

isfunction(::Space) = false
isfunction(::FunctionSpace) = true
isfunction(::OperatorSpace) = true
# isfunction(::Operator) = true
# isfunction(::BinaryOperator) = true
# isfunction(::NaryOperator) = true

function issinglevalued(T::Space)
    isfunction(T) ? false : error("$T is not a function space.")
end
issinglevalued(::AbstractFunction) = true
# issinglevalued(::Functional) = true
# issinglevalued(::BinaryOperator) = true
# issinglevalued(::NaryOperator) = true

issubset(T1::Space, T2::Space) = typeof(T1) <: typeof(T2)

function canevaluate(T1::Space, T2::Space)
    isfunction(T1) && issubset(T2, domain(T1)) ? true : false
end

isfunctional(::Space) = false
# isfunctional(::Functional) = true

# additiveidentity(::Type{T}) where {T<:Space} = isgroup(T, +) ? Zero{T}() : error("Space $T is not a group over addition")

# multiplicativeidentity(::Type{T}) where {T<:Space} = isgroup(T, *) ? One{T}() : error("Space $T is not a group over multiplication")


isvectorspace(e1::Object, e2::Object) = isvectorspace(space(e1),space(e2))
canevaluate(e1::Object, e2::Object) = canevaluate(space(e1), space(e2))
isfunction(e::Object) = isfunction(space(e))
issinglevalued(e::Object) = issinglevalued(space(e))
isfunctional(e::Object) = isfunctional(space(e))




############################################################################################
# Real numbers

"""
    Field <: Space

A field.

An element of a field is a scalar. A scalar is an object that can be an affine function of other scalars and inner products of points in an inner product space over the field.

Use [`@field]`](@ref) to construct a field.
"""
mutable struct Field <: Space
    label::String
    objects::Objects
    structures::Structures

    function Field(l::String)
        K = new(l, Objects(), Structures())
        op = K × K → K
        push!(K.structures, :+, Atom(op, "+"))
        push!(K.structures, :*, Atom(op, "*"))
        K
    end
end

"""
    R <: Field

The field of real numbers.
"""
const R = Field("R")


# """
#     𝓛{V}

# Space of linear functionals on a vector space `V`.
# """
# struct 𝓛{V} <: LinearFunctional{V}
#     # gradient::Object{AbstractFunction{𝓛{V},UnaryOperator{V}}}
#     # relation::Object{AbstractFunction{𝓛{V},SingleValuedRelation}}
#     gradient::Object
#     relation::Object
#     # relation::SingleValuedRelation{𝓛{V},SingleValuedRelation}

#     function Base.reinterpret(::Type{𝓛{V}}) where V
#         gradient = AbstractFunction{𝓛{V},UnaryOperator{V}}()
#         gradient.labeler = x -> "∇$(label(x))"
#         relation = AbstractFunction{𝓛{V},SingleValuedRelation}()
#         new{V}(gradient, relation)
#     end
# end

# const _𝓛 = Dict{VectorSpace,𝓛}()
# instance(::Type{𝓛{V}}) where {V<:VectorSpace} = get(_𝓛, V, reinterpret(𝓛{V}))


# """
#     𝓕{V}

# Space of differentiable functionals on a vector space `V`.
# """
# struct 𝓕{V} <: Functional{V}
#     gradient::Object{AbstractFunction{𝓕{V},UnaryOperator{V}}}

#     function Base.reinterpret(::Type{𝓕{V}}) where V
#         grad = AbstractFunction{𝓕{V},UnaryOperator{V}}()
#         grad.labeler = x -> "∇$(label(x))"
#         new{V}(grad)
#     end
# end

# const _𝓕 = Dict{VectorSpace,𝓕}()
# instance(::Type{𝓕{V}}) where {V<:VectorSpace} = get(_𝓕, V, reinterpret(𝓕{V}))



# """
#     Rⁿ <: InnerProductSpace

# A real inner product space.
# """
# struct Rⁿ <: InnerProductSpace{R}
#     addition::Object{Addition{Rⁿ}}
#     scaling::Object{Scaling{Rⁿ,R}}
#     dual::Object{AbstractFunction{Rⁿ,Rⁿ'}}

#     function Base.reinterpret(::Type{Rⁿ})
#         f = Addition{Rⁿ}()
#         g = Scaling{Rⁿ,R}()
#         h = AbstractFunction{Rⁿ,Rⁿ'}()
#         f ∈ Associative
#         f ∈ Commutative
#         h.labeler = x -> "$(label(x))'"
#         new(f, g, h)
#     end
# end

# const _Rⁿ = reinterpret(Rⁿ)
# instance(::Type{Rⁿ}) = _Rⁿ
# structures(::Type{Rⁿ}) = Atoms([
#     instance(Rⁿ).addition, instance(Rⁿ).scaling, instance(Rⁿ).dual])

# """
#     Rᵐ <: InnerProductSpace

# A real inner product space.
# """
# struct Rᵐ <: InnerProductSpace{R}
#     addition::Object{Addition{Rᵐ}}
#     scaling::Object{Scaling{Rᵐ,R}}

#     function Base.reinterpret(::Type{Rᵐ})
#         f = Addition{Rᵐ}()
#         g = Scaling{Rᵐ,R}()
#         f ∈ Associative
#         f ∈ Commutative
#         new(f, g)
#     end
# end

# const _Rᵐ = reinterpret(Rᵐ)
# instance(::Type{Rᵐ}) = _Rᵐ
# structures(::Type{Rᵐ}) = Atoms([
#     instance(Rᵐ).addition, instance(Rᵐ).scaling, instance(Rᵐ).dual])



getfields(x) = Set( getfield(x,i) for i ∈ 1:fieldcount(typeof(x)) )

# operators(::Type{<:Space}) = Operators()
# operators(::Type{R}) = getfields(instance(R))


isimplementable(::Any) = false
isimplementable(::Type{Field}) = true
isimplementable(::Type{<:Real}) = true
# isimplementable(::Type{CartesianProduct{T}}) where T =
#     isimplementable(T1) && isimplementable(T2)

juliatype(::Any) = Union{}
# juliatype(::Type{R}) = Real
# juliatype(::Type{R × R}) = Tuple{Real, Real}

algorithmtype(::Any) = Union{}
# algorithmtype(::Type{Real}) = R
# algorithmtype(::Type{Tuple{Real, Real}}) = R × R

convert(::Type{<:Object}, x::Number) = Atom(R)

# convert(::Type{<:Object{R}}, x::Real) = Atom{R}(x)
# # convert(::Type{<:Expression{R}}, ::Zero) = R(0)
# # convert(::Type{<:Expression{R}}, ::One) = R(1)

promote_rule(::Type{<:Object}, ::Type{<:Number}) = Object

# +(x::Real, y::Expression{R}) = +(promote(x,y)...)
# +(x::Expression{R}, y::Real) = y + x
# -(x::Real, y::Expression{R}) = x + (-y)
# -(x::Expression{R}, y::Real) = x + (-y)
# *(x::Real, y::Expression{R}) = *(promote(x,y)...)
# *(x::Expression{R}, y::Real) = R(y)*x
# /(x::Real, y::Expression{R}) = /(promote(x,y)...)
# /(x::Expression{R}, y::Real) = /(promote(x,y)...)

# *(a::Real, x::Decomposition{R}) = R(a) * x
# *(x::Real, y::Expression{<:VectorSpace{R}}) = R(x) * y
# *(x::Real, y::Expression{<:LinearFunctional{<:VectorSpace{R}}}) = R(x) * y

# # function *(X::Matrix{<:JuMP.AbstractJuMPScalar}, Y::Matrix{R})
# #     if size(X)[2] != size(Y)[1]
# #         error("Matrix dimensions do not agree for matrix multiplication, dimensions are $(size(X)) and $(size(Y))")
# #     end
# #     Z = Matrix{R}(undef, size(X)[1], size(Y)[2])
# #     for i = 1:size(X)[1], j = 1:size(Y)[2]
# #         Z[i,j] = R(0)
# #         for k = 1:size(X)[2]
# #             Z[i,j] += X[i,k]*Y[k,j]
# #         end
# #     end
# #     Z
# # end

# zero(::Type{R}) = R(0)
# one(::Type{R}) = R(1)

# # zero(::Type{JuMP.GenericAffExpr}) = JuMP.AffExpr(0)

# iszero(e::R) = e.value isa Zero || (e.value isa Number && iszero(e.value))
# isone(e::R) = e.value isa One || (e.value isa Number && isone(e.value))

# # value(::Zero{R}) = 0
# # value(::One{R}) = 1
