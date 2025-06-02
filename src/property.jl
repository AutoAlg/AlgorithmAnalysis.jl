
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

∈(::Type{X}, prop::Magma{X}) where X = push!(properties(X), prop)

function op(x::Object{T}, y::Object{T}) where T
    p = get(T, Magma)
    if ismissing(p)
        error("$T is not a magma")
    else
        p.op(x,y)
    end
end


############################################################################################
# RING
############################################################################################

struct Ring{X} <: Property{X}
    zero::Object{X}
    one::Object{X}
    plus::Object{BinaryOperator{X}}
    mult::Object{BinaryOperator{X}}

    Ring{X}() where X = get!(_CACHE, Ring{X}) do
        zero = Atom{X}(Symbol(0), false)
        one = Atom{X}(Symbol(1), false)
        plus = Atom{X × X → X}(:+)
        mult = Atom{X × X → X}(:*)
        new{X}( zero, one, plus, mult )
    end
end

∈(::Type{X}, ::Ring{X}) where X = push!(properties(X), Ring{X}())

zero(p::Ring) = p.zero
one(p::Ring) = p.one
plus(p::Ring) = p.plus
mult(p::Ring) = p.mult

zero(S::Type{<:Space}) = zero(get(S, Ring))
one(S::Type{<:Space}) = one(get(S, Ring))

iszero(x::Object{X}) where X = x === zero(X)
isone(x::Object{X}) where X = x === one(X)

function +(x::Object{T}, y::Object{T}) where T
    p = get(T, Ring)
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

function *(x::Object{T}, y::Object{T}) where T
    p = get(T, Ring)
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



