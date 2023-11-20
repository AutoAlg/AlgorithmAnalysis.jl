functionals = []

mutable struct Functional
  is_leaf::Bool
  value::Number
  weight::Dict
  reuse_gradient::Bool
  evaluations::Vector
  stationary::Vector
  constraints
  psd
  class_constraints
  class_psd
  counter

  function Functional(is_leaf=true,weight=[],reuse_gradient=false)
    new(is_leaf,NaN,weight,reuse_gradient,[],[],[],[],[],[],0)
  end
end