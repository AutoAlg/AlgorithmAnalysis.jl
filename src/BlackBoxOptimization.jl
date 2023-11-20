# cd("C:\\Users\\vanscob\\.julia\\dev\\BlackBoxOptimization\\")
# ] activate .
# using Revise
# using BlackBoxOptimization

# ] test BlackBoxOptimization

module BlackBoxOptimization

function greet()
  return "BlackBoxOptimization!"
end

"A node in the computational graph (either a variable or an operator)."
abstract type Node end

"Construct a new variable."
function variable() end

"Add nodes."
Base.:+(n1::Node, n2::Node)::Node = Node(merge(children(n1),children(n2)))  # sum(n1,n2)

"Subtract nodes."
Base.:-(n1::Node, n2::Node)::Node = n1 + (-n2)

"Multiply node by scalar."
Base.:*(a::Number, n::Node)::Node = Node(Dict(keys(children(n)) .=> map(x->a*x, values(children(n)))))  # scale(a,n)

"Negate node."
Base.:-(n::Node)::Node = -1*n



# include("Node.jl")
# include("Point.jl")
# include("Expression.jl")


# include("Constraint.jl")
# include("DynamicalSystem.jl")
# include("Functional.jl")
# include("FunctionClass.jl")
# include("Oracle.jl")


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
