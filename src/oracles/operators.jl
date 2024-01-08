export Operator, ContinuousOperator, LinearOperator


###############################################################################
struct MultiValuedOperator{X,Y} <: AbstractOperator{X,Y}
  label::String
  value::Relation{X,Y}
  classes::OperatorClasses
  
  function Operator{X,Y}() where {X,Y}
    label = "Operator"
    value = Relation{Expression{X},Expression{Y}}()
    new{Expression{X},Expression{Y}}(label, value)
  end
end

relation(o::Operator) = get_oracle(o).value


###############################################################################
struct SingleValuedOperator{X,Y} <: AbstractOperator{X,Y}
  label::String
  value::SingleValued{X,Y}
  
  function SingleValuedOperator{X,Y}() where {X,Y}
    label = "Single-valued operator"
    value = SingleValued{Expression{X},Expression{Y}}()
    new{Expression{X},Expression{Y}}(label, value)
  end
end

relation(o::SingleValuedOperator) = get_oracle(o).value


###############################################################################
struct LinearOperator{X,Y} <: DualOracle{X,Y,Y,X}
  label::String
  value::SingleValued{X,Y}
  adjoint::SingleValued{Y,X}
  
  function LinearOperator{X,Y}() where {X,Y}
    label = "Linear operator"
    value = SingleValued{Expression{X},Expression{Y}}("Operator")
    adjoint = SingleValued{Expression{Y},Expression{X}}("Adjoint")
    new{Expression{X},Expression{Y}}("Linear operator", value, adjoint)
  end
end

relation(o::LinearOperator) = get_oracle(o).value
relation(o::Dual{<:LinearOperator}) = get_oracle(o).adjoint


###############################################################################
struct SymmetricLinearOperator{X} <: Oracle{SingleValued{X,X}}
  label::String
  value::SingleValued{X,X}
  
  SymmetricLinearOperator{X}() where {X} = new{Expression{X},Expression{X}}("Symmetric linear operator", SingleValued{Expression{X},Expression{X}}("Operator"))
end

relation(o::SymmetricLinearOperator) = o.value
adjoint(o::SymmetricLinearOperator) = o


###############################################################################
struct SkewSymmetricLinearOperator{X} <: Oracle{SingleValued{X,X}}
  label::String
  value::SingleValued{X,X}
  
  SymmetricLinearOperator{X}() where {X} = new{Expression{X},Expression{X}}("Skew-symmetric linear operator", SingleValued{Expression{X},Expression{X}}("Operator"))
end

relation(o::SkewSymmetricLinearOperator) = o.value
adjoint(o::SkewSymmetricLinearOperator) = -o
