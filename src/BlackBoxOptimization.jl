# cd("C:\\Users\\vanscob\\.julia\\dev\\BlackBoxOptimization\\")
# ] activate .
# using Revise
# using BlackBoxOptimization

# ] test BlackBoxOptimization

module BlackBoxOptimization

function greet()
  return "BlackBoxOptimization!"
end

# "Construct a new variable."
# function variable() end

# include("Vec.jl")
# include("Node.jl")
# include("Point.jl")
# include("Expression.jl")
include("Tensor.jl")
include("Oracle.jl")

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


const m = BlackBoxOptimization

export greet, m

end
