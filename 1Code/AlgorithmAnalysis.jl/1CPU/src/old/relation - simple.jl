###############################################################################
# Relation

abstract type AbstractRelation end

"""
    Relation{X,Y} <: AbstractRelation

A relation is a subset of the Cartesian product of its domain `X` and codomain `Y`.
"""
mutable struct Relation{X,Y} <: AbstractRelation
    samples::Set{Pair{X,Y}}

    # Construct an empty relation
    Relation{X,Y}() where {X,Y} = new(Set{Pair{X,Y}}())

    # Construct a relation from a set of input-output pairs
    Relation(s::Set{Pair{X,Y}}) where {X,Y} = new{X,Y}(s)
    Relation{X,Y}(s::Set{Pair{<:X,<:Y}}) where {X,Y} = new(s)
end

# A set of relations
const Relations = Set{Relation}

# Construct a relation from a generator of pairs of points
Relation(g::Generator) = Relation(Set(p for p ∈ g))

# Construct a relation from a dictionary
Relation(d::Dict) = Relation(first(p) => last(p) for p ∈ d)

Relation(s::Set{Pair{X}}) where {X} = Relation(Set{Pair{X,X}}(s))

# Domain of a relation
domain(::Relation{X,Y}) where {X,Y} = X

# Codomain of a relation
codomain(::Relation{X,Y}) where {X,Y} = Y

# Set of pairs of points at which a relation has been sampled
samples(r::Relation) = r.samples

# Check equality of two relations
==(r1::Relation, r2::Relation) = (samples(r1) == samples(r2))

# Number of elements in a relation
length(r::Relation) = length(samples(r))

# Inputs of a relation
inputs(r::Relation) = Set(p.first for p ∈ samples(r))

# Outputs of a relation
outputs(r::Relation) = Set(p.second for p ∈ samples(r))

# Tuple of inputs and outputs of a relation
inputs_outputs(r::Relation) = (pairs=collect(samples(r)); ([first(p) for p ∈ pairs], [last(p) for p ∈ pairs]))

# Add an input-output pair to a relation
push!(r::Relation{X,Y}, p::Pair{X,Y}) where {X,Y} = push!(samples(r), p)

# Composition of two relations. Unicode ∘ can be typed with \\circ[Tab]
function ∘(r1::Relation{Y,Z}, r2::Relation{X,Y}) where {X,Y,Z}
    r = Relation{X,Z}()
    r2inv = inv(r2)
    for y ∈ collect(inputs(r1) ∩ outputs(r2))
        for x ∈ collect(r2inv(y)), z ∈ collect(r1(y))
        push!(r, x => z)
        end
    end
    r
end

# Sum of two relations
function +(r1::Relation{X,Y}, r2::Relation{X,Y}) where {X,Y}
    r = Relation{X,Y}()
    for x ∈ collect(inputs(r1) ∩ inputs(r2))
        for y1 ∈ collect(r1(x)), y2 ∈ collect(r2(x))
        push!(r, x => y1 + y2)
        end
    end
    r
end

# Scaling of a relation
*(a::Number, r::Relation) = Relation( p.first => a*p.second for p ∈ r )

# Negation of a relation
-(r::Relation) = (-1)*r

# Sum of a relation and an element of its codomain
+(r::Relation{X,Y}, y) where {X,Y} = Relation( p.first => p.second + y for p ∈ r )
+(y, r::Relation{X,Y}) where {X,Y} = r + y

# Iterate over the samples of a relation
iterate(r::Relation) = iterate(r,1)
iterate(r::Relation, state::Int) = (state > length(r) ? nothing : ( collect(samples(r))[state], state+1 ))

# Evaluate a relation at a point (or set of points) in its domain. Returns a set of points in the codomain. To evaluate a relation `r` at a point `y` in its codomain, use `inv(r)(y)`.
(r::Relation{X,Y})(x::X) where {X,Y} = Set{Y}(p.second for p ∈ samples(r) if isequal(p.first,x))
(r::Relation{X,Y})(s::Set{X}) where {X,Y} = union([r(x) for x ∈ s]...)
(r::Relation{X,Y})(v::Vector{X}) where {X,Y} = r(Set(v))

label(r::Relation) = r.label
label!(r::Relation, label::String) = (r.label = label)

# Invert a relation
inv(r::Relation) = Relation(reverse(p) for p ∈ samples(r))


###############################################################################
# RelationClass

# "An abstract class of relations. Each `RelationClass` must provide a method ∈(r,R) to test whether or not a relation `r` is in a relation class `R`. For a relation class that consists of a finite number of relations, this function could simply check whether or not the relation is an element of the class. For relation classes that consist of an infinite number of relations, these are the interpolation conditions for the relation class."
# abstract type RelationClass end

# "A set of relation classes."
# const RelationClasses = Set{RelationClass}

# "Intersection of relation classes (which is the union of the sets)."
# ∩(r1::RelationClass,   r2::RelationClass)   = RelationClasses([r1,r2])
# ∩(r1::RelationClass,   r2::RelationClasses) = RelationClasses([r1]) ∪ r2
# ∩(r1::RelationClasses, r2::RelationClass)   = r1 ∪ RelationClasses([r2])
# ∩(r1::RelationClasses, r2::RelationClasses) = r1 ∪ r2

# function show(io::IO, c::RelationClasses)
#   first = true
#   for c ∈ collect(c)
#     first ? (print(io, c); first = false) : print(io, ", ", c)
#   end
# end



# "Constrain a relation to be in a relation class."
# ∈(r::Relation, R::RelationClass) = push!(classes(r), R)
# ∈(r::Relation, R::RelationClasses) = union!(classes(r), R)

# "Sample a relation at a point in its domain."
# (r::Relation)(x) = sample(r,x)

# "Set of classes that a relation is in."
# classes(r::Relation) = r.classes




# "A single-valued relation (also known as a function) is a relation in which there is a unique element of the outputs associated with each element of the inputs."
# mutable struct SingleValued{X,Y} <: Relation{X,Y}
#   samples::Dict{X,Y}
#   classes::RelationClasses
#   label::String

#   "Construct an empty relation."
#   SingleValued{X,Y}(label::String = "") where {X,Y} = new(Dict{X,Y}(), RelationClasses(), label)

#   "Construct a relation from a set of input-output pairs."
#   SingleValued(d::Dict{X,Y}) where {X,Y} = new{X,Y}(d, RelationClasses(), "")
#   SingleValued{X,Y}(d::Dict{X,Y}) where {X,Y} = new(d, RelationClasses(), "")
# end

# "Construct a relation from a generator of pairs of points."
# SingleValued(g::Generator) = SingleValued(Dict(p for p ∈ g))

# evaluate(r::SingleValued{X,Y}, x::X) where {X, Y} = get(samples(r), x, missing)

###############################################################################
# Sample

# "Sample a relation at a point in its domain."
# function sample(r::MultiValued{X,Y}, x::X) where {X,Y}
#   y = codomain(r)()
#   push!(samples(r), x => y)
#   y
# end

# "Sample a relation at a point in its domain."
# function sample(r::SingleValued{X,Y}, x::X) where {X, Y}
#   if x ∈ keys(samples(r))
#     samples(r)[x]
#   else
#     y = codomain(r)()
#     push!(samples(r), x => y)
#     y
#   end
# end
