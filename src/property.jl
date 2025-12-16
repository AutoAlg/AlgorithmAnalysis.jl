
export Property, Properties, properties, hasproperties, @property, get
export Linear, Invertible, Differentiable, LocallyLipschitz, Convex, StronglyConvex
export SelfAdjoint
export inv, gradient, clark_subdifferential, subdifferential
export Ring, zero, one

############################################################################################
# PROPERTIES
############################################################################################

properties(x::Object) = hasfield(typeof(x), :properties) ? x.properties : Properties{typeof(x)}()
delete!(x::Object, p::Property) = delete!(properties(x), p)
hasproperties(x::Object) = length(properties(x)) > 0
space(::Property{T}) where T = T

function ∈(x::Object, p::Property)
    if space(x) ≠ space(p)
        error("The space of the property must match that of the object $x")
    end
    push!(properties(x), p)
end

∈(x::Object, properties::Properties) = map(p -> x ∈ p, properties)

function get(x, T::Type{<:Property})
    for p in properties(x)
        if typeof(p) <: T
            return p
        end
    end
    # error("Error: $x does not have property $T")
    missing
end


############################################################################################

"""
    @property a ∈ P, ...

Assign a property to an object.
"""
macro property(ex)
    _property(ex)
end

function _property(expr::Expr)
    if expr.head == :tuple
        Expr(:block, [ _property(arg) for arg ∈ expr.args ]...)
    elseif expr.head == :call && (expr.args[1] == :(∈) || expr.args[1] == :in)
        a = esc(expr.args[2])
        P = esc(expr.args[3])
        quote
            push!($a, $P); nothing
        end
    else
        error("@property expects `a ∈ P`")
    end
end


############################################################################################
# FUNCTION SPACE PROPERTIES
############################################################################################

domain(::Property{<:Map{X,Y}}) where {X,Y} = X
codomain(::Property{<:Map{X,Y}}) where {X,Y} = Y

function ∈(x::Object{Map}, p::Property{Map})
    if domain(x) ≠ domain(p)
        error("The domain of the property must match that of $x")
    end
    if codomain(x) ≠ codomain(p)
        error("The codomain of the property must match that of $x")
    end
    push!(properties(x), p)
    nothing
end


############################################################################################
# INVERTIBLE
############################################################################################

struct Invertible{X,Y} <: Property{Object{SingleValuedMap{X,Y}}}
    inverse::Dict{Object{SingleValuedMap{X,Y}}, Object{SingleValuedMap{Y,X}}}

    Invertible{X,Y}() where {X,Y} = get!(_CACHE, Invertible{X,Y}) do
        new{X,Y}(Dict{Object{SingleValuedMap{X,Y}}, Object{SingleValuedMap{Y,X}}}())
    end
end

domain(::Invertible{X,Y}) where {X,Y} = X
codomain(::Invertible{X,Y}) where {X,Y} = Y

function inv(f::Object{T}) where {X, Y, T<:SingleValuedMap{X,Y}}
    t = get(f, Invertible)
    if ismissing(t)
        error("Function $f is not invertible")
    end
    get!(t.inverse, f) do
        f⁻¹ = Atom{Y → X}(Symbol(label(f), "⁻¹"))
        f⁻¹ ∈ Invertible{Y,X}()
        for (x,y) ∈ graph(f)
            push!(graph(f⁻¹), TupleDecomposition(y,x))
        end
        get!(get(f⁻¹, Invertible).inverse, f⁻¹) do
            f
        end
        f⁻¹
    end
end


############################################################################################
# DIFFERENTIABLE
############################################################################################

struct Differentiable{X,Y} <: Property{Object{SingleValuedMap{X,Y}}}
    gradient::Dict{Object{SingleValuedMap{X,Y}}, Object{SingleValuedMap{X,X}}}

    Differentiable{X,Y}() where {X,Y} = get!(_CACHE, Differentiable{X,Y}) do
        new{X,Y}(Dict{Object{SingleValuedMap{X,Y}}, Object{SingleValuedMap{X,X}}}())
    end
end

function ∈(x::Object{SingleValuedMap{X,Y}}, ::Differentiable{X,Y}) where {X,Y}
    if !ismissing(get(x, LocallyLipschitz))
        error("Function $x is already locally Lipschitz.")
    end
    push!(properties(x), Differentiable{X,Y}())
    nothing
