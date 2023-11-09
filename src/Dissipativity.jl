# cd("C:\\Users\\vanscob\\.julia\\dev\\Dissipativity\\")
# ] activate .
# using Revise
# using Dissipativity

# ] test Dissipativity

module Dissipativity

function greet()
  return "Dissipativity!"
end

struct DynamicalSystem
  T          # time space
  X          # state value space
  U          # input value space
  Y          # output value space
  stateTransitionFunction::Function  # map from (T,T,X,𝒰) to X
  outputFunction::Function           # map from (X,U) to Y

  function DynamicalSystem(T,X,U,Y,stateTransitionFunction,outputFunction)

    @assert T <: Real

    new(T,X,U,Y,stateTransitionFunction,outputFunction)
  end
end

function iterate(sys::DynamicalSystem, x, u, t)

  @assert typeof(x) <: sys.X
  @assert typeof(u) <: sys.U
  @assert typeof(t) <: sys.T

  sys.stateTransitionFunction(x,u,t)::sys.X
end

output(sys::DynamicalSystem, x, u) = sys.outputFunction(x,u,t)


# Algorithms
gradientDescent(α::Real) = DynamicalSystem( Integer, Real, Real, Real, (t1,t2,x,u) -> x-α*u(t1), (x,u,t) -> x )

export greet

end
