
export Property, Properties, properties, hasproperties, @property
export Invertible, Differentiable, LocallyLipschitz, Convex, StronglyConvex
export inv, gradient, clark_subdifferential, subdifferential


############################################################################################
# PROPERTIES
############################################################################################

properties(x::Object) = hasfield(typeof(x), :properties) ? x.properties : Properties()
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

function (x::Object)(T::Type{<:Property})
    for p in properties(x)
        typeof(p) <: T && return p
    end
    return missing
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

struct Invertible{X,Y} <: Property{SingleValuedMap{X,Y}}
    inverse::Dict{Object{SingleValuedMap{X,Y}}, Object{SingleValuedMap{Y,X}}}

    Invertible{X,Y}() where {X,Y} = get!(_CACHE, Invertible{X,Y}) do
        new{X,Y}(Dict{Object{SingleValuedMap{X,Y}}, Object{SingleValuedMap{Y,X}}}())
    end
end

domain(::Invertible{X,Y}) where {X,Y} = X
codomain(::Invertible{X,Y}) where {X,Y} = Y

function inv(f::Object{T}) where {X, Y, T<:SingleValuedMap{X,Y}}
    t = f(Invertible)
    if ismissing(t)
        error("Function $f is not invertible")
    end
    get!(t.inverse, f) do
        f⁻¹ = Atom{Y → X}(Symbol(label(f), "⁻¹"))
        f⁻¹ ∈ Invertible{Y,X}()
        for (x,y) ∈ graph(f)
            push!(graph(f⁻¹), TupleDecomposition(y,x))
        end
        get!(f⁻¹(Invertible).inverse, f⁻¹) do
            f
        end
        f⁻¹
    end
end


############################################################################################
# DIFFERENTIABLE
############################################################################################

struct Differentiable{X,Y} <: Property{SingleValuedMap{X,Y}}
    gradient::Dict{Object{SingleValuedMap{X,Y}}, Object{SingleValuedMap{X,X}}}

    Differentiable{X,Y}() where {X,Y} = get!(_CACHE, Differentiable{X,Y}) do
        new{X,Y}(Dict{Object{SingleValuedMap{X,Y}}, Object{SingleValuedMap{X,X}}}())
    end
end

function ∈(x::Object{SingleValuedMap{X,Y}}, ::Differentiable{X,Y}) where {X,Y}
    if !ismissing(x(LocallyLipschitz))
        error("Function $x is already locally Lipschitz.")
    end
    push!(properties(x), Differentiable{X,Y}())
end

function gradient(f::Object{T}) where {X, Y, T<:SingleValuedMap{X,Y}}
    t = f(Differentiable)
    if ismissing(t)
        error("Function $f does not have a gradient because it is not differentiable")
    end
    get!(t.gradient, f) do
        Atom{X → X}(Symbol("∇", label(f)))
    end
end


############################################################################################
# LOCALLY LIPSCHITZ
############################################################################################

struct LocallyLipschitz{X,Y} <: Property{SingleValuedMap{X,Y}}
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
    t = f(LocallyLipschitz)
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

struct Convex{X,Y} <: Property{SingleValuedMap{X,Y}}
    subdifferential::Dict{Object{SingleValuedMap{X,Y}}, Object{SetValuedMap{X,X}}}

    Convex{X,Y}() where {X,Y} = get!(_CACHE, Convex{X,Y}) do
        new{X,Y}(Dict{Object{SingleValuedMap{X,Y}}, Object{SetValuedMap{X,X}}}())
    end
end

function ∈(x::Object{SingleValuedMap{X,Y}}, ::Convex{X,Y}) where {X,Y}
    push!(properties(x), Convex{X,Y}())
end

function subdifferential(f::Object{T}) where {X, Y, T<:SingleValuedMap{X,Y}}
    t = f(Convex)
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

struct StronglyConvex{X,Y} <: Property{SingleValuedMap{X,Y}}
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