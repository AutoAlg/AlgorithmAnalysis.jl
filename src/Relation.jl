export RelationClass, RelationClasses, AbstractRelation, Relation
export domain, codomain, preimage, image, evaluate, classes

import Base.push!, Base.length, Base.inv, Base.zeros, Base.∈, Base.+, Base.∘
import Base.show, Base.∩, Base.Generator, Base.iterate, Base.==


###############################################################################
# RelationClass

"An abstract class of relations. Each `RelationClass` must provide a method ∈(r,R) to test whether or not a relation `r` is in a relation class `R`. For a relation class that consists of a finite number of relations, this function could simply check whether or not the relation is an element of the class. For relation classes that consist of an infinite number of relations, these are the interpolation conditions for the relation class."
abstract type RelationClass end

const RelationClasses = Set{RelationClass}

"Intersection of relation classes (which is the union of the sets)."
∩(r1::RelationClass,   r2::RelationClass)   = RelationClasses([r1,r2])
∩(r1::RelationClass,   r2::RelationClasses) = RelationClasses([r1]) ∪ r2
∩(r1::RelationClasses, r2::RelationClass)   = r1 ∪ RelationClasses([r2])
∩(r1::RelationClasses, r2::RelationClasses) = r1 ∪ r2


###############################################################################
# Relation
#  .samples
#  sample()
#  classes()

"A relation is a subset of the Cartesian product of the input space `X` and output space `Y`. The preimage (image) is the subset of the domain (codomain) on which the the relation is defined."
abstract type Relation{X, Y} end

const Relations = Set{Relation}

"Constrain a relation to be in a relation class."
∈(r::Relation, R::RelationClass) = push!(classes(r), R)
∈(r::Relation, R::RelationClasses) = union!(classes(r), R)

"Domain of a relation."
domain(::R) where {X, Y, R<:Relation{X,Y}} = X

"Codomain of a relation."
codomain(::R) where {X, Y, R<:Relation{X,Y}} = Y

"Set of pairs of points at which a relation has been sampled that can be iterated."
samples(r::Relation) = r.samples

"Check equality of two relations."
==(r1::Relation,r2::Relation) = (samples(r1) == samples(r2))

"Number of elements in a relation."
length(r::Relation) = length(samples(r))

"Preimage of a relation."
preimage(r::Relation) = Set([p.first for p ∈ samples(r)])

"Image of a relation."
image(r::Relation) = Set([p.second for p ∈ samples(r)])

"Add an input-output pair to a relation."
push!(r::Relation{X, Y}, p::Pair{X, Y}) where {X, Y} = push!(samples(r), p)

"Composition of two relations. Unicode ∘ can be typed with \\circ[Tab]."
function ∘(r1::Relation{Y, Z}, r2::Relation{X, Y}) where {X, Y, Z}
  r = Relation{X, Z}()
  r2inv = inv(r2)
  for y ∈ collect(preimage(r1) ∩ image(r2))
    for x ∈ collect(r2inv(y)), z ∈ collect(r1(y))
      push!(r, x => z)
    end
  end
  r
end

"Sum of two relations."
function +(r1::Relation{X, Y}, r2::Relation{X, Y}) where {X, Y}
  r = Relation{X, Y}()
  for x ∈ collect(preimage(r1) ∩ preimage(r2))
    for y1 ∈ collect(r1(x)), y2 ∈ collect(r2(x))
      push!(r, x => y1 + y2)
    end
  end
  r
end

"Iterate over the samples of a relation."
iterate(r::Relation) = iterate(r,1)
iterate(r::Relation, state::Int) = (state > length(r) ? nothing : ( collect(samples(r))[state], state+1))

"Add a relation to all variables in an expression or tuple of expressions."
add_relation!(x::Expression, r::Relation) = map(v -> push!(v.relations, r), collect(variables(x)))
add_relation!(X::NTuple{N,Expression}, r::Relation) where {N} = map(x -> add_relation!(x, r), X)

