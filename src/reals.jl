############################################################################################
# Real numbers

"""
    R <: Field

The field of real numbers.
"""
struct R <: Field
    addition::Element{Addition{R}}
    multiplication::Element{Multiplication{R}}

    # Use a different name for the inner constructor so that we can create real numbers using R(); see https://stackoverflow.com/questions/74801484/inner-constructor-in-julia-with-different-name-than-the-struct
    function Base.reinterpret(::Type{R})
        f = Addition{R}()
        g = Multiplication{R}()
        f ∈ Associative
        f ∈ Commutative
        g ∈ Associative
        new(f, g)
    end
end

const _R = reinterpret(R)
instance(::Type{R}) = _R


"""
    Rⁿ <: InnerProductSpace

A real inner product space.
"""
struct Rⁿ <: InnerProductSpace{R}
    addition::Element{Addition{Rⁿ}}
    scaling::Element{Scaling{Rⁿ,R}}
    dual::Element{AbstractFunction{Rⁿ,LinearFunctional{Rⁿ}}}

    function Base.reinterpret(::Type{Rⁿ})
        f = Addition{Rⁿ}()
        g = Scaling{Rⁿ,R}()
        h = AbstractFunction{Rⁿ,LinearFunctional{Rⁿ}}()
        f ∈ Associative
        f ∈ Commutative
        new(f, g, h)
    end
end

const _Rⁿ = reinterpret(Rⁿ)
instance(::Type{Rⁿ}) = _Rⁿ

"""
    Rᵐ <: InnerProductSpace

A real inner product space.
"""
struct Rᵐ <: InnerProductSpace{R}
    addition::Element{Addition{Rᵐ}}
    scaling::Element{Scaling{Rᵐ,R}}

    function Base.reinterpret(::Type{Rᵐ})
        f = Addition{Rᵐ}()
        g = Scaling{Rᵐ,R}()
        f ∈ Associative
        f ∈ Commutative
        new(f, g)
    end
end

const _Rᵐ = reinterpret(Rᵐ)
instance(::Type{Rᵐ}) = _Rᵐ


"""
    𝓕{V}

A differentiable functional on a vector space `V`.
"""
struct 𝓕{V} <: Functional{V}
    gradient::Element{UnaryOperator{V}}

    function Base.reinterpret(::Type{𝓕{V}}) where {V}
        new{V}(UnaryOperator{V}())
    end
end

const _𝓕 = Dict{VectorSpace,𝓕}()
instance(::Type{𝓕{V}}) where {V<:VectorSpace} = get(_𝓕, V, reinterpret(𝓕{V}))



getfields(x) = Set( getfield(x,i) for i ∈ 1:fieldcount(typeof(x)) )

operators(::Type{<:Space}) = Operators()
operators(::Type{R}) = getfields(instance(R))


isimplementable(::Any) = false
isimplementable(::Type{R}) = true
isimplementable(::Type{<:Real}) = true
# isimplementable(::Type{CartesianProduct{T}}) where T =
#     isimplementable(T1) && isimplementable(T2)

juliatype(::Any) = Union{}
juliatype(::Type{R}) = Real
juliatype(::Type{CartesianProduct{Tuple{R,R}}}) = Tuple{Real, Real}

algorithmtype(::Any) = Union{}
algorithmtype(::Type{Real}) = R
algorithmtype(::Type{Tuple{Real, Real}}) = CartesianProduct{R, R}

# convert(::Type{<:Expression{R}}, x::Real) = Atom{R}(x)
# # convert(::Type{<:Expression{R}}, ::Zero) = R(0)
# # convert(::Type{<:Expression{R}}, ::One) = R(1)
# promote_rule(::Type{<:Expression{R}}, ::Type{<:Real}) = Expression{R}

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
