export Relation, Relations, RelationClass, RelationClasses
export domain, codomain, inputs, outputs, inputs_outputs

import Base.push!, Base.length, Base.inv, Base.zeros, Base.show, Base.Generator, Base.iterate, Base.pairs
import Base.∈, Base.+, Base.-, Base.*, Base./, Base.∘, Base.∩, Base.==


############################################################################################
# Relation

"A relation is a subset of the product space X × Y."
abstract type Relation{X,Y} end

"A set of relations."
const Relations = Set{Relation}

"Domain of a relation."
domain(::Relation{X,Y}) where {X,Y} = X

"Codomain of a relation."
codomain(::Relation{X,Y}) where {X,Y} = Y

"Set of pairs of points in a relation."
pairs(r::Relation) = r.pairs

"Check equality of two relations."
==(r1::Relation, r2::Relation) = isequal(pairs(r1),pairs(r2))

"Number of elements in a relation."
length(r::Relation) = length(pairs(r))

"Inputs of a relation."
inputs(r::Relation) = Set(first(p) for p ∈ pairs(r))

"Outputs of a relation."
outputs(r::Relation) = Set(last(p) for p ∈ pairs(r))

"Vectors of inputs and outputs of a relation."
inputs_outputs(r::Relation) = (v=collect(pairs(r)); ([first(p) for p ∈ v], [last(p) for p ∈ v]))

"Add an input-output pair to a relation."
push!(r::Relation{X,Y}, p::Pair{X,Y}) where {X,Y} = push!(pairs(r), p)

"Iterate over the pairs of a relation."
iterate(r::Relation) = iterate(r,1)
iterate(r::Relation, state::Int) = (state > length(r) ? nothing : ( collect(pairs(r))[state], state+1 ))

label(r::Relation) = r.label
label!(r::Relation, label::String) = (r.label = label)

"Custom display of a relation."
function show(io::IO, r::Relation{X,Y}) where {X,Y}
  isempty(r.label) ? nothing : print(io, "\n", r.label, ": ")
  println(io, "\nRelation on $X x $Y")
  map(p -> println(io, p), collect(pairs(r)))
end


############################################################################################
# Multi-valued relation

"A relation is a subset of the Cartesian product of its domain `X` and codomain `Y`."
mutable struct MultiValuedRelation{X,Y}
  pairs::Set{Pair{X,Y}}
  label::String

  "Construct an empty multi-valued relation."
  MultiValuedRelation{X,Y}(label::String = "") where {X,Y} = new(Set{Pair{X,Y}}(), label)

  "Construct a multi-valued relation from a set of input-output pairs."
  MultiValuedRelation(s::Set{Pair{X,Y}}) where {X,Y} = new{X,Y}(s, "")
  MultiValuedRelation{X,Y}(s::Set{Pair{<:X,<:Y}}) where {X,Y} = new(s, "")
end

"Construct a multi-valued relation from a generator of pairs of points."
MultiValuedRelation(g::Generator) = MultiValuedRelation(Set(p for p ∈ g))

"Evaluate a multi-valued relation at a point (or set of points) in its domain. Returns a set of points in the codomain. To evaluate a relation `r` at a point `y` in its codomain, use `inv(r)(y)`."
(r::MultiValuedRelation{X,Y})(x::X) where {X,Y} = Set{Y}(last(p) for p ∈ pairs(r) if isequal(first(p),x))
(r::MultiValuedRelation{X,Y})(s::Set{X}) where {X,Y} = union([r(x) for x ∈ s]...)
(r::MultiValuedRelation{X,Y})(v::Vector{X}) where {X,Y} = r(Set(v))


############################################################################################
# Single-valued relation

"A single-valued relation (also known as a function) is a relation in which there is a unique element of the codomain associated with each element of the domain."
mutable struct SingleValuedRelation{X,Y} <: Relation{X,Y}
  pairs::Dict{X,Y}
  label::String

  "Construct an empty relation."
  SingleValuedRelation{X,Y}(label::String = "") where {X,Y} = new(Dict{X,Y}(), label)

  "Construct a relation from a set of input-output pairs."
  SingleValuedRelation(d::Dict{X,Y}) where {X,Y} = new{X,Y}(d, "")
  SingleValuedRelation{X,Y}(d::Dict{X,Y}) where {X,Y} = new(d, "")
end

