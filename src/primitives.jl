
############################################################################################
# Stationary points

function first_order_stationary_point(o::AbstractLocallyLipschitzFunctional{X}) where {F<:Field, X<:VectorSpace{F}}
  x, f, g = X(), F(), X(Zero())
  push!(samples(o), x => f)
  push!(samples(o'), x => g)
  x, f, g
end

# function first_order_stationary_point(o::DifferentiableFunction{X,F}) where {X,F}
#   x, f, g = X(), F(), zero(X)
#   push!(o, x => f, x => g)
#   x, f, g
# end

# function prox(o::ConvexFunction{X,F}, z::X, γ::Real) where {X,F}
#   f, g = F(), X()
#   x = z - γ*g
#   push!(o, x => f, x => g)
#   x, f, g
# end

# function inexact_gradient(o::ConvexFunction{X,Y}, x0::X, γ::Real, ε::Real) where {X,Y} end

# function inexact_prox(o::ConvexFunction{X,Y}, x0::X, γ::Real) where {X,Y} end

# function linesearch(o::ConvexFunction{X,Y}, x0::X, dirs) where {X,Y} end

# function epsilon_subgradient(o::ConvexFunction{X,Y}, x0::X, γ::Real) where {X,Y} end

# function bregman_gradient(mirror_map::ConvexFunction{X,F}, gx0, sx0, γ) where {X,F}
#   x, hx = X(), F()

#   sx = sx0 - γ*gx0

#   push!(mirror_map, x => hx, x => sx)

#   x, sx, hx
# end

# function bregman_prox(mirror_map::ConvexFunction{X,F}, min_function::ConvexFunction{X,F}, sx0, γ) where {X,F}
#   x, fx, gx = X(), F(), X()

#   sx = sx0 - γ*gx
#   hx = F()

#   push!(min_function, x => fx, x => gx)
#   push!(mirror_map, x => hx, x => sx)

#   x, sx, hx, gx, fx
# end


# function linear_optimization(dir, o::ConvexFunction{X,F}) where {X,F}
#   x, g, f = X(), -dir, F()
#   push!(o, x => f, x => g)
#   x, f, g
# end