end

function gradient(f::Object{T}) where {X, Y, T<:SingleValuedMap{X,Y}}
    t = get(f, Differentiable)
    if ismissing(t)
        error("Function $f does not have a gradient because it is not differentiable")
    end
    get!(t.gradient, f) do
        Atom{X → X}(Symbol("∇", label(f)))
    end
end


# struct NDifferentiable{N,X,Y} <: Property{Object{SingleValuedMap{X,Y}}} end

# function ∈(x::Object{SingleValuedMap{X,Y}}, ::NDifferentiable{N,X,Y}) where {N,X,Y}
#     if N == 0
#         return
#     end
#     if N < 0
#         error("In NDifferentiable{N,X,Y}, the parameter N must be a positive integer")
#     end
#     x ∈ Differentiable{X,Y}()
#     x' ∈ NDifferentiable{N-1,domain(x'),codomain(x')}()
# end


############################################################################################
# LOCALLY LIPSCHITZ
############################################################################################

struct LocallyLipschitz{X,Y} <: Property{Object{SingleValuedMap{X,Y}}}
    clark_subdifferential::Dict{Object{SingleValuedMap{X,Y}}, Object{SetValuedMap{X,X}}}

    LocallyLipschitz{X,Y}() where {X,Y} = get!(_CACHE, LocallyLipschitz{X,Y}) do
        new{X,Y}(Dict{Object{SingleValuedMap{X,Y}}, Object{SetValuedMap{X,X}}}())
    end
end

function ∈(x::Object{SingleValuedMap{X,Y}}, ::Type{LocallyLipschitz{X,Y}}) where {X,Y}
    if !ismissing(x(Differentiable))
        error("Function $x is already differentiable.")
    end
    push!(properties(x), LocallyLipschitz{X,Y}())
    nothing
end

function clark_subdifferential(f::Object{T}) where {X, Y, T<:SingleValuedMap{X,Y}}
    t = get(f, LocallyLipschitz)
    if ismissing(t)
        error("Function $f does not have a Clark subdifferential because it is not locally Lipschitz")
    end
    get!(t.clark_subdifferential, f) do
        Atom{X ⇒ X}(Symbol("∂c", label(f)))
    end
end


############################################################################################
# CONVEX
############################################################################################

struct Convex{X,Y} <: Property{Object{SingleValuedMap{X,Y}}}
    subdifferential::Dict{Object{SingleValuedMap{X,Y}}, Object{SetValuedMap{X,X}}}

    Convex{X,Y}() where {X,Y} = get!(_CACHE, Convex{X,Y}) do
        new{X,Y}(Dict{Object{SingleValuedMap{X,Y}}, Object{SetValuedMap{X,X}}}())
    end
end

function ∈(x::Object{SingleValuedMap{X,Y}}, ::Convex{X,Y}) where {X,Y}
    push!(properties(x), Convex{X,Y}())
    nothing
end

function subdifferential(f::Object{T}) where {X, Y, T<:SingleValuedMap{X,Y}}
    t = get(f, Convex)
    if ismissing(t)
        error("Function $f does not have a subdifferential because it is not convex")
    end
    get!(t.subdifferential, f) do
        Atom{X ⇒ X}(Symbol("∂", label(f)))
    end
end


############################################################################################
# STRONGLY CONVEX
############################################################################################

struct StronglyConvex{X,Y} <: Property{Object{SingleValuedMap{X,Y}}}
    parameter::Number
end

function ∈(x::Object{SingleValuedMap{X,Y}}, p::StronglyConvex{X,Y}) where {X,Y}
    m = p.parameter
    if m == 0
        push!(properties(x), Convex{X,Y}())
    elseif m > 0
        push!(properties(x), p)
        push!(properties(x), Differentiable{X,Y}())
    else
        error("Function is not convex; need m ≥ 0")
    end
    nothing
end


############################################################################################
# OPERATOR PROPERTIES
############################################################################################

# abstract type OnePointProperty <: Property end
# abstract type TwoPointProperty <: Property end
# abstract type AllPointProperty <: Property end

