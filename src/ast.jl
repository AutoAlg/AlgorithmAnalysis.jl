export Expression, Constraint, evaluate, head, id_hash, type, label!, label, children, parents, constraints, Scalar, Point, Value, zero, lift

"Data type for the values of an expression."
abstract type Value end

struct Scalar <: Value
  value::Number
end

struct Point <: Value
  value::AbstractArray
end

zero(::Type{Scalar}) = Scalar(0)
zero(::Type{Point}) = Point([0])

"Lift a vector of scalars."
function lift(X::Vector{Scalar})
  [ x.value for x ∈ X ]
end

"Lift a vector of points."
function lift(X::Vector{Point})
  P = reduce(hcat, x.value for x ∈ X)
  P'*P
end

"Value or nothing (if value is unknown)."
const ValueOrNothing = Union{Value,Nothing}

"An abstract expression that evaluates to a value of type `T`."
abstract type Expression{T<:Value} end

"An abstract constraint on expressions that evaluates to a value of type `T`."
abstract type Constraint{T<:Value} end

const Expressions{T} = Set{Expression{T}}
const Parents = Set{Expression}
const Label = String
const Functional = Expression{Scalar}


"The `i`th basis vector of dimension `n`."
function basis_vector(i::Int, n::Int)
  if i ≤ 0 || i > n
    error("Basis vector must have 1 ≤ i ≤ n.")
  end
  e = zeros(n)
  e[i] = 1
  e
end

###############################################################################
# Each `Expression` must specialize the following methods.

"Evaluate an expression. Returns a value of type `type(e)` if the value of all children expressions are known, and `nothing` otherwise."
function evaluate(e::Expression)::ValueOrNothing end

###############################################################################
# Each `Expression` must either have the fields `head`, `id_hash`, `label`,
# `children`, `parents`, and `constraints`, or it must specialize the following
# methods.

"Custom display of an expression."
function Base.show(io::IO, x::T) where {T<:Expression}
  println(io, "$T($(x.label))")
end

"Set the label of an expression."
function label!(x::Expression, label::String)::Nothing
  x.label = label
  nothing
end

"Get the label of an expression."
function label(x::Expression)::String
  x.label
end

"Children of an expression, which is a set/tuple/vector of expressions on which the atom is operated to produce the expression."
function children(x::Expression)
  x.children
end

"Parents of an expression, which is the set of expressions for which this expression is a child."
function parents(x::Expression)::Set{Expression}
  x.parents
end

"Data type for the values of an expression."
type(::Expression{T}) where {T<:Value} = T


###############################################################################
# IsEqual

import Base.isequal

"Test if two expressions are equal (they are of the same type and have the same children)."
function isequal(x::Expression, y::Expression)::Bool
  if typeof(x) ≠ typeof(y)
    return false
  end
  if isa(x, Variable)
    if objectid(x) == objectid(y)
      return true
    else
      return false
    end
  end
  if isa(x, Constant)
    if x.value == y.value
      return true
    else
      return false
    end
  end
  n = length(children(x))
  if n ≠ length(children(y))
    return false
  end
  for i = 1:n
    if !isequal(x.children[i],y.children[i])
      return false
    end
  end
  true
end






export Constant, Variable, evaluate, zero, constraints, lift

import Base.+, Base.-, Base.*, Base.^, Base.isequal


###############################################################################
# Constant expression

mutable struct Constant{T<:Value} <: Expression{T}
  label::Label
  parents::Parents
  value::T
  lift::Vector
  
  Constant(value::T, label::Label = "") where {T<:Value} = new{T}(label, Parents(), value)
end

evaluate(x::Constant) = x.value

zero(::Type{Expression{T}}) where {T<:Value} = Constant(zero(T))

lift(x::Constant) = x.lift


###############################################################################
# Variable expression

mutable struct Variable{T<:Value} <: Expression{T}
  label::Label
  parents::Parents
  value::Union{T,Nothing}
  constraints::Set{Constraint}
  oracles::Set{Oracle}
  lift::Vector
  
  function Variable{T}(label::Label = "") where {T<:Value}
    new(label, Parents(), nothing, Set{Constraint}(), Set{Oracle}(), Vector())
  end
end

evaluate(x::Variable) = x.value

"Construct an expression (without arguments) as a variable."
Expression{T}() where {T<:Value} = Variable{T}()

"The set of constraints that depend on a variable."
constraints(x::Variable) = x.constraints

lift(x::Variable) = x.lift

