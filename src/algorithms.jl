export Algorithm
export GradientMethod, MomentumMethod
export update

############################################################################################
# Algorithms

abstract type Algorithm end


struct GradientMethod{α} <: Algorithm end
struct MomentumMethod{α,β,γ} <: Algorithm end

function update(alg::GradientMethod{α}, f::Functional, x::Expression) where {α}
  x - α * f'(x)
end

function update(alg::MomentumMethod{α,β,γ}, f::Functional, x, str) where {α,β,γ}
  g = f'(x[1]+γ*(x[1]-x[2]))
  label!(g, str)
  [ x[1]+β*(x[1]-x[2])-α*g; x[1] ]
end
