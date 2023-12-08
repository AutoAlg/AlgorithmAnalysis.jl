export Oracle, Oracles, domain, codomain, FunctionClass, ConvexFunction, SmoothStronglyConvexFunction, FirstOrder, ConvexOracle, MonotoneOperator, SmoothStronglyConvexOracle, sample_input, sample_output, stationary_point, samples, interpolation_conditions, zero

"A oracle consists of a field `samples` of type `r<:Relation` and a field `interpolation_class` of type `R<:RelationClass`, both of which must have the same domain and codomain. The oracle samples points in the domain and returns information in the codomain."
mutable struct Oracle{r,R}
  samples::r
  interpolation_class::R
  singlevalued::Bool

  "Construct an oracle from its input and output spaces."
  Oracle{r,R}(singlevalued=true) where {r<:AbstractRelation,R<:AbstractRelationClass} = new(r(),R(),singlevalued)
end

const Oracles = Vector{Oracle}

samples(o::Oracle) = o.samples
interpolation_class(o::Oracle) = o.interpolation_class
singlevalued(o::Oracle) = o.singlevalued

# zero(::Type{X}) where {X} = zero(X)
zero(::Type{Tuple{X,Y}}) where {X, Y} = (zero(X),zero(Y))

"Custom display of an oracle."
function Base.show(io::IO, o::Oracle)
  println(io, "\nOracle on $(domain(o)) x $(codomain(o))")
  for (x,y) ∈ o.samples
    print(io, "\n($x, $y)")
  end
  println()
  @show o.interpolation_class
  println()
  @show o.singlevalued
end

###############################################################################
# Derived methods.

"Domain of an oracle."
domain(o::Oracle) = domain(samples(o))

"Codomain of an oracle."
codomain(o::Oracle) = codomain(samples(o))

"Interpolation conditions for an oracle's interpolation class and samples."
interpolation_conditions(o::Oracle) = samples(o) ∈ interpolation_class(o)

"Zeros of an oracle."
zeros(o::Oracle) = zeros(samples(o))

"Add an oracle to all variables in an expression."
function add_oracle!(x::Expression, o::Oracle)
  vars = variables(x)
  for v ∈ collect(vars)
    push!(v.oracles, o)
  end
  nothing
end

"Add an oracle to all variables in a tuple of expressions."
function add_oracle!(X::NTuple{N,Expression}, o::Oracle) where {N}
  for x ∈ X
    add_oracle!(x, o)
  end
end

"Stationary point of an oracle."
function stationary_point(o::Oracle)
  x = domain(o)()
  y = zero(codomain(o))
  push!(samples(o), x, y)
  x, y
end

"Sample an oracle at a point in its domain."
function sample_input(o::Oracle,x)
  if !isa(x,domain(o))
    error("The point $x must be in the domain $(domain(o)) of the oracle $o.")
  end
  if singlevalued(o) && x ∈ preimage(samples(o))
    y = samples(o)(x)[1]
  else
    y = codomain(samples(o))()
    push!(samples(o), x, y)
  end
  add_oracle!(x, o)
  add_oracle!(y, o)
  y
end
(o::Oracle)(x) = sample_input(o,x)

"Sample an oracle at a point in its codomain."
function sample_output(o::Oracle,y)
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
