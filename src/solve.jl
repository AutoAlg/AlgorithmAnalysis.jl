
# export decompose, variables, constraints, lift, lifted_expression, lifted_constraint, lifted_constraints, variables_constraints_constants, basis_vector

export original_variables, lift

function maximize(P::Scalar)
  println("Maximizing the performance measure $P.")
  
end

"Variables in an expression."
function original_variables(x::Expression)
  
  vars = keys(children(x))

  # split the variables into scalars and inner products of points
  F = filter(x -> isa(x, Scalar), vars)
  G = filter(x -> isa(x, Tuple{Point,Point}), vars)

  # find all points that appear in the inner products
  X = Set([(G...)...])
  
  # remove anything scalars that have a value
  for f ∈ collect(F)
    if hasvalue(f)
      delete!(F, f)
    end
  end
  
  X, F
end


function lift(x::Expression, X, 𝒳)
  points, scalars = X
  n = length(points)
  m = length(scalars)
  A = zeros(n,n)
  b = zeros(m)
  c = 0.0
  for (i,f) ∈ enumerate(scalars)
    if f ∈ keys(x.children)
      b[i] = x.children[f]
    end
  end
  for (i,x1) ∈ enumerate(points)
    for (j,x2) ∈ enumerate(points)
      if (x1,x2) ∈ keys(x.children)
        A[i,j] = x.children[(x1,x2)]
      end
    end
  end
  # if 1 ∈ keys(x.children)
  #   c = x.children[1]
  # end
  
  G, F = 𝒳
  
  Convex.tr(G * A) + (m>0 ? Convex.inner_product(F, b) : 0)
end


"Each type of constraint must specialize this method."
function lift(c::Constraint, X, 𝒳)
  error("Lifted constraint not implemented for constraint of type $(typeof(c)).")
end

"Represent an equality constraint in the lifted space."
function lift(c::EqualityConstraint, X, 𝒳)
  Convex.EqConstraint(lift(c.x, X, 𝒳), 0)
end

"Represent an LP constraint in the lifted space."
function lift(c::ConeConstraint{PositiveOrthant}, X, 𝒳)
  Convex.GtConstraint(lift(c.x, X, 𝒳), Convex.Constant(0))
end

"Represent a semidefinite constraint in the lifted space."
function lift(c::ConeConstraint{PositiveSemidefinite}, X, 𝒳)
  Convex.SDPConstraint(lift(c.x, X, 𝒳))
end

"Represent a set of constraints in the lifted space."
function lift(cons::Set{Constraint}, X, 𝒳)
  𝒞 = Set{Convex.Constraint}()
  for c ∈ cons
    push!(𝒞, lift(c, X, 𝒳))
  end
  𝒞
end

# function variables(x::Expression)::Set{Variable}
#   if isa(x, Constant)
#     Set()
#   elseif isa(x, Variable)
#     Set([x])
#   else
#     vars = Set{Variable}()
#     for y ∈ x.children
#       if isa(y, Variable)
#         push!(vars,y)
#       else
#         vars = vars ∪ variables(y)
#       end
#     end
#     vars
#   end
# end

# "Constants in an expression."
# function constants(x::Expression)::Set{Constant}
#   if isa(x, Constant)
#     Set([x])
#   elseif isa(x, Variable)
#     Set()
#   else
#     consts = Set{Constant}()
#     for y ∈ x.children
#       if isa(y, Constant)
#         push!(consts,y)
#       else
#         consts = consts ∪ constants(y)
#       end
#     end
#     consts
#   end
# end

# "Set of constraints that depend on a set of variables."
# function constraints(vars::Set{Variable})::Set{Constraint}
#   cons = Set{Constraint}()
#   for v ∈ vars
#     for o ∈ v.oracles
#       interpolation_conditions(o)
#     end
#     cons = cons ∪ v.constraints
#   end
#   cons
# end

# "Set of variables and constraints associated with an expression. The variables include those that directly affect the expression, as well as those that affect any constraint on those variables."
# function variables_constraints_constants(x::Expression)
#   vars = variables(x)
#   consts = constants(x)
#   cons = constraints(vars)
#   for c ∈ cons
#     vars = vars ∪ variables(c.x)
#     consts = consts ∪ constants(c.x)
#   end
#   vars, cons, consts
# end