"Evaluate a relation at a point (or set of points) in its domain. Returns a set of points in the codomain. To evaluate a relation `r` at a point `y` in its codomain, use `inv(r)(y)`."
evaluate(r::Relation{X, Y}, s::Set{X}) where {X, Y} = union([r(x) for x ∈ s]...)
evaluate(r::Relation{X, Y}, v::Vector{X}) where {X, Y} = r(Set(v))

"Sample a relation at a point in its domain."
(r::Relation)(x) = sample(r,x)


###############################################################################
# Multi-valued relation

"A multi-valued relation is a relation in which there is a subset of the image associated with each element in the preimage."
mutable struct MultiValued{X, Y} <: Relation{X, Y}
  samples::Set{Pair{X,Y}}
  classes::RelationClasses

  "Construct an empty relation."
  MultiValued{X,Y}() where {X, Y} = new(Set{Pair{X,Y}}(), RelationClasses())

  "Construct a relation from a set of input-output pairs."
  MultiValued(s::Set{Pair{X,Y}}) where {X, Y} = new{X,Y}(s, RelationClasses())
  MultiValued{X,Y}(s::Set{<:Pair}) where {X, Y} = new(s, RelationClasses())
end

"Construct a relation from a generator of pairs of points."
MultiValued(g::Generator) = MultiValued(Set(p for p ∈ g))

"Custom display of a relation."
function show(io::IO, r::MultiValued)
  println(io, "\nMulti-valued relation on $(domain(r)) x $(codomain(r))")
  map(p -> println(io, p), collect(samples(r)))
end

"Invert a relation. Returns a multi-valued relation (even if the input is single valued)."
inv(r::Relation) = MultiValued(reverse(p) for p ∈ samples(r))

classes(r::MultiValued) = r.classes

evaluate(r::MultiValued{X, Y}, x::X) where {X, Y} = Set([p.second for p ∈ samples(r) if isequal(p.first,x)])

"Sample a relation at a point in its domain."
function sample(r::MultiValued{X, Y}, x::X) where {X, Y}
  y = codomain(r)()
  push!(samples(r), x => y)
  add_relation!(x, r)
  add_relation!(y, r)
  y
end

# "Sample a relation at a point in its codomain."
# function sample_output(r::MultiValued{X, Y}, y::Y) where {X, Y}
#   if y ∈ image(samples(r))
#     x = inv(samples(r))(y)[1]
#   else
#     x = domain(samples(r))()
#     push!(samples(r), x, y)
#   end
#   add_relation!(x, r)
#   add_relation!(y, r)
#   x
# end


###############################################################################
# Single-valued relation

"A single-valued relation (also known as a function) is a relation in which there is a unique element of the image associated with each element of the preimage."
mutable struct SingleValued{X, Y} <: Relation{X, Y}
  samples::Dict{X,Y}
  classes::RelationClasses

  "Construct an empty relation."
  SingleValued{X,Y}() where {X, Y} = new(Dict{X,Y}(), RelationClasses())

  "Construct a relation from a set of input-output pairs."
  SingleValued(d::Dict{X,Y}) where {X, Y} = new{X,Y}(d, RelationClasses())
  SingleValued{X,Y}(d::Dict{X,Y}) where {X, Y} = new(d, RelationClasses())
end

"Construct a relation from a generator of pairs of points."
SingleValued(g::Generator) = SingleValued(Dict(p for p ∈ g))

"Custom display of a relation."
function show(io::IO, r::SingleValued)
  println(io, "\nSingle-valued relation on $(domain(r)) x $(codomain(r))")
  print(io, "\nClasses: ")
  first = true
  for c ∈ collect(classes(r))
    first ? (print(io, c); first = false) : print(io, ", ", c)
  end
  println(io, "\nSamples:")
  map(p -> println(io, p), collect(samples(r)))
end

classes(r::SingleValued) = r.classes

evaluate(r::SingleValued{X, Y}, x::X) where {X, Y} = samples(r)[x]

"Sample a relation at a point in its domain."
function sample(r::SingleValued{X, Y}, x::X) where {X, Y}
  if x ∈ keys(samples(r))
    samples(r)[x]
  else
    y = codomain(r)()
    push!(samples(r), x => y)
    add_relation!(x, r)
    add_relation!(y, r)
    y
  end
end
