# cd("C:\\Users\\vanscob\\.julia\\dev\\BlackBoxOptimization\\")
# ] activate .
# using Revise
# using BlackBoxOptimization

# ] test BlackBoxOptimization

module BlackBoxOptimization

const m = BlackBoxOptimization

export BlackBoxOptimization, m, Problem, oracle!, point!, constraint!, performance!, solve!, Constraint, Constraints, FirstOrderConvexOracle


# include("Vec.jl")
include("Expression.jl")
include("Constraint.jl")
include("Relation.jl")
include("Oracle.jl")

mutable struct Problem
  oracles::Oracles
  points::Points
  constraints::Constraints
  performance::Scalar

  Problem() = new(Oracles(), Points(), Constraints(), Scalar())
end

"Custom display of a problem."
function Base.show(io::IO, prob::Problem)
  print(io, "\n>> Oracles\n\t")
  [ println(io, x) for x in prob.oracles ]
  print(io, ">> Points\n\t")
  [ println(io, x) for x in prob.points ]
  print(io, ">> Constraints\n\t")
  [ println(io, x) for x in prob.constraints ]
  isempty(prob.constraints) && println()
  print(io, ">> Performance\n\t")
  println(io, prob.performance)
end

oracle!(prob::Problem, oracle::Oracle) = (push!(prob.oracles, oracle); oracle)
point!(prob::Problem, point::Point) = (push!(prob.points, point); point)
point!(prob::Problem) = (point=Point(); point!(prob,point))
constraint!(prob::Problem, constraint::Constraint) = (push!(prob.constraints, constraint); constraint)
performance!(prob::Problem, s::Scalar) = (prob.performance = s)

# function solve!(prob::Problem, verbose::Int, return_full_cvxpy_problem=false, dimension_reduction_heuristic=nothing, eig_regularization=1e-3, tol_dimension_reduction=1e-5; kwargs...) end

# # only used internally to solve
# function expression2convex(prob::Problem, e::Expression, f::Vector{Scalar}, G::Matrix{Scalar}) end
# function send_constraint_to_cvxpy(prob::Problem, e::Expression, f::Vector{Scalar}, G::Matrix{Scalar}) end
# function _eval_points_and_function_values(prob::Problem, F_value, G_value, verbose) end

# function analysis_begin()
#   global __prob = Problem()
# end

# function analysis_end()
#   global __prob

#   @show __prob
# end





# include("Point.jl")
# include("Expression.jl")
# include("Constraint.jl")
# include("DynamicalSystem.jl")
# include("Functional.jl")
# include("FunctionClass.jl")

# mutable struct Algorithm
#   oracles::Array{Oracle}
#   # points::Array{Point}
#   # constraints
#   performanceMeasure
#   # counter (number of algorithms defined)
  
#   # function Algorithm()
#   #   new()
#   # end
# end

# function getState(alg::Algorithm; dim::Integer)
  
# end

# function setState(alg::Algorithm, nextState)
  
# end

# function setPerformanceMeasure(alg::Algorithm, measure)
#   alg.performanceMeasure = measure
# end

# function analyze(alg::Algorithm)
  
# end

end
