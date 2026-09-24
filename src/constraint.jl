export Constraint, PositiveSemidefinite, LessThanEqualZero, EqualConstraint, ConstraintOp

abstract type ConstraintOp end;

struct EqualConstraint <: ConstraintOp end
struct LessThanEqualZero <: ConstraintOp end
struct PositiveSemidefinite <: ConstraintOp end

# TODO: should op be in the parameterization?
struct Constraint <: Expression
    id::ExpressionID
    expression::ExpressionID
    op::ConstraintOp
end

(Base.:(<=)(l::Variable{S}, r::Variable{S})::Constraint) where {S <: Space} = register!(Constraint(allocate_id!(), (l - r).id, LessThanEqualZero()))
(Base.:(>=)(l::Variable{S}, r::Variable{S})::Constraint) where {S <: Space} = register!(Constraint(allocate_id!(), (r - l).id, LessThanEqualZero()))
(Base.:(==)(l::Variable{S}, r::Variable{S})::Constraint) where {S <: Space} = register!(Constraint(allocate_id!(), (l - r).id, EqualConstraint()))