abstract type Oracle end

abstract type FunctionClassOracle <: Oracle end
abstract type ConstraintClassOracle <: Oracle end

abstract type ZerothOrderFunctionClassOracle <: FunctionClassOracle end
abstract type FirstOrderFunctionClassOracle <: FunctionClassOracle end
abstract type SecondOrderFunctionClassOracle <: FunctionClassOracle end

"Sample the oracle at a point."
function sample(oracle::Oracle, point)
  
end

"Determine whether or not the set of inputs and outputs of the oracle are interpolable (check if they satisfy the interpolation conditions)."
function isInterpolable(oracle::Oracle, inputs, outputs)::Bool
  
end

"Set the lifting dimension associated with the oracle."
function setLiftingDimension(oracle::Oracle, ℓ::Integer)
  
end

