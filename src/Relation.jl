export Relation, length, domain, codomain, preimage, image, push!, inv, ∘, +, ∈, zeros

import Base.push!, Base.length, Base.inv, Base.zeros

###############################################################################
"An abstract relation is a subset of the Cartesian product of the input space `X` and output space `Y`."
abstract type AbstractRelation{X, Y} end

# struct Zero{T} end


###############################################################################
# Each `AbstractRelation` must specialize the following methods.

"Evaluate a relation at a subset of its input space."
function (r::AbstractRelation{X, Y})(x::Set{X}) where {X, Y} end

"Invert a relation."
function inv(r::AbstractRelation) end

"Relation composition. Unicode ∘ can be typed with \\circ[Tab]."
function Base.:∘(r1::AbstractRelation{Y, Z}, r2::AbstractRelation{X, Y}) where {X, Y, Z} end

"Relation addition."
function Base.:+(r1::AbstractRelation{X, Y}, r2::AbstractRelation{X, Y}) where {X, Y} end

###############################################################################
# Derived methods.

"Domain of a relation."
domain(r::R) where {X, Y, R<:AbstractRelation{X, Y}} = X

"Codomain of a relation."
codomain(r::R) where {X, Y, R<:AbstractRelation{X, Y}} = Y


###############################################################################
"A relation is a (finite) subset of the Cartesian product of the input space `X` and output space `Y`."
mutable struct Relation{X, Y} <: AbstractRelation{X, Y}
  inputs::Vector{Union{X,Nothing}}
  outputs::Vector{Union{Y,Nothing}}
end

Relation{X,Y}() where {X, Y} = Relation{X,Y}(Vector{X}(),Vector{Y}())

function Relation{X,Y}(v::Vector{Tuple{X,Y}}) where {X, Y}
  inputs  = [ x[1] for x in v ]
  outputs = [ x[2] for x in v ]
  Relation{X,Y}(inputs,outputs)
end

Relation{X,Y}(s::Set{Tuple{X,Y}}) where {X, Y} = Relation{X,Y}(collect(s))

Base.:(==)(r1::Relation,r2::Relation) = (r1.inputs == r2.inputs && r1.outputs == r2.outputs)

"Number of elements in a relation."
length(r::Relation) = length(r.inputs)

"Preimage of a relation."
preimage(r::Relation) = Set(r.inputs)

"Image of a relation."
image(r::Relation) = Set(r.outputs)

"Add an input-output pair to a relation."
function push!(r::Relation, x, y)
  if !isa(x,domain(r))
    error("The point $x must be in the domain $(domain(r)) of the relation $r.")
  end
  if !isa(y,codomain(r))
    error("The point $y must be in the codomain $(codomain(r)) of the relation $r.")
  end
  push!(r.inputs,x)
  push!(r.outputs,y)
  ;
end

"Evaluate a relation at a point in its domain. Returns a vector of points in the codomain. To evaluate a relation at a point `y` in its codomain, use `inv(r)(y)`."
(r::Relation{X, Y})(x::X) where {X, Y} = Set(getindex(r.outputs, findall(r.inputs .== x)))

# (r::Relation{X, Y})(x::Zero{X}) where {X, Y} = Set(getindex(r.outputs, findall(r.inputs .== 0)))

"Evaluate a relation at a subset of its domain."
(r::Relation{X, Y})(s::Set{X}) where {X, Y} = union([r(x) for x ∈ s]...)
(r::Relation{X, Y})(v::Vector{X}) where {X, Y} = r(Set(v))

"Invert a relation."
inv(r::Relation) = Relation(r.outputs,r.inputs)

"Composition of two relations. Unicode ∘ can be typed with \\circ[Tab]."
function Base.:∘(r1::Relation{Y, Z}, r2::Relation{X, Y}) where {X, Y, Z}
  r = Relation{X, Z}()
  r2inv = inv(r2)
  for y ∈ collect(preimage(r1) ∩ image(r2))
    for x ∈ collect(r2inv(y)), z ∈ collect(r1(y))
      push!(r, x, z)
    end
  end
  r
end

"Sum of two relations."
function Base.:+(r1::Relation{X, Y}, r2::Relation{X, Y}) where {X, Y}
  r = Relation{X, Y}()
  for x ∈ collect(preimage(r1) ∩ preimage(r2))
    for y1 ∈ collect(r1(x)), y2 ∈ collect(r2(x))
      push!(r, x, y1+y2)
    end
  end
  r
end

"Zeros of a relation."
zeros(r::Relation) = inv(r)(zero(codomain(r)))

"Iterate over input-output pairs of a relation."
Base.iterate(r::Relation) = iterate(r,1)
Base.iterate(r::Relation, state::Int) = (state > length(r) ? nothing : ( (r.inputs[state], r.outputs[state]), state+1))

"Custom display of a relation."
function Base.show(io::IO, r::Relation)
  println(io, "\nRelation on $(domain(r)) x $(codomain(r))")
  for (x,y) ∈ r
    print(io, "\n($x, $y)")
  end
end

###############################################################################
"An abstract class of relations. Each `AbstractRelationClass` must provide a method ∈(r,R) to test whether or not a relation `r` is in a relation class `R`. For a relation class that consists of a finite number of relations, this function could simply check whether or not the relation is an element of the class. For relation classes that consist of an infinite number of relations, these are the interpolation conditions for the relation class."
abstract type AbstractRelationClass end