###############################################################################
# Unary negation

mutable struct NegateAtom{T<:Value} <: Expression{T}
  label::Label
  children::Tuple{Expression}
  parents::Parents
  value::Union{T,Nothing}
  
  function NegateAtom(x::Expression{T}, label::Label = "") where {T<:Value}
    children = (x,)
    this = new{T}(label, children, Parents(), nothing)
    push!(x.parents,this)
    return this
  end
end

evaluate(x::NegateAtom) = -evaluate(x.children[1])

-(x::Expression) = NegateAtom(x)

lift(x::NegateAtom) = -lift(x.children[1])

###############################################################################
# Addition

mutable struct AdditionAtom{T<:Value} <: Expression{T}
  label::Label
  children::Vector{Expression}
  parents::Parents
  value::Union{T,Nothing}
  
  function AdditionAtom(x::Expression{T}, y::Expression{T}, label::Label = "") where {T<:Value}
    children = Vector{Expression{T}}()
    if isa(x, AdditionAtom)
      append!(children, x.children)
    else
      push!(children, x)
    end
    if isa(y, AdditionAtom)
      append!(children, y.children)
    else
      push!(children, y)
    end
    this = new{T}(label, children, Parents(), nothing)
    push!(x.parents,this)
    push!(y.parents,this)
    return this
  end
end

evaluate(x::AdditionAtom) = mapreduce(evaluate, (a, b) -> a .+ b, x.children)

+(x::Expression, y::Expression) = AdditionAtom(x, y)
+(x::Expression, y) = AdditionAtom(promote(x, y)...)
+(x, y::Expression) = AdditionAtom(promote(x, y)...)

-(x::Expression, y::Expression) = x + (-y)
-(x::Expression, y) = x + (-y)
-(x, y::Expression) = x + (-y)

function lift(x::AdditionAtom)
  if type(x.children[1]) == type(x.children[2])
    mapreduce(lift, (a, b) -> a + b, x.children)
  else
    
  end
end

###############################################################################
# Inner product

mutable struct InnerProductAtom <: Functional
  label::Label
  children::Tuple{Expression, Expression}
  parents::Parents
  value::Union{Scalar,Nothing}
  
  function InnerProductAtom(x::Expression{Point}, y::Expression{Point}, label::Label = "")
    children = (x,y)
    this = new(label, children, Parents(), nothing)
    push!(x.parents,this)
    push!(y.parents,this)
    return this
  end
end

evaluate(x::InnerProductAtom) = evaluate(x.children[1])'*evaluate(x.children[2])

*(x::Expression{Point}, y::Expression{Point}) = (isequal(x,y) ? SquaredNormAtom(x) : InnerProductAtom(x, y))

lift(x::InnerProductAtom) = lift(x.children[1])*lift(x.children[2])'

###############################################################################
# Squared norm

mutable struct SquaredNormAtom <: Functional
  label::Label
  children::Tuple{Expression}
  parents::Parents
  value::Union{Scalar,Nothing}
  
  function SquaredNormAtom(x::Expression{Point}, label::Label = "")
    children = (x,)
    this = new(label, children, Parents(), nothing)
    push!(x.parents,this)
    return this
  end
end

evaluate(x::SquaredNormAtom) = evaluate(x.children[1])'*evaluate(x.children[1])

^(x::Expression{Point}, n::Int) = (n == 2 ? SquaredNormAtom(x) : error("Power not implemented for n ≠ 2."))

lift(x::SquaredNormAtom) = lift(x.children[1])*lift(x.children[1])'









export decompose, variables, constraints, lift, lifted_expression, lifted_constraint, lifted_constraints, variables_constraints_constants, basis_vector

function maximize(P::Scalar)
  println("Maximizing the performance measure $P.")
  
end

"Variables in an expression."
function variables(x::Expression)::Set{Variable}
  if isa(x, Constant)
    Set()
  elseif isa(x, Variable)
    Set([x])
  else
    vars = Set{Variable}()
    for y ∈ x.children
      if isa(y, Variable)
        push!(vars,y)
      else
        vars = vars ∪ variables(y)
      end
    end
    vars
  end
end

"Constants in an expression."
function constants(x::Expression)::Set{Constant}
  if isa(x, Constant)
    Set([x])
  elseif isa(x, Variable)
    Set()
  else
    consts = Set{Constant}()
    for y ∈ x.children
      if isa(y, Constant)
        push!(consts,y)
      else
        consts = consts ∪ constants(y)
      end
    end
    consts
  end
