export Constraint, Constraints
export expression, set
export Cone, PositiveSemidefiniteCone, PositiveOrthant, Positive, Semidefinite, Equality
export ConeConstraint
export ⪯, ⪰

import Base.∈, Base.isequal, Base.==, Base.:≤, Base.:≥

"Add a constraint to all variables in an expression or an array of expressions."
add_constraint!(x::Expression, c::Constraint) = map(v -> push!(v.constraints, c), collect(variables(x)))
add_constraint!(A::AbstractArray{<:Expression}, c::Constraint) = map(x -> add_constraint!(x,c), A)


###############################################################################
# Constraint

abstract type ConstraintSet end

∈(x::Expression, s::ConstraintSet) = error("∈ not implemented for expression $(typeof(x)) and set $(typeof(s)).")
expression(c::Constraint) = error("expression not implemented for constraint $(typeof(c)).")
set(c::Constraint) = error("set not implemented for constraint $(typeof(c)).")
isequal(lhs::Constraint, rhs::Constraint) = false


###############################################################################
# ConeConstraint

abstract type Cone <: ConstraintSet end
struct PositiveSemidefiniteCone <: Cone end
struct PositiveOrthant <: Cone end
struct ZeroSet <: Cone end

struct ConeConstraint{K<:Cone} <: Constraint
  x::Union{Expression, AbstractArray{<:Expression}}
  
  function ConeConstraint{K}(x) where {K<:Cone}
    this = new(x)
    add_constraint!(x, this)
    return this
  end
end

const Positive = ConeConstraint{PositiveOrthant}
const Semidefinite = ConeConstraint{PositiveSemidefiniteCone}
const Equality = ConeConstraint{ZeroSet}

∈(x::Expression, ::K) where {K<:Cone} = ConeConstraint{K}(x)

expression(c::ConeConstraint) = c.x

set(c::ConeConstraint{K}) where {K<:Cone} = K

isequal(lhs::ConeConstraint{K}, rhs::ConeConstraint{K}) where {K<:Cone} = isequal(lhs.x,rhs.x)

==(lhs::Expression, rhs::Expression) = Equality(lhs-rhs)
==(lhs::Expression, rhs) = Equality(lhs-rhs)
==(lhs, rhs::Expression) = Equality(lhs-rhs)

≤(lhs::Expression, rhs::Expression) = Positive(rhs-lhs)
≤(lhs::Expression, rhs) = Positive(rhs-lhs)
≤(lhs, rhs::Expression) = Positive(rhs-lhs)

≥(lhs::Expression, rhs::Expression) = Positive(lhs-rhs)
≥(lhs::Expression, rhs) = Positive(lhs-rhs)
≥(lhs, rhs::Expression) = Positive(lhs-rhs)

⪯(lhs::Expression, rhs::Expression) = Semidefinite(rhs-lhs)
⪯(lhs::Expression, rhs) = Semidefinite(rhs-lhs)
⪯(lhs, rhs::Expression) = Semidefinite(rhs-lhs)

⪰(lhs::Expression, rhs::Expression) = Semidefinite(lhs-rhs)
⪰(lhs::Expression, rhs) = Semidefinite(lhs-rhs)
⪰(lhs, rhs::Expression) = Semidefinite(lhs-rhs)

function ⪰(lhs::Matrix{<:Expression}, rhs::Int)
  A = copy(lhs)
  for i = 1:size(A, 1)
    A[i,i] -= rhs
  end
  Semidefinite(A)
end

function ==(lhs::AbstractArray{<:Expression}, rhs::AbstractArray{<:Expression})
  if size(lhs) ≠ size(rhs)
    error("Sizes must be the same.")
  end
  cons = Constraints()
  for i ∈ eachindex(lhs)
    if !iszero(lhs[i] - rhs[i])
      push!(cons, lhs[i] == rhs[i])
    end
  end
  cons
end
