export Constraint, Constraints, Cone, PositiveSemidefinite, NonnegativeOrthant, EqualityConstraint

import Base.==, Base.<=, Base.>=, Base.<, Base.>, Base.+

abstract type Constraint end
abstract type Cone end
struct PositiveSemidefiniteCone <: Cone end
struct NonnegativeOrthantCone <: Cone end

struct ConeConstraint{C} <: Constraint
  e::Expression
end
# const SDPConstraint = ConeConstraint{PositiveSemidefiniteCone}

struct EqualityConstraint <: Constraint
  e::Expression
end

# struct LtConstraint <: Constraint
#   lhs::Expression
#   rhs::Expression
# end

# struct GtConstraint <: Constraint
#   lhs::Expression
#   rhs::Expression
# end

# function LtConstraint(lhs::Expression, rhs::Expression)::Constraint end
# function GtConstraint(lhs::Expression, rhs::Expression)::Constraint end

const Constraints = Vector{Constraint}

# overwrites comparison of two expressions
# ==(lhs::ExpressionOrValue, rhs::ExpressionOrValue) = EqualityConstraint(lhs-rhs)

# <=(lhs::T1, rhs::T2) where {T1<:ExpressionOrValue,T2<:ExpressionOrValue} = ConeConstraint{NonnegativeOrthantCone}(rhs-lhs)

# >=(lhs::T1, rhs::T2) where {T1<:ExpressionOrValue,T2<:ExpressionOrValue} = ConeConstraint{NonnegativeOrthantCone}(lhs-rhs)

# "Add constraints."
# +(c1::Array{<:Constraint},c2::Array{<:Constraint}) = append!(append!(Constraint[], c1), c2)
# +(c1::Constraint, c2::Constraint) = [c1] + [c2]
# +(c1::Constraint, c2::Array{<:Constraint}) = [c1] + c2
# +(c1::Array{<:Constraint}, c2::Constraint) = c1 + [c2]
