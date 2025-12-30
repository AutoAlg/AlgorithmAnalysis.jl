
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
        new{X,Y}(Dict{Object{X → Y}, Object{X ⇒ X}}())
    end
end

Convex{T}() where {T<:Map} = Convex{domain(T),codomain(T)}()

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

# struct Convex{F,X} <: Property{F}
#     func::SingleValuedMap{X,Y}
#     subdifferential::Object{SingleValuedMap{F, SetValuedMap{X,X}}}

#     function Convex{F,X}() where {F,X}
#         ℱ = new{F,X}(Atom{F → (X ⇒ X)}())
#         push!(properties(F), ℱ)
#         # @eval adjoint(::Type{$F}) = subdifferential($F)
#         # register_methods!(ℱ)
#         # @eval adjoint(f::Object{$F}) = $F.subdifferential(f)
#     end
# end


############################################################################################
# STRONGLY CONVEX
############################################################################################

# struct StronglyConvex{X,Y} <: Property{Object{SingleValuedMap{X,Y}}}
#     parameter::Number
# end

# function ∈(x::Object{SingleValuedMap{X,Y}}, p::StronglyConvex{X,Y}) where {X,Y}
#     m = p.parameter
#     if m == 0
#         push!(properties(x), Convex{X,Y}())
#     elseif m > 0
#         push!(properties(x), p)
#         push!(properties(x), Differentiable{X,Y}())
#     else
#         error("Function is not convex; need m ≥ 0")
#     end
#     nothing
# end


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


"""
Registers a property by turning its relevant fields into global methods.
"""
function register_methods!(prop::Property)

    p = ProgressMeter.ProgressUnknown(desc="Registering methods for property $prop", spinner=true)

    S = space(prop)
    
    # @info "Registering methods for property $prop"

    for field in fieldnames(typeof(prop))

        ProgressMeter.next!(p)

        obj = getfield(prop, field)

        # recursively register methods for properties of properties
        if obj isa Property

            # field(S)
            # println("  $field(::Type{$S})")
            @eval export $field
            @eval $field(::Type{$S}) = $obj
            
            register_methods!(obj)
            
        elseif obj isa Object
            
            # sym(S)
            sym = label(obj)
            # @info "  $sym(::Type{$S})"
            @eval export $sym
            @eval $sym(::Type{$S}) = $obj

            if space(obj) <: Map
                D = domain(obj)

                # function syntax f(x)
                # @info "  $sym(x::Object{$D})"
                @eval $sym(x::Object{$D}) = $obj(x)

                # for Cartesian product domains, also allow the function syntax f(x1,x2,...)
                if D <: CartesianProduct
                    arg_names = [Symbol("x$i") for i in 1:length(D)]
                    typed_args = [:($arg::Object{$type}) for (arg, type) in zip(arg_names, as_tuple(D))]
                    @eval $sym($(typed_args...)) = $obj($(arg_names...))
                end
            end
        end
    end
    ProgressMeter.finish!(p)
    nothing
end


############################################################################################
# MAGMA
############################################################################################

export Magma

struct Magma{T} <: Property{T}
    op::Object{BinaryOperator{T}}

    function Magma{T}(op::Symbol) where T
        M = new{T}( Atom{T × T → T}(op) )
        push!(properties(T), M)
        register_methods!(M)
    end
end

op(M::Magma) = M.op


############################################################################################
# GROUP
############################################################################################

export Group

struct Group{T} <: Property{T}
    id::Object{T}
    op::Object{BinaryOperator{T}}
    inv::Object{Operator{T}}

    function Group{T}(id::Symbol, op::Symbol, inv::Symbol) where T
        G = new{T}( Atom{T}(id), Atom{T × T → T}(op), Atom{T → T}(inv) )
        push!(properties(T), G)
        @eval $inv(x::Object{$T}, y::Object{$T}) = $op(x, $inv(y))
        register_methods!(G)
        G
    end
end

id(G::Group) = G.id
op(G::Group) = G.op
inv(G::Group) = G.inv


############################################################################################
# RING
############################################################################################

export Ring

struct Ring{T} <: Property{T}
    add_group::Group{T}
    mul_group::Group{T}

    function Ring{T}() where T
        R = new{T}( Group{T}(:zero, :+, :-), Group{T}(:one, :*, :/) )
        push!(properties(T), R)
        register_methods!(R)
    end
end

zero(R::Ring) = id(R.add_group)
one(R::Ring) = id(R.mul_group)
plus(R::Ring) = op(R.add_group)
mult(R::Ring) = op(R.mul_group)
neg(R::Ring) = inv(R.add_group)
inv(R::Ring) = inv(R.mul_group)


############################################################################################
# VECTOR SPACE
############################################################################################

export VectorSpace

struct VectorSpace{V,F} <: Property{V}
    vectors::Group{V}
    scale::Object{SingleValuedMap{CartesianProduct{Tuple{F,V}},V}}

    function VectorSpace{V,F}() where {V,F}
        VS = new{V,F}( Group{V}(:zero, :+, :-), Atom{F × V → V}(:⋅) )
        push!(properties(V), VS)
        register_methods!(VS)
    end
end

zero(V::VectorSpace) = zero(vectors(V))
add(V::VectorSpace) = op(vectors(V))
neg(V::VectorSpace) = inv(vectors(V))
field(::VectorSpace{V,F}) where {V,F} = F


############################################################################################
# INNER PRODUCT SPACE
############################################################################################

export InnerProductSpace, innerproductspace

struct InnerProductSpace{V,F} <: Property{V}
    vectors::Group{V}
    scale::Object{SingleValuedMap{CartesianProduct{Tuple{F,V}},V}}
    adjoint::Object{SingleValuedMap{V, LinearMap{V,F}}}

    function InnerProductSpace{V,F}() where {V,F}
        adj = Atom{V → LinearMap{V,F}}(:adjoint)
        adj.labeler = x -> ismissing(label(x)) ? missing : Symbol(label(x), "'")
        VS = new{V,F}( Group{V}( :zero, :+, :- ), Atom{F × V → V}(:⋅), adj )
        push!(properties(V), VS)
        register_methods!(VS)
    end
end

zero(V::InnerProductSpace) = zero(vectors(V))
add(V::InnerProductSpace) = op(vectors(V))
neg(V::InnerProductSpace) = inv(vectors(V))
field(::InnerProductSpace{V,F}) where {V,F} = F


############################################################################################
# IMPLEMENTATION
############################################################################################

export @implementation, implement, isimplementable

function isimplementable end
function juliatype end
function algorithmtype end
function value! end
function properties end
function implement end

isimplementable(::Type{<:Component}) = false
isimplementable(::Type{T}) where {T<:CartesianProduct} = all(isimplementable.(as_tuple(T)))

"""
    @implementation(S, T)

Defines methods associating the type `S<:Space` with the Julia type `T`.
Recursively calls `implement` for all properties of `S`.

An object is implementable if it can be instantiated by a concrete type in Julia.
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

function implement(prop::Property{T1}, T2::DataType) where T1
    for field in fieldnames(typeof(prop))
        func = getfield(prop, field)
        op = label(func)

         if space(func) <: BinaryOperator
            @eval $op(x::Object{$T1}, y::$T2) = $op(promote(x,y)...)
            @eval $op(x::$T2, y::Object{$T1}) = $op(promote(x,y)...)
        end
    end
    nothing
end

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