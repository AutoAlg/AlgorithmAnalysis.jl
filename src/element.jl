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
    Element{T}

Element of the space `T`.
"""
mutable struct Element{T} <: Expression{T}
    label::String
    value::Any
    constraints::Constraints
    operators::Operators
    properties::Properties
    relation::Relation
    next::Union{Expression{T}, Missing}

    function Element{T}(value = missing) where {T<:Space}
        new{T}(
            "",
            value,
            Constraints(),
            Operators(),
            Properties(),
            emptyrelation(T),
            missing
        )
    end

    Element(value::T) where T =
        new{T}(
            "",
            value,
            Constraints(),
            Operators(),
            Properties(),
            emptyrelation(T),
            missing
        )
end

const Elements = Set{Element}


convert(::Type{Element{CartesianPower{T}}}, x::Tuple{Vararg{<:Element{<:T}}}) where T = Element{CartesianPower{T}}(x)


# convert a tuple of elements to a single element of the Cartesian product space
function convert(::Type{<:CartesianProduct}, x::Tuple{Vararg{Element}}) 
    Element{CartesianProduct{Tuple{space.(x)...}}}(x)
end

# function convert(::Type{CartesianPower{T}}, x::Tuple{Vararg{Element{T}}}) where T 
#     Element{CartesianPower{T}}(x)
# end


############################################################################################
# Constructors

(::Type{T})() where {T<:Space} = Element{T}()
(::Type{T})(value) where {T<:Space} = Element{T}(value)

Expression{T}() where {T} = Element{T}()

zero(::Type{T}) where {T<:Space} = Element{T}(𝟎)
one(::Type{T}) where {T<:Space} = Element{T}(𝟏)

############################################################################################
# Zero and one

# zero(::Union{T, Type{T}}) where {T<:VectorSpace} = T(𝟎)
# one(::Union{T, Type{T}}) where {T<:Field} = T(𝟏)
# convert(::Type{T}, ::Zero) where {T<:VectorSpace} = T(𝟎)
# convert(::Type{T}, ::One) where {T<:Field} = T(𝟏)


############################################################################################
# Methods

value(a::Element) = a.value
elements(a::Element) = Elements([a])
constraints(a::Element) = a.constraints
operators(a::Element) = a.operators
properties(a::Element) = a.properties
next(a::Element) = a.next

hasconstraints(a::Element) = !isempty(constraints(a))
hasoperators(a::Element) = !isempty(operators(a))
hasnext(a::Element) = !ismissing(next(a))
hasproperties(a::Element) = !isempty(properties(a))
hasvalue(a::Element) = !ismissing(value(a))

function isclean(a::Element)
    !hasconstraints(a) &&
    !hasproperties(a) &&
    isempty(relation(a)) &&
    !hasnext(a)
end

constraint!(e::Expression, c::Constraint) =
    map( v -> constraint!(v,c), collect(elements(e)) )
constraint!(a::Element, c::Constraint) = push!(constraints(a), c)

operator!(::Expression, ::Expression{<:Operator}) = nothing
operator!(a::Element, o::Element{<:Operator}) = push!(operators(a), o)

next!(x::Element{T}, y::Expression{T}) where {T<:Space} = (x.next = y; nothing)

field(::Type{<:VectorSpace{F}}) where {F<:Field} = F
field(::Type{F}) where {F<:Field} = F
# field(::Type{LinearFunctional{T}}) where {T<:VectorSpace} = field(T)

# ring(::Type{<:Module{R}}) where {R<:Ring} = R
ring(::Type{R}) where {R<:Ring} = R
ring(::Type{<:VectorSpace{R}}) where {R<:Ring} = R

iszero(a::Element) = iszero(value(a))

isone(a::Element) = isone(value(a))

zero(::Expression{T}) where T = Zero{T}()

next(a::AbstractArray{<:Expression}) = [ next(x) for x ∈ a ]

update!(p::Pair{T, T}) where T = next!( first(p), last(p) )

inv(f::Element, y::Element) = inv(relation(f))(y)

############################################################################################
# Evaluate

evaluate(a::Element) = value(e)
evaluate(a::AbstractArray{<:Expression}) = [ evaluate(e) for e ∈ a ]


############################################################################################
# Properties

struct Associative <: Property{Element{<:Space}} end
struct Commutative <: Property{Element{<:Space}} end

∈(x::T, property::Property) where {T<:Element} = push!(properties(x), property)
∈(x::T, property::Type{<:Property}) where {T<:Element} = push!(properties(x), property())
∈(x::T, properties::Properties) where {T<:Element} = map(p -> x ∈ p, properties)


############################################################################################
# Methods

"""
    relation(o)

The relation associated with an oracle (or its wrapper).
"""
relation(a::Element) = a.relation

"""
    samples(o)

Get the samples associated with an oracle (or its wrapper).

The set of samples is a `Relation`. Iterating an oracle iterates over its samples.
"""
samples(a::Element) = samples(relation(a))


############################################################################################
# Inputs / outputs

inputs(a::Element) = Set(first(p) for p ∈ samples(a))
outputs(a::Element) = Set(last(p) for p ∈ samples(a))

inputs(exps::Expressions) = mapreduce(inputs, ∪, exps)
outputs(exps::Expressions) = mapreduce(outputs, ∪, exps)

inputs_outputs(a::Element) = zip(samples(a))

inputs_and_outputs(x::Element) = inputs(x) ∪ outputs(x)

flatten(x::Set{<:Element{<:CartesianProduct}}) = mapreduce(Set ∘ value, ∪, x)


############################################################################################
# Neighbors

neighbors(::Object) = Objects()

neighbors(objs::Objects) = mapreduce(neighbors, ∪, objs)
neighbors(vec::Vector{Object}) = mapreduce(neighbors, ∪, vec)

function neighbors(x::Element)
    Objects( constraints(x) ∪
    operators(x) ∪
    inputs_and_outputs(x) ∪
    ( hasnext(x) ? Objects([next(x)]) : Objects() ) ∪
    operators(space(x)) ∪
    ( space(x) <: CartesianProduct ? Objects(value(x)) : Objects() ) )
end

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

function simplify!(x::Element)
    simplify_associative!(x)
end

# flatten f(x,f(y,z)) → f(x,y,z) for operators f that are associative
function simplify_associative!(x::Element)
    T = space(x)
    f = instance(T).addition
    if isclean(x) && x ∈ outputs(f)
        f( Element{CartesianPower{T}}( (value(inv(f, x1))..., x2) ) )
    else
        x
    end
end


function linearform(p::Pair)

end