# abstract type OperatorProperty <: Property end
# abstract type FunctionProperty <: Property end

# abstract type InnerProductSpaceProperty <: OperatorProperty end
# abstract type NormedVectorSpaceProperty <: OperatorProperty end
# abstract type Monotonicity <: InnerProductSpaceProperty end
# abstract type RelativeBoundedness <: NormedVectorSpaceProperty end
# abstract type Boundedness <: NormedVectorSpaceProperty end
# abstract type LinearMapProperty <: Property end
# abstract type SquareLinearMapProperty <: Property end
# abstract type FunctionalProperty <: Property end



# Each structure is a subtype of Property{T}, where T<:Set is the underlying set.
# The fields of the struct should store all quantities related to the structure, such as unary and binary operators, and special elements of the set such as one and zero. Accessor methods should be defined for each field.



############################################################################################
# MAGMA
############################################################################################

export Magma

struct Magma{X} <: Property{X}
    op::Object{BinaryOperator{X}}

    Magma{X}(s::Symbol) where X = get!(_CACHE, Magma{X}) do
        new{X}( Atom{X × X → X}(s) )
    end
end

op(M::Magma) = M.op

function ∈(::Type{T}, prop::Magma{T}) where T
    push!(properties(T), prop)
    @eval $(prop.op.label)(x::Object{$T}, y::Object{$T}) = op(magma($T))(x,y)
    nothing
end

function magma(s::Space)
    M = get(s, Magma)
    if ismissing(M)
        error("Space $s is not a magma")
    end
    M
end

magma(T::Type{<:Space}) = magma(instance(T))


export @implementation, implement, isimplementable

function isimplementable end
function juliatype end
function algorithmtype end
function value! end
function properties end
function implement end

"""
    @implementation(S, T)

Defines methods associating the Space type `S` with the Julia type `T`.
Recursively calls `implement` for all properties of `S`.
"""
macro implementation(S::Symbol, T::Symbol)
    s = esc(S)
    t = esc(T)
    M = :AlgorithmAnalysis
    quote
        $M.isimplementable(::Type{$s}) = true
        $M.juliatype(::Type{$s}) = $t
        $M.algorithmtype(::Type{$t}) = $s
        Base.promote_rule(::Type{<:Object}, ::Type{<:$t}) = Object
        function Base.convert(::Type{Object}, x::$t)
            a = $M.Atom{$s}()
            $M.value!(a, x)
            return a
        end
        for prop ∈ $M.properties($s)
            $M.implement(prop, $t)
        end
    end
end

# by default, properties have no additional implementation
implement(::Property, ::DataType) = nothing



############################################################################################
# GROUP
############################################################################################

export Group

struct Group{X} <: Property{X}
    id::Object{X}
    op::Object{BinaryOperator{X}}
    inv::Object{Operator{X}}

    Group{X}(op::Symbol, id::Symbol) where X = get!(_CACHE, Group{X}) do
        new{X}( Atom{X}(id), Atom{X × X → X}(op), Atom{X → X}(:⁻¹) )
    end
end

id(G::Group) = G.id
op(G::Group) = G.op
inv(G::Group) = G.inv

function ∈(::Type{T}, G::Group{T}) where T
    push!(properties(T), G)
    @eval $(label(op(G)))(x::Object{$T}, y::Object{$T}) = op(get($T, Group))(x,y)
    nothing
end

function group(s::Space)
    G = get(s, Group)
    if ismissing(G)
        error("Space $s is not a group")
    end
    G
end

group(T::Type{<:Space}) = group(instance(T))

function implement(G::Group{T1}, T2::DataType) where T1
    op_sym = label(op(G))
    @eval begin
        $(op_sym)(x::Object{$T1}, y::$T2) = $(op_sym)(promote(x,y)...)
        $(op_sym)(x::$T2, y::Object{$T1}) = $(op_sym)(promote(x,y)...)
    end
    nothing
end


############################################################################################
# RING
############################################################################################

export Ring

