############################################################################################
# REAL NUMBERS
############################################################################################

export Field, R, zero, one, plus, mult

"""
    Field <: Space

An abstract field.

An element of a field is a scalar. A scalar is an object that can be an affine function of other scalars and inner products of points in an inner product space over the field.

Use [`@field]`](@ref) to construct a field.
"""
abstract type Field <: Space end

"""
    R <: Field

Real numbers (as a ring).

An element of a field is a scalar. A scalar is an object that can be an affine function of other scalars and inner products of points in an inner product space over the field.

Use [`@field]`](@ref) to construct a field.
"""
struct R <: Field
    zero::Object{R}
    one::Object{R}
    elements::Objects{R}
    plus::Object{R × R → R}
    mult::Object{R × R → R}
    properties::Properties{R}

    R() = get!(_CACHE, R) do
        zero = Atom{R}(Symbol(0), false)
        one = Atom{R}(Symbol(1), false)
        elements = Objects{R}()
        push!(elements, zero)
        push!(elements, one)
        plus = Atom{R × R → R}(:+)
        mult = Atom{R × R → R}(:*)
        new( zero, one, elements, plus, mult, Properties{R}() )
    end
end

zero(::Type{R}) = R().zero
one(::Type{R}) = R().one
elements(::Type{R}) = R().elements
plus(::Type{R}) = R().plus
mult(::Type{R}) = R().mult
iszero(x::Object{R}) = x === zero(R)
isone(x::Object{R}) = x === one(R)

function +(x::Object{R}, y::Object{R})
    if iszero(x)
        y
    elseif iszero(y)
        x
    else
        plus(R)(x,y)
    end
end

function *(x::Object{R}, y::Object{R})
    if isone(x)
        y
    elseif isone(y)
        x
    elseif iszero(x) || iszero(y)
        zero(R)
    else
        mult(R)(x,y)
    end
end

isimplementable(::Any) = false
isimplementable(::Type{R}) = true
isimplementable(::Type{CartesianProduct{T}}) where T = all(isimplementable.(fieldtypes(T)))

juliatype(::Any) = Union{}
juliatype(::Type{R}) = Real
juliatype(::Type{R × R}) = Tuple{Real, Real}

algorithmtype(::Any) = Union{}
algorithmtype(::Type{Real}) = R
algorithmtype(::Type{Tuple{Real, Real}}) = R × R

function convert(::Type{<:Object}, x::Real)
    if iszero(x)
        zero(R)
    elseif isone(x)
        one(R)
    else
        a = Atom{R}()
        value!(a, x)
        a
    end
end

promote_rule(::Type{<:Object}, ::Type{<:Number}) = Object

+(x::Real, y::Object{R}) = +(promote(x,y)...)
+(x::Object{R}, y::Real) = +(promote(x,y)...)
-(x::Object{R}) = (-1) * x
-(x::Object{R}, y::Object{R}) = x + (-y)
-(x::Real, y::Object{R}) = x + (-y)
-(x::Object{R}, y::Real) = x + (-y)
*(x::Real, y::Object{R}) = *(promote(x,y)...)
*(x::Object{R}, y::Real) = *(promote(x,y)...)
/(x::Real, y::Object{R}) = /(promote(x,y)...)
/(x::Object{R}, y::Real) = /(promote(x,y)...)

adjoint(x::Object{R}) = x

# function *(X::Matrix{<:JuMP.AbstractJuMPScalar}, Y::Matrix{R})
#     if size(X)[2] != size(Y)[1]
#         error("Matrix dimensions do not agree for matrix multiplication, dimensions are $(size(X)) and $(size(Y))")
#     end
#     Z = Matrix{R}(undef, size(X)[1], size(Y)[2])
#     for i = 1:size(X)[1], j = 1:size(Y)[2]
#         Z[i,j] = R(0)
#         for k = 1:size(X)[2]
#             Z[i,j] += X[i,k]*Y[k,j]
#         end
#     end
#     Z
# end


############################################################################################
# REAL VECTOR SPACE
############################################################################################

export VectorSpace, NormedVectorSpace, InnerProductSpace
export Rⁿ

"""
    VectorSpace{F<:Field} <: Space

An abstract vector space.

A vector is an object that can be a linear function of other vectors.
"""
abstract type VectorSpace{F<:Field} <: Space end

"""
    NormedVectorSpace{F<:Field} <: VectorSpace{F}

An abstract normed vector space.
"""
abstract type NormedVectorSpace{F<:Field} <: VectorSpace{F} end

"""
    InnerProductSpace{F<:Field} <: NormedVectorSpace{F}

An abstract inner product space. The inner product of two vectors produces a scalar, and the squared norm is the inner product of a vector with itself.
"""
abstract type InnerProductSpace{F<:Field} <: NormedVectorSpace{F} end

"""
    Rⁿ <: InnerProductSpace

A real inner product space of unspecified dimension.
"""
struct Rⁿ <: InnerProductSpace{R}
    zero::Object{Rⁿ}
    elements::Objects{Rⁿ}
    plus::Object{Rⁿ × Rⁿ → Rⁿ}
    mult::Object{R × Rⁿ → Rⁿ}
    adjoint::Dict{Object{Rⁿ}, Object{LinearMap{Rⁿ,R}}}
    properties::Properties{Rⁿ}

    Rⁿ() = get!(_CACHE, Rⁿ) do
        zero = Atom{Rⁿ}(Symbol(0), false)
        elements = Objects{Rⁿ}()
        push!(elements, zero)
        plus = Atom{Rⁿ × Rⁿ → Rⁿ}(:+)
        mult = Atom{R × Rⁿ → Rⁿ}(:*)
        adjoint = Dict{Object{Rⁿ}, Object{LinearMap{Rⁿ,R}}}()
        new( zero, elements, plus, mult, adjoint, Properties{Rⁿ}() )
    end
end

zero(::Type{Rⁿ}) = Rⁿ().zero
elements(::Type{Rⁿ}) = Rⁿ().elements
plus(::Type{Rⁿ}) = Rⁿ().plus
mult(::Type{Rⁿ}) = Rⁿ().mult
iszero(x::Object{Rⁿ}) = x === zero(Rⁿ)

function +(x::Object{Rⁿ}, y::Object{Rⁿ})
    if iszero(x)
        y
    elseif iszero(y)
        x
    else
        plus(Rⁿ)(x,y)
    end
end

function *(x::Object{R}, y::Object{Rⁿ})
    if isone(x)
        y
    elseif iszero(x) || iszero(y)
        zero(Rⁿ)
    else
        mult(Rⁿ)(x,y)
    end
end

-(x::Object{Rⁿ}) = (-1) * x
-(x::Object{Rⁿ}, y::Object{Rⁿ}) = x + (-y)
*(x::Real, y::Object{Rⁿ}) = *(promote(x,y)...)

adjoint(x::Object{Rⁿ}) = get!(Rⁿ().adjoint, x) do
    Atom{LinearMap{Rⁿ,R}}(Symbol(label(x), "'"))
end

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

# *(a::Real, x::Decomposition{R}) = R(a) * x
# *(x::Real, y::Expression{<:VectorSpace{R}}) = R(x) * y
# *(x::Real, y::Expression{<:LinearFunctional{<:VectorSpace{R}}}) = R(x) * y


# zero(::Type{JuMP.GenericAffExpr}) = JuMP.AffExpr(0)

# iszero(e::R) = e.value isa Zero || (e.value isa Number && iszero(e.value))
# isone(e::R) = e.value isa One || (e.value isa Number && isone(e.value))


