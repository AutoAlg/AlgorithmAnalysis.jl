############################################################################################
# OBJECT
############################################################################################

"""
    Atom{T}

Atomic object in space `T`.
"""
mutable struct Atom{T<:Space} <: Object{T}
    label::Label
    value::Any
    constraints::Constraints
    next::Union{Object{T}, Missing}

    function Atom{T}(label::Label = missing, flag::Bool = true) where {T<:Space}
        x = new{T}(
            label,
            missing,
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

# const Atoms = Set{Atom}

function clear(x::Atom)
    value!(x, missing)
    empty!(constraints(x))
    next!(x, missing)
end

# Iteration over atoms
# length(a::Atom) = 1
# isempty(a::Atom) = false
# iterate(a::Atom) = a
# iterate(::Atom, ::Int) = nothing

# length(a::Atoms) = length(value(a))
# isempty(a::Atoms) = iszero(length(a))
# iterate(a::Atoms) = iterate(a,1)
# iterate(a::Atoms, state::Int) = state > length(a) ? nothing : ( value(a)[state], state+1 )



############################################################################################
# Constructors

# (T::Space)() = Atom(T)
# (x::Tuple{Vararg{Object}})() = Atoms(x)
# (::Type{T})(value) where {T<:Space} = Atom{T}(value)

# zero(::Type{T}) where {T<:Space} = Atom{T}(𝟎)
# one(::Type{T}) where {T<:Space} = Atom{T}(𝟏)

############################################################################################
# Zero and one

# zero(::Union{T, Type{T}}) where {T<:VectorSpace} = T(𝟎)
# one(::Union{T, Type{T}}) where {T<:Field} = T(𝟏)
# convert(::Type{T}, ::Zero) where {T<:VectorSpace} = T(𝟎)
# convert(::Type{T}, ::One) where {T<:Field} = T(𝟏)


############################################################################################
# Methods

objects(a::Object) = Objects([a])

# Atom
value(a::Atom) = a.value
constraints(a::Atom) = a.constraints
next(a::Atom) = a.next

value!(x::Atom, val) = (x.value = val; nothing)

# Atoms
# value(a::Atoms) = a.value
# constraints(a::Atoms) = mapreduce(constraints, ∪, value(a); init=Constraints())
# next(a::Atoms) = next(value(a))

# value!(x::Atoms, val) = (x.value = val; nothing)


hasconstraints(a::Object) = !isempty(constraints(a))
hasnext(a::Object) = !ismissing(next(a))
hasvalue(a::Object) = !ismissing(value(a))

function isclean(a::Object)
    !hasconstraints(a) &&
    isempty(relation(a)) &&
    !hasnext(a)
end

constraint!(a::Object, c::Constraint) = push!(constraints(a), c)

# operator!(a::Object, o::Object{<:Operator}) = push!(operators(a), o)

next!(x::Object{T}, y::Union{Object{T}, Missing}) where {T<:Space} = (x.next = y; nothing)

# field(::Type{<:VectorSpace{F}}) where {F<:Field} = F
# field(::Type{F}) where {F<:Field} = F
# field(::Type{LinearFunctional{T}}) where {T<:VectorSpace} = field(T)

iszero(a::Object) = iszero(value(a))

isone(a::Object) = isone(value(a))

# zero(::Object{T}) where T = Zero{T}()

next(a::AbstractArray{<:Object}) = [ next(x) for x ∈ a ]

update!(p::Pair{T, T}) where T = next!( first(p), last(p) )

inv(f::Object, y::Object) = inv(relation(f))(y)

############################################################################################
# Evaluate

evaluate(a::Object) = value(e)
evaluate(a::AbstractArray{<:Object}) = [ evaluate(e) for e ∈ a ]


############################################################################################
# Properties

# struct Associative <: Property end
# struct Commutative <: Property end

# ∈(x::Object, property::Property) = push!(properties(x), property)
# ∈(x::Object, property::Type{<:Property}) = push!(properties(x), property())
# ∈(x::Object, properties::Properties) = map(p -> x ∈ p, properties)


############################################################################################
# Methods

# """
#     relation(o)

# The relation associated with an oracle (or its wrapper).
# """
# relation(a::Object) = a.relation

# """
#     samples(o)

# Get the samples associated with an oracle (or its wrapper).

# The set of samples is a `Relation`. Iterating an oracle iterates over its samples.
# """
# samples(a::Object) = samples(relation(a))


############################################################################################
# Inputs / outputs

# inputs(a::Object) = Objects(first(p) for p ∈ samples(a))
# outputs(a::Object) = Objects(last(p) for p ∈ samples(a))

# inputs(exps::Objects) = mapreduce(inputs, ∪, exps)
# outputs(exps::Objects) = mapreduce(outputs, ∪, exps)

# inputs_outputs(a::Object) = zip(samples(a))

# inputs_and_outputs(x::Object) = inputs(x) ∪ outputs(x)

# flatten(x::Object) = Set([x])
# # flatten(x::Object{<:CartesianProduct}) = Set(value(x))
# flatten(x::Objects) = mapreduce(flatten, ∪, x; init=Objects())