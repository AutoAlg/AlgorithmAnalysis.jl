

abstract type Constraint end
abstract type Expression end
abstract type Affine <: Expression end
abstract type Variable <: Expression end
abstract type AlgorithmVariable <: Variable end
struct OptimizationVariable <: Variable end
struct Point <: AlgorithmVariable end
struct Scalar <: AlgorithmVariable end

const OptimizationVariables = Vector{OptimizationVariable}
const AlgorithmVariables = Vector{AlgorithmVariable}

*(x1::Number, x2::Scalar)::Scalar
*(x1::Number, x2::Point)::Point
+(x1::Scalar, x2::Scalar)::Scalar
+(x1::Point, x2::Point)::Point
*(x1::Point, x2::Point)::Scalar

lift(X::AlgorithmVariables)::OptimizationVariables

project(𝒳::OptimizationVariables)::AlgorithmVariables

maximize(x::Affine{OptimizationVariables})

islyap(f::Affine{AlgorithmVariables}, V::Function)