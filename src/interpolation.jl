import Base.∈

###############################################################################
# Relations

# const Functional = Relation{Point, Scalar}
# const FirstOrder = Relation{Expression{Point}, Tuple{Expression{Scalar}, Expression{Point}}}
# const Operator   = Relation{Expression{Point}, Expression{Point}}
const FirstOrder = Relation{Point, Tuple{Scalar, Point}}
const Operator   = Relation{Point, Point}

###############################################################################
# Relation classes

abstract type FunctionClass <: AbstractRelationClass end
struct ConvexFunction <: FunctionClass end
# struct Monotone <: FunctionClass end
struct SmoothStronglyConvexFunction{μ,L} <: FunctionClass end
struct Linear{μ,L} <: FunctionClass end

###############################################################################
# Oracles

const ConvexOracle = Oracle{FirstOrder, ConvexFunction}
const LinearOracle{μ,L} = Oracle{Operator, Linear{μ,L}}
# const MonotoneOperator = Oracle{Operator, Monotone}
# const SmoothStronglyConvexOracle{T1,T2,μ,L} = Oracle{FirstOrder{T1,T2}, SmoothStronglyConvexFunction{μ,L}}

###############################################################################
# Interpolation conditions

function Base.:∈(r::FirstOrder, ::ConvexFunction)
  c = ConeConstraint[]
  for (x1,(f1,g1)) ∈ r, (x2,(f2,_)) ∈ r
    push!(c, f2 ≥ f1 + g1*(x2-x1))
  end
  c
end

function Base.:∈(r::FirstOrder, ::SmoothStronglyConvexFunction{μ,L}) where {μ,L}
  c = ConeConstraint[]
  for (x1,(f1,g1)) ∈ r, (x2,(f2,g2)) ∈ r
    push!(c, f2-f1-g1*(x2-x1) ≥ 1/(2*(1-μ/L))*(1/L*(g2-g1)^2 + μ*(x2-x1)^2 - 2μ/L*(g2-g1)*(x2-x1)))
  end
  c
end

function Base.:∈(r::Operator, ::Linear{μ,L}) where {μ,L}
  X = reduce(hcat, x.value for x ∈ r.inputs)  # need to define matrix operations on arrays of points
  Y = reduce(hcat, y.value for y ∈ r.outputs)
  [ X'*Y == Y'*X, (Y-μ*X)'*(L*X-Y) ⪰ 0 ]
end