struct Ring{X} <: Property{X}
    zero::Object{X}
    one::Object{X}
    plus::Object{BinaryOperator{X}}
    mult::Object{BinaryOperator{X}}
    neg::Object{Operator{X}}
    inv::Object{Operator{X}}

    Ring{X}() where X = get!(_CACHE, Ring{X}) do
        zero = Atom{X}(Symbol(0))
        one  = Atom{X}(Symbol(1))
        plus = Atom{X × X → X}(:+)
        mult = Atom{X × X → X}(:*)
        neg  = Atom{X → X}(:-)
        inv  = Atom{X → X}(:/)
        new{X}( zero, one, plus, mult, neg, inv )
    end
end

zero(R::Ring) = R.zero
one(R::Ring) = R.one
plus(R::Ring) = R.plus
mult(R::Ring) = R.mult
neg(R::Ring) = R.neg
inv(R::Ring) = R.inv

zero(S::Type{<:Space}) = zero(get(S, Ring))
one(S::Type{<:Space}) = one(get(S, Ring))

iszero(x::Object{X}) where X = x === zero(X)
isone(x::Object{X}) where X = x === one(X)

function ∈(::Type{T}, R::Ring{T}) where T
    push!(properties(T), R)
    @eval begin
        function $(label(plus(R)))(x::Object{$T}, y::Object{$T})
            p = get($T, Ring)
            if ismissing(p)
                error("$T is not a ring")
            elseif iszero(x)
                y
            elseif iszero(y)
                x
            else
                plus(p)(x,y)
            end
        end
        function $(label(mult(R)))(x::Object{$T}, y::Object{$T})
            p = get($T, Ring)
            if ismissing(p)
                error("$T is not a ring")
            elseif isone(x)
                y
            elseif isone(y)
                x
            else
                mult(p)(x,y)
            end
        end
        function $(label(neg(R)))(x::Object{$T})
            p = get($T, Ring)
            if ismissing(p)
                error("$T is not a ring")
            end
            iszero(x) ? x : neg(p)(x)
        end
        function $(label(inv(R)))(x::Object{$T})
            p = get($T, Ring)
            if ismissing(p)
                error("$T is not a ring")
            end
            isone(x) ? x : inv(p)(x)
        end
        function $(label(neg(R)))(x::Object{$T}, y::Object{$T})
            $(label(plus(R)))(x, $(label(neg(R)))(y))
        end
        function $(label(inv(R)))(x::Object{$T}, y::Object{$T})
            $(label(mult(R)))(x, $(label(inv(R)))(y))
        end
    end
    nothing
end

function ring(s::Space)
    R = get(s, Ring)
    if ismissing(R)
        error("Space $s is not a ring")
    end
    R
end

ring(T::Type{<:Space}) = ring(instance(T))

function implement(R::Ring{T1}, T2::DataType) where T1
    plus_sym = label(plus(R))
    mult_sym = label(mult(R))
    neg_sym = label(neg(R))
    inv_sym = label(inv(R))
    @eval begin
        $(plus_sym)(x::Object{$T1}, y::$T2) = $(plus_sym)(promote(x,y)...)
        $(plus_sym)(x::$T2, y::Object{$T1}) = $(plus_sym)(promote(x,y)...)
        $(mult_sym)(x::Object{$T1}, y::$T2) = $(mult_sym)(promote(x,y)...)
        $(mult_sym)(x::$T2, y::Object{$T1}) = $(mult_sym)(promote(x,y)...)
        $(neg_sym)(x::Object{$T1}, y::$T2) = $(neg_sym)(promote(x,y)...)
        $(neg_sym)(x::$T2, y::Object{$T1}) = $(neg_sym)(promote(x,y)...)
        $(inv_sym)(x::Object{$T1}, y::$T2) = $(inv_sym)(promote(x,y)...)
        $(inv_sym)(x::$T2, y::Object{$T1}) = $(inv_sym)(promote(x,y)...)
    end
    nothing
end


############################################################################################
# VECTOR SPACE
############################################################################################

export VectorSpace

struct VectorSpace{V,F} <: Property{V}
    zero::Object{V}
    add::Object{BinaryOperator{V}}
    neg::Object{Operator{V}}
    scale::Object{SingleValuedMap{CartesianProduct{Tuple{F,V}},V}}

    VectorSpace{V,F}() where {V,F} = get!(_CACHE, VectorSpace{V,F}) do
        new{V,F}(
            Atom{V}(Symbol(0)),
            Atom{V × V → V}(:+),
            Atom{V → V}(:-),
            Atom{F × V → V}(:⋅)
        )
    end