end

"Set of constraints that depend on a set of variables."
function constraints(vars::Set{Variable})::Set{Constraint}
  cons = Set{Constraint}()
  for v ∈ vars
    for o ∈ v.oracles
      interpolation_conditions(o)
    end
    cons = cons ∪ v.constraints
  end
  cons
end

"Set of variables and constraints associated with an expression. The variables include those that directly affect the expression, as well as those that affect any constraint on those variables."
function variables_constraints_constants(x::Expression)
  vars = variables(x)
  consts = constants(x)
  cons = constraints(vars)
  for c ∈ cons
    vars = vars ∪ variables(c.x)
    consts = consts ∪ constants(c.x)
  end
  vars, cons, consts
end

"Expression and its corresponding constraints in the lifted space."
function lift(x::Expression)
  
  # Get the variables and constraints associated with the performance measure
  vars, cons, consts = variables_constraints_constants(x)

  # Lift the set of variables
  𝒳 = lift(vars, consts)

  # Represent the performance measure in the lifted space
  𝒫 = lifted_expression(P, 𝒳)

  # Represent the constraints in the lifted space
  𝒞 = lifted_constraints(cons, 𝒳)
  
  # Return the expression and its associated constraints in the lifted space
  𝒫, 𝒞
end

"Lift a set of variables to the lifted space in which all `Functional` expressions are affine."
function lift(vars::Set{Variable}, consts::Set{Constant})
  
  var_points  = filter(x -> typeof(x) <: Variable{Point},  vars)
  var_scalars = filter(x -> typeof(x) <: Variable{Scalar}, vars)
  
  const_points  = filter(x -> typeof(x) <: Constant{Point},  consts)
  const_scalars = filter(x -> typeof(x) <: Constant{Scalar}, consts)
  
  if vars ≠ var_points ∪ var_scalars
    error("Unknown variable types in $vars.")
  end
  
  # number of variables of each type
  n = length(var_points)
  m = length(var_scalars)
  
  # lifted variables
  G = Convex.Semidefinite(n)
  F = Convex.Variable(m)
  
  # assign a unique element in a basis to each variable
  for (i, x) ∈ enumerate(var_points)
    lift!(x, i, n)
  end
  for (i, x) ∈ enumerate(var_scalars)
    lift!(x, i, m)
  end
  for x ∈ const_points
    if x.value.value == [0]
      x.lift = zeros(m)
    else
      error("Cannot lift nonzero constant points.")
    end
  end
  for x ∈ const_scalars
    x.lift = [x.value.value]
  end
  
  (G, F)
end

"Represent a scalar-valued expression as an affine function in the lifted space. The functional must be affine in `Expression{Scalar}` objects and inner products of two `Expression{Point}` objects."
function lifted_expression(x::Functional, 𝒳)
  G, F = 𝒳
  𝒜, 𝒷 = lift(x)
  𝒜*𝒳 + 𝒷  # affine function Ax+b in the lifted space
  Convex.tr(G * A) + Convex.inner_product(F, b) + c
end

function evaluate_lifted(𝒜, 𝒷, 𝒳)
  A, b, c = 𝒜, 𝒷
  G, F = 𝒳
  Convex.tr(G * A) + Convex.inner_product(F, b) + c
end

"Each type of constraint must specialize this method."
function lifted_constraint(c::Constraint)
  error("Lifted constraint not implemented for constraint of type $(typeof(c)).")
end

"Represent an equality constraint in the lifted space."
function lifted_constraint(c::EqualityConstraint, 𝒳)
  Convex.EqConstraint(lifted_expression(c.x, 𝒳), 0)
end

"Represent an LP constraint in the lifted space."
function lifted_constraint(c::ConeConstraint{T,PositiveOrthant}, 𝒳) where {T<:Value}
  Convex.GtConstraint(lifted_expression(c.x, 𝒳), Convex.Constant(0))
end

"Represent a semidefinite constraint in the lifted space."
function lifted_constraint(c::ConeConstraint{T,PositiveSemidefinite}, 𝒳) where {T<:Value}
  Convex.SDPConstraint(lifted_expression(c.x, 𝒳))
end

"Represent a set of constraints in the lifted space."
function lifted_constraints(cons::Set{Constraint}, 𝒳)
  𝒞 = Set{Convex.Constraint}()
  for c ∈ collect(cons)
    push!(𝒞, lifted_constraint(c, 𝒳))
  end
  𝒞
end
