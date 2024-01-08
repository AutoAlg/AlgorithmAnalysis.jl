export DifferentiableFunction, ConvexFunction, ConvexIndicatorFunction
export interpolation_conditions


###############################################################################
# Functional

"A functional is an oracle whose domain is an inner product space and whose codomain is the underlying field. A functional also has a dual oracle that is either the subdifferential (for a convex function) or the gradient (for a differentiable function)."
abstract type Functional{X,F} <: DualOracle{X,F,X,X} end


###############################################################################
struct DifferentiableFunction{X,F} <: Functional{X,F}
  label::String
  value::SingleValued{X,F}
  gradient::SingleValued{X,X}
  
  function DifferentiableFunction{X}() where {F<:Field, X<:InnerProductSpace{F}}
    label = "Differentiable function"
    value = SingleValued{Expression{X},Expression{F}}("Function")
    gradient = SingleValued{Expression{X},Expression{X}}("Gradient")
    new{Expression{X},Expression{F}}(label, value, gradient)
  end
end

relation(o::DifferentiableFunction) = get_oracle(o).value
relation(o::Dual{<:DifferentiableFunction}) = get_oracle(o).gradient

interpolation_conditions(o::DifferentiableFunction) = Constraints()


###############################################################################
struct ConvexFunction{X,F} <: Functional{X,F}
  label::String
  value::SingleValued{X,F}
  subdifferential::MultiValued{X,X}
  
  function ConvexFunction{X}() where {F<:Field, X<:InnerProductSpace{F}}
    label = "Convex function"
    value = SingleValued{Expression{X},Expression{F}}("Function")
    subdifferential = MultiValued{Expression{X},Expression{X}}("Subdifferential")
    new{Expression{X},Expression{F}}(label, value, subdifferential)
  end
end

relation(o::ConvexFunction) = get_oracle(o).value
relation(o::Dual{<:ConvexFunction}) = get_oracle(o).subdifferential

function interpolation_conditions(o::ConvexFunction)
  Constraints( f2 ≥ f1 + g1*(x2-x1) for (x1,f1,g1) ∈ o, (x2,f2,_) ∈ o )
end


###############################################################################
struct ConvexIndicatorFunction{X} <: Functional{X,F}
  label::String
  subdifferential::MultiValued{X,X}
  
  function ConvexIndicatorFunction{X}() where {X}
    label = "Convex indicator function"
    subdifferential = SingleValued{Expression{X},Expression{X}}("Subdifferential")
    new{Expression{X}}(label, subdifferential)
  end
end

relation(o::ConvexIndicatorFunction) = o.value
relation(o::Dual{<:ConvexIndicatorFunction}) = o.primal.subdifferential