# "Expression and its corresponding constraints in the lifted space."
# function lift(x::Expression)
  
#   # Get the variables and constraints associated with the performance measure
#   vars, cons, consts = variables_constraints_constants(x)

#   # Lift the set of variables
#   𝒳 = lift(vars, consts)

#   # Represent the performance measure in the lifted space
#   𝒫 = lifted_expression(P, 𝒳)

#   # Represent the constraints in the lifted space
#   𝒞 = lifted_constraints(cons, 𝒳)
  
#   # Return the expression and its associated constraints in the lifted space
#   𝒫, 𝒞
# end

# "Lift a set of variables to the lifted space in which all `Functional` expressions are affine."
# function lift(vars::Set{Variable}, consts::Set{Constant})
  
#   var_points  = filter(x -> typeof(x) <: Variable{Point},  vars)
#   var_scalars = filter(x -> typeof(x) <: Variable{Scalar}, vars)
  
#   const_points  = filter(x -> typeof(x) <: Constant{Point},  consts)
#   const_scalars = filter(x -> typeof(x) <: Constant{Scalar}, consts)
  
#   if vars ≠ var_points ∪ var_scalars
#     error("Unknown variable types in $vars.")
#   end
  
#   # number of variables of each type
#   n = length(var_points)
#   m = length(var_scalars)
  
#   # lifted variables
#   G = Convex.Semidefinite(n)
#   F = Convex.Variable(m)
  
#   # assign a unique element in a basis to each variable
#   for (i, x) ∈ enumerate(var_points)
#     lift!(x, i, n)
#   end
#   for (i, x) ∈ enumerate(var_scalars)
#     lift!(x, i, m)
#   end
#   for x ∈ const_points
#     if x.value.value == [0]
#       x.lift = zeros(m)
#     else
#       error("Cannot lift nonzero constant points.")
#     end
#   end
#   for x ∈ const_scalars
#     x.lift = [x.value.value]
#   end
  
#   (G, F)
# end

# "Represent a scalar-valued expression as an affine function in the lifted space. The functional must be affine in `Expression{Scalar}` objects and inner products of two `Expression{Point}` objects."
# function lifted_expression(x::Functional, 𝒳)
#   G, F = 𝒳
#   𝒜, 𝒷 = lift(x)
#   𝒜*𝒳 + 𝒷  # affine function Ax+b in the lifted space
#   Convex.tr(G * A) + Convex.inner_product(F, b) + c
# end

# function evaluate_lifted(𝒜, 𝒷, 𝒳)
#   A, b, c = 𝒜, 𝒷
#   G, F = 𝒳
#   Convex.tr(G * A) + Convex.inner_product(F, b) + c
# end

# "Each type of constraint must specialize this method."
# function lifted_constraint(c::Constraint)
#   error("Lifted constraint not implemented for constraint of type $(typeof(c)).")
# end

# "Represent an equality constraint in the lifted space."
# function lifted_constraint(c::EqualityConstraint, 𝒳)
#   Convex.EqConstraint(lifted_expression(c.x, 𝒳), 0)
# end

# "Represent an LP constraint in the lifted space."
# function lifted_constraint(c::ConeConstraint{T,PositiveOrthant}, 𝒳) where {T<:Value}
#   Convex.GtConstraint(lifted_expression(c.x, 𝒳), Convex.Constant(0))
# end

# "Represent a semidefinite constraint in the lifted space."
# function lifted_constraint(c::ConeConstraint{T,PositiveSemidefinite}, 𝒳) where {T<:Value}
#   Convex.SDPConstraint(lifted_expression(c.x, 𝒳))
# end

# "Represent a set of constraints in the lifted space."
# function lifted_constraints(cons::Set{Constraint}, 𝒳)
#   𝒞 = Set{Convex.Constraint}()
#   for c ∈ collect(cons)
#     push!(𝒞, lifted_constraint(c, 𝒳))
#   end
#   𝒞
# end
