############################################################################################
# Real numbers

structures(::Type{<:Space}) = Atoms()

# """
#     Sampler{X,Y}

# A sampler from `X` to `Y`.
# """
# struct Sampler{X,Y}
#     relation::SingleValuedRelation{Func{X,Y},Relation}
#     labeler::Function
#     singlevalued::Bool

#     function Sampler{X,Y}(singlevalued = true) where {X,Y}
#         relation = SingleValuedRelation{Func{X,Y},SingleValuedRelation}()
#         labeler = () -> ""
#         new{X,Y}(relation, labeler, singlevalued)
#     end
# end


"""
    𝓛{V}

Space of linear functionals on a vector space `V`.
"""
struct 𝓛{V} <: LinearFunctional{V}
    gradient::Object{AbstractFunction{𝓛{V},UnaryOperator{V}}}
    relation::Object{AbstractFunction{𝓛{V},SingleValuedRelation}}
    # relation::SingleValuedRelation{𝓛{V},SingleValuedRelation}

    function Base.reinterpret(::Type{𝓛{V}}) where V
        gradient = AbstractFunction{𝓛{V},UnaryOperator{V}}()
        gradient.labeler = x -> "∇$(label(x))"
        relation = AbstractFunction{𝓛{V},SingleValuedRelation}()
        new{V}(gradient, relation)
    end
end

const _𝓛 = Dict{VectorSpace,𝓛}()
instance(::Type{𝓛{V}}) where {V<:VectorSpace} = get(_𝓛, V, reinterpret(𝓛{V}))


"""
    𝓕{V}

Space of differentiable functionals on a vector space `V`.
"""
struct 𝓕{V} <: Functional{V}
    gradient::Object{AbstractFunction{𝓕{V},UnaryOperator{V}}}

    function Base.reinterpret(::Type{𝓕{V}}) where V
        grad = AbstractFunction{𝓕{V},UnaryOperator{V}}()
        grad.labeler = x -> "∇$(label(x))"
        new{V}(grad)
    end
end

const _𝓕 = Dict{VectorSpace,𝓕}()
instance(::Type{𝓕{V}}) where {V<:VectorSpace} = get(_𝓕, V, reinterpret(𝓕{V}))


"""
    R <: Field

The field of real numbers.
"""
struct R <: Field
    addition::Object{Addition{R}}
    multiplication::Object{Multiplication{R}}

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
structures(::Type{R}) = Atoms([instance(R).addition, instance(R).multiplication])


"""
    Rⁿ <: InnerProductSpace

A real inner product space.
"""
struct Rⁿ <: InnerProductSpace{R}
    addition::Object{Addition{Rⁿ}}
    scaling::Object{Scaling{Rⁿ,R}}
    dual::Object{AbstractFunction{Rⁿ,Rⁿ'}}

    function Base.reinterpret(::Type{Rⁿ})
        f = Addition{Rⁿ}()
        g = Scaling{Rⁿ,R}()
        h = AbstractFunction{Rⁿ,Rⁿ'}()
        f ∈ Associative
        f ∈ Commutative
        h.labeler = x -> "$(label(x))'"
        new(f, g, h)
    end
end

const _Rⁿ = reinterpret(Rⁿ)
instance(::Type{Rⁿ}) = _Rⁿ
structures(::Type{Rⁿ}) = Atoms([
    instance(Rⁿ).addition, instance(Rⁿ).scaling, instance(Rⁿ).dual])

"""
    Rᵐ <: InnerProductSpace

A real inner product space.
"""
struct Rᵐ <: InnerProductSpace{R}
    addition::Object{Addition{Rᵐ}}
    scaling::Object{Scaling{Rᵐ,R}}

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
structures(::Type{Rᵐ}) = Atoms([
    instance(Rᵐ).addition, instance(Rᵐ).scaling, instance(Rᵐ).dual])



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
juliatype(::Type{R × R}) = Tuple{Real, Real}

algorithmtype(::Any) = Union{}
algorithmtype(::Type{Real}) = R
algorithmtype(::Type{Tuple{Real, Real}}) = R × R

convert(::Type{<:Object{R}}, x::Real) = Atom{R}(x)
# # convert(::Type{<:Expression{R}}, ::Zero) = R(0)
# # convert(::Type{<:Expression{R}}, ::One) = R(1)
promote_rule(::Type{<:Object{R}}, ::Type{<:Real}) = Object{R}

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
