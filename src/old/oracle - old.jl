export Oracle, Oracles, domain, codomain
export sample_input, sample_output, samples, zero

import Base.show, Base.∈


###############################################################################
# Oracle

"An oracle consists of a field `samples` of type `r<:Relation` and a field `interpolation_class` of type `R<:RelationClass`, both of which must have the same domain and codomain. The oracle samples points in the domain and returns information in the codomain."
mutable struct Oracle{Relation}
  samples::Relation
  classes::RelationClasses
  singlevalued::Bool

  "Construct an oracle from its input and output spaces."
  function Oracle{Relation}(singlevalued=true) where {Relation<:AbstractRelation}
    new(Relation(),RelationClasses(),singlevalued)
  end
end

const Oracles = Set{Oracle}

samples(o::Oracle) = o.samples
classes(o::Oracle) = o.classes
singlevalued(o::Oracle) = o.singlevalued


###############################################################################
# Derived methods.

∈(o::Oracle, r::RelationClass) = push!(classes(o), r)

"Custom display of an oracle."
function show(io::IO, o::Oracle)
  println(io, "\nOracle on $(domain(o)) x $(codomain(o))")
  println(io, "\nClasses:")
  for c ∈ classes(o)
    print(io, c)
  end
  println(io, "\n\n", singlevalued(o) ? "Single-valued" : "Multi-valued")
  println(io, "\nSamples:")
  for (x,y) ∈ samples(o)
    print(io, "\n($x, $y)")
  end
end

"Domain of an oracle."
domain(o::Oracle) = domain(samples(o))

"Codomain of an oracle."
codomain(o::Oracle) = codomain(samples(o))

"Interpolation conditions for an oracle's interpolation class and samples."
interpolation_conditions(o::Oracle) = mapreduce(c -> interpolation_conditions(o,c), ∪, o.classes; init=Constraints())

"Zeros of an oracle."
zeros(o::Oracle) = zeros(samples(o))

"Add an oracle to all variables in an expression."
add_oracle!(x::Expression, o::Oracle) = map(v -> push!(v.oracles, o), collect(variables(x)))

"Add an oracle to all variables in a tuple of expressions."
add_oracle!(X::NTuple{N,Expression}, o::Oracle) where {N} = map(x -> add_oracle!(x, o), X)

"Sample an oracle at a point in its domain."
function sample_input(o::Oracle, x)
  if !isa(x,domain(o))
    error("The point $x must be in the domain $(domain(o)) of the oracle $o.")
  end
  if singlevalued(o) && x ∈ preimage(samples(o))
    y = samples(o)(x)[1]
  else
    y = codomain(samples(o))()
    push!(samples(o), x => y)
  end
  add_oracle!(x, o)
  add_oracle!(y, o)
  y
end
(o::Oracle)(x) = sample_input(o,x)

"Sample an oracle at a point in its codomain."
function sample_output(o::Oracle, y)
  if !isa(y,codomain(o))
    error("The point $y must be in the codomain $(codomain(o)) of the oracle $o.")
  end
  if y ∈ image(samples(o))
    x = inv(samples(o))(y)[1]
  else
    x = domain(samples(o))()
    push!(samples(o), x, y)
  end
  add_oracle!(x, o)
  add_oracle!(y, o)
  x
end
