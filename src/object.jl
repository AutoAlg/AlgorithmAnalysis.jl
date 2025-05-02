############################################################################################
# ELEMENT
############################################################################################

function emptyrelation(T)
    if isfunction(T)
        if issinglevalued(T)
            r = SingleValuedRelation{domain(T), codomain(T)}()
        else
            r = MultiValuedRelation{domain(T), codomain(T)}()
        end
    else
        r = EmptyRelation()
    end
    r
end

"""
    Atom{T}

Atomic object in space `T`.
"""
mutable struct Atom{T} <: Object{T}
    label::String
    value::Any
    constraints::Constraints
    operators::Operators
    properties::Properties
    # relation::Relation
    next::Union{Object{T}, Missing}
    # labeler::Function

    Atom{T}(value = missing) where {T<:Space} = new{T}(
        "",
        value,
        Constraints(),
        Operators(),
        Properties(),
        # emptyrelation(T),
        missing,
        # (::Object) -> ""
    )

    Atom(value::T) where {T<:Space} = new{T}(
        "",
        value,
        Constraints(),
        Operators(),
        Properties(),
        # emptyrelation(T),
        missing,
        # (::Object) -> ""
    )
end

const Atoms = Set{Atom}

function clear(x::Atom)
    value!(x, missing)
    empty!(constraints(x))
    empty!(operators(x))
    empty!(properties(x))
    empty!(relation(x))
end


convert(::Type{Object{CartesianPower{T}}}, x::Tuple{Vararg{Object{T}}}) where T = Atom{CartesianPower{T}}(x)


# convert a tuple of objects to a single object of the Cartesian product space
function convert(::Type{<:CartesianProduct}, x::Tuple{Vararg{<:Object}}) 
    Atom{CartesianProduct{Tuple{space.(x)...}}}(x)
end

# function convert(::Type{CartesianPower{T}}, x::Tuple{Vararg{Object{T}}}) where T 
#     Object{CartesianPower{T}}(x)
# end


############################################################################################
# Constructors

(::Type{T})() where {T<:Space} = Atom{T}()
(::Type{T})(value) where {T<:Space} = Atom{T}(value)

zero(::Type{T}) where {T<:Space} = Atom{T}(𝟎)
one(::Type{T}) where {T<:Space} = Atom{T}(𝟏)

############################################################################################
# Zero and one

# zero(::Union{T, Type{T}}) where {T<:VectorSpace} = T(𝟎)
# one(::Union{T, Type{T}}) where {T<:Field} = T(𝟏)
# convert(::Type{T}, ::Zero) where {T<:VectorSpace} = T(𝟎)
# convert(::Type{T}, ::One) where {T<:Field} = T(𝟏)


############################################################################################
# Methods

value(a::Atom) = a.value
objects(a::Object) = Objects([a])
constraints(a::Atom) = a.constraints
operators(a::Atom) = a.operators
properties(a::Atom) = a.properties
next(a::Atom) = a.next

hasconstraints(a::Object) = !isempty(constraints(a))
hasoperators(a::Object) = !isempty(operators(a))
hasnext(a::Object) = !ismissing(next(a))
hasproperties(a::Object) = !isempty(properties(a))
hasvalue(a::Object) = !ismissing(value(a))

function isclean(a::Object)
    !hasconstraints(a) &&
    !hasproperties(a) &&
    isempty(relation(a)) &&
    !hasnext(a)
end

value!(x::Atom, val) = (x.value = val; nothing)

constraint!(a::Object, c::Constraint) = push!(constraints(a), c)

operator!(a::Object, o::Object{<:Operator}) = push!(operators(a), o)

next!(x::Object{T}, y::Object{T}) where {T<:Space} = (x.next = y; nothing)

field(::Type{<:VectorSpace{F}}) where {F<:Field} = F
field(::Type{F}) where {F<:Field} = F
# field(::Type{LinearFunctional{T}}) where {T<:VectorSpace} = field(T)

iszero(a::Object) = iszero(value(a))

isone(a::Object) = isone(value(a))

zero(::Object{T}) where T = Zero{T}()

next(a::AbstractArray{<:Object}) = [ next(x) for x ∈ a ]

update!(p::Pair{T, T}) where T = next!( first(p), last(p) )

inv(f::Object, y::Object) = inv(relation(f))(y)

############################################################################################
# Evaluate

evaluate(a::Object) = value(e)
evaluate(a::AbstractArray{<:Object}) = [ evaluate(e) for e ∈ a ]


############################################################################################
# Properties

struct Associative <: Property end
struct Commutative <: Property end

∈(x::Object, property::Property) = push!(properties(x), property)
∈(x::Object, property::Type{<:Property}) = push!(properties(x), property())
∈(x::Object, properties::Properties) = map(p -> x ∈ p, properties)


############################################################################################
# Methods

"""
    relation(o)

The relation associated with an oracle (or its wrapper).
"""
relation(a::Object) = a.relation

"""
    samples(o)

Get the samples associated with an oracle (or its wrapper).

The set of samples is a `Relation`. Iterating an oracle iterates over its samples.
"""
samples(a::Object) = samples(relation(a))


############################################################################################
# Inputs / outputs

inputs(a::Object) = Objects(first(p) for p ∈ samples(a))
outputs(a::Object) = Objects(last(p) for p ∈ samples(a))

inputs(exps::Objects) = mapreduce(inputs, ∪, exps)
outputs(exps::Objects) = mapreduce(outputs, ∪, exps)

inputs_outputs(a::Object) = zip(samples(a))

inputs_and_outputs(x::Object) = inputs(x) ∪ outputs(x)

flatten(x::Object) = Set([x])
flatten(x::Object{<:CartesianProduct}) = Set(value(x))
flatten(x::Objects) = mapreduce(flatten, ∪, x; init=Objects())


############################################################################################
# Neighbors

neighbors(x::Object) = Objects(
    constraints(x) ∪
    operators(x) ∪
    flatten(inputs_and_outputs(x)) ∪
    ( hasnext(x) ? Objects([next(x)]) : Objects() ) ∪
    operators(space(x))
)

neighbors(objs::Union{Objects,Array{<:Object}}) = mapreduce(neighbors, ∪, objs)

# Get all objects in the graph using graph search
function nodes(x::Object)
    visited = Objects()
    queue = Objects([x])
    
    while !isempty(queue)
        node = pop!(queue)
        if node ∉ visited
            push!(visited, node)
            union!(queue, neighbors(node))
        end
    end
    visited
end

############################################################################################
# Simplify

function simplify!(x::Object)
    simplify_associative!(x)
end

# flatten f(x,f(y,z)) → f(x,y,z) for operators f that are associative
function simplify_associative!(x::Object)
    T = space(x)
    f = instance(T).addition
    if isclean(x) && x ∈ outputs(f)
        f( Object{CartesianPower{T}}( (value(inv(f, x1))..., x2) ) )
    else
        x
    end
end


function linearform(p::Pair)

end