end

zero(V::VectorSpace) = V.zero
add(V::VectorSpace) = V.add
neg(V::VectorSpace) = V.neg
scale(V::VectorSpace) = V.scale
field(::VectorSpace{V,F}) where {V,F} = F

function ∈(::Type{T}, V::VectorSpace{T,F}) where {T,F}
    push!(properties(T), V)
    @eval begin
        function $(label(add(V)))(x::Object{$T}, y::Object{$T})
            p = get($T, VectorSpace)
            if ismissing(p)
                error("$T is not a vector space")
            elseif iszero(x)
                y
            elseif iszero(y)
                x
            else
                add(p)(x,y)
            end
        end
        function $(label(scale(V)))(x::Object{$F}, y::Object{$T})
            p = get($T, VectorSpace)
            if isone(x)
                y
            elseif iszero(x)
                zero($T)
            else
                scale(p)(x,y)
            end
        end
        function $(label(neg(V)))(x::Object{$T})
            p = get($T, VectorSpace)
            iszero(x) ? x : neg(p)(x)
        end
        function $(label(neg(V)))(x::Object{$T}, y::Object{$T})
            $(label(add(V)))(x, $(label(neg(V)))(y))
        end
    end
    nothing
end

function vectorspace(s::Space)
    V = get(s, VectorSpace)
    if ismissing(V)
        error("Space $s is not a vector space")
    end
    V
end

vectorspace(T::Type{<:Space}) = vectorspace(instance(T))


############################################################################################
# INNER PRODUCT SPACE
############################################################################################

export InnerProductSpace, innerproductspace

struct InnerProductSpace{V,F} <: Property{V}
    zero::Object{V}
    add::Object{BinaryOperator{V}}
    neg::Object{Operator{V}}
    scale::Object{SingleValuedMap{CartesianProduct{Tuple{F,V}},V}}
    adjoint::Object{SingleValuedMap{V, LinearMap{V,F}}}

    InnerProductSpace{V,F}() where {V,F} = get!(_CACHE, InnerProductSpace{V,F}) do
        new{V,F}(
            Atom{V}(Symbol(0)),
            Atom{V × V → V}(:+),
            Atom{V → V}(:-),
            Atom{F × V → V}(:⋅),
            Atom{V → LinearMap{V,F}}(:adjoint)
        )
    end
end

zero(V::InnerProductSpace) = V.zero
add(V::InnerProductSpace) = V.add
neg(V::InnerProductSpace) = V.neg
scale(V::InnerProductSpace) = V.scale
adjoint(V::InnerProductSpace) = V.adjoint
field(::InnerProductSpace{V,F}) where {V,F} = F

function ∈(::Type{T}, V::InnerProductSpace{T,F}) where {T,F}
    push!(properties(T), V)
    @eval begin
        function $(label(add(V)))(x::Object{$T}, y::Object{$T})
            p = get($T, InnerProductSpace)
            if ismissing(p)
                error("$T is not an inner product space")
            elseif iszero(x)
                y
            elseif iszero(y)
                x
            else
                add(p)(x,y)
            end
        end
        function $(label(scale(V)))(x::Object{$F}, y::Object{$T})
            p = get($T, InnerProductSpace)
            if isone(x)
                y
            elseif iszero(x)
                zero($T)
            else
                scale(p)(x,y)
            end
        end
        function $(label(neg(V)))(x::Object{$T})
            p = get($T, InnerProductSpace)
            iszero(x) ? x : neg(p)(x)
        end
        function $(label(neg(V)))(x::Object{$T}, y::Object{$T})
            $(label(add(V)))(x, $(label(neg(V)))(y))
        end
        function $(label(adjoint(V)))(x::Object{$T})
            p = get($T, InnerProductSpace)
            adjoint(p)(x)
        end
    end
    nothing
end

function innerproductspace(s::Space)
    V = get(s, InnerProductSpace)
    if ismissing(V)
        error("Space $s is not an inner product space")
    end
    V
end

innerproductspace(T::Type{<:Space}) = innerproductspace(instance(T))
