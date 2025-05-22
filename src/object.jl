############################################################################################
# OBJECT
############################################################################################

"""
    Atom{T}

Atomic object in space `T`.
"""
struct Atom{T<:Space} <: Object{T}
    label::Label
    value::Any
    properties::Properties
    constraints::Constraints
    next::Union{Object{T}, Missing}

    function Atom{T}(label::Label = missing, flag::Bool = true) where {T<:Space}
        x = new{T}(
            label,
            missing,
            Properties(),
            Constraints(),
            missing
        )
        if flag
            push!(T, x)
        end
        x
    end
end

space(::Object{T}) where T = T
space(::Type{Object{T}}) where T = T

function clear(x::Atom)
    value!(x, missing)
    empty!(constraints(x))
    next!(x, missing)
end


############################################################################################
# Constructors

# (T::Space)() = Atom(T)
# (x::Tuple{Vararg{Object}})() = Atoms(x)
# (::Type{T})(value) where {T<:Space} = Atom{T}(value)


############################################################################################
# Zero and one

# zero(::Type{T}) where {T<:Space} = Atom{T}(𝟎)
# one(::Type{T}) where {T<:Space} = Atom{T}(𝟏)
# zero(::Union{T, Type{T}}) where {T<:VectorSpace} = T(𝟎)
# one(::Union{T, Type{T}}) where {T<:Field} = T(𝟏)
# convert(::Type{T}, ::Zero) where {T<:VectorSpace} = T(𝟎)
# convert(::Type{T}, ::One) where {T<:Field} = T(𝟏)


############################################################################################
# Methods

objects(a::Object) = Objects([a])
value(a::Atom) = a.value
constraints(a::Atom) = a.constraints
next(a::Atom) = a.next
value!(x::Atom, val) = (x.value = val; nothing)
hasconstraints(a::Object) = !isempty(constraints(a))
hasnext(a::Object) = !ismissing(next(a))
hasvalue(a::Object) = !ismissing(value(a))

function isclean(a::Object)
    !hasconstraints(a) &&
    isempty(relation(a)) &&
    !hasnext(a)
end

constraint!(a::Object, c::Constraint) = push!(constraints(a), c)
next!(x::Object{T}, y::Union{Object{T}, Missing}) where {T<:Space} = (x.next = y; nothing)
iszero(a::Object) = iszero(value(a))
isone(a::Object) = isone(value(a))
next(a::AbstractArray{<:Object}) = [ next(x) for x ∈ a ]
update!(p::Pair{T, T}) where T = next!( first(p), last(p) )