"Construct a relation from a generator of pairs of points."
SingleValuedRelation(g::Generator) = SingleValuedRelation(Dict(p for p ∈ g))

"Evaluate a single-valued relation at a point in its domain. Returns a point in the codomain or `missing`."
(r::SingleValuedRelation{X,Y})(x::X) where {X,Y} = get(pairs(r), x, missing)


############################################################################################
# Constant relation

"A constant relation is a relation in which there is a unique element of the codomain that is associated with any element of the domain."
mutable struct ConstantRelation{X,Y} <: Relation{X,Y}
  inputs::Set{X}
  output::Y
  label::String

  "Construct an empty relation."
  ConstantRelation{X,Y}(label::String = "") where {X,Y} = new(Dict{X,Y}(), label)

  "Construct a relation from a set of input-output pairs."
  ConstantRelation(x::Set{X}, y::Y) where {X,Y} = new{X,Y}(x, y, "")
  ConstantRelation{X,Y}(x::Set{<:X}, y::Y) where {X,Y} = new(x, y, "")
end

"Evaluate a constant relation at a point in its domain."
(r::ConstantRelation{X,Y})(x::X) where {X,Y} = r.output


############################################################################################
# Sample

"Sample a relation at a point in its domain."
function sample(r::MultiValuedRelation{X,Y}, x::X) where {X,Y}
  y = codomain(r)()
  push!(pairs(r), x => y)
  y
end

"Sample a relation at a point in its domain."
function sample(r::SingleValuedRelation{X,Y}, x::X) where {X, Y}
  if x ∈ keys(pairs(r))
    pairs(r)[x]
  else
    y = codomain(r)()
    push!(pairs(r), x => y)
    y
  end
end

"Sample a constant relation at a point in its domain."
sample(r::ConstantRelation{X,Y}, x::X) where {X,Y} = r.output


############################################################################################
# Operations involving relations

"Invert a relation."
inv(r::Relation) = Relation(reverse(p) for p ∈ pairs(r))

"Composition of two relations. Unicode ∘ can be typed with \\circ[Tab]."
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

"Sum of two relations."
function +(r1::Relation{X,Y}, r2::Relation{X,Y}) where {X,Y}
  r = Relation{X,Y}()
  for x ∈ collect(inputs(r1) ∩ inputs(r2))
    for y1 ∈ collect(r1(x)), y2 ∈ collect(r2(x))
      push!(r, x => y1 + y2)
    end
  end
  r
end

"Scaling of a relation."
*(a::Number, r::Relation) = Relation( first(p) => a*last(p) for p ∈ r )

"Negation of a relation."
-(r::Relation) = (-1)*r

"Sum of a relation and an element of its codomain."
+(r::Relation{X,Y}, y) where {X,Y} = Relation( first(p) => last(p) + y for p ∈ r )
+(y, r::Relation{X,Y}) where {X,Y} = r + y


############################################################################################
# RelationClass

"An abstract class of relations. Each `RelationClass` must provide a method ∈(r,R) to test whether or not a relation `r` is in a relation class `R`. For a relation class that consists of a finite number of relations, this function could simply check whether or not the relation is an element of the class. For relation classes that consist of an infinite number of relations, these are the interpolation conditions for the relation class."
abstract type RelationClass end

"A set of relation classes."
const RelationClasses = Set{RelationClass}

"Intersection of relation classes (which is the union of the sets)."
∩(r1::RelationClass,   r2::RelationClass)   = RelationClasses([r1,r2])
∩(r1::RelationClass,   r2::RelationClasses) = RelationClasses([r1]) ∪ r2
∩(r1::RelationClasses, r2::RelationClass)   = r1 ∪ RelationClasses([r2])
∩(r1::RelationClasses, r2::RelationClasses) = r1 ∪ r2

function show(io::IO, c::RelationClasses)
  first = true
  for c ∈ collect(c)
    first ? (print(io, c); first = false) : print(io, ", ", c)
  end
end

# "Constrain a relation to be in a relation class."
# ∈(r::Relation, R::RelationClass) = push!(classes(r), R)
# ∈(r::Relation, R::RelationClasses) = union!(classes(r), R)

# "Sample a relation at a point in its domain."
# (r::Relation)(x) = sample(r,x)

# "Set of classes that a relation is in."
# classes(r::Relation) = r.classes
