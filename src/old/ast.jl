export Expression, Constraint, evaluate, head, id_hash, type, label!, label, children, parents, constraints, AbstractScalar, AbstractPoint, Scalar, Point, zero, lift


export Constant, Variable, evaluate, zero, constraints, lift

import Base.+, Base.-, Base.*, Base.^, Base.isequal


# "Data type for the value of an expression."
# abstract type Value end

# struct Scalar <: Value
#   value::Number
# end

# struct Point <: Value
#   value::AbstractArray
# end

# zero(::Type{Scalar}) = Scalar(0)
# zero(::Type{Point}) = Point([0])

# "Lift a vector of scalars."
# function lift(X::Vector{Scalar})
#   [ x.value for x ∈ X ]
# end

# "Lift a vector of points."
# function lift(X::Vector{Point})
#   P = reduce(hcat, x.value for x ∈ X)
#   P'*P
# end

# "Value or nothing (if value is unknown)."
# const ValueOrNothing = Union{Value,Nothing}

abstract type AbstractPoint end
abstract type AbstractScalar end

struct Point <: AbstractPoint end
struct Scalar <: AbstractScalar end

const Parents = Tuple{Expression}
const Children = Set{Expression}
const Label = String
const Constraints = Set{Constraint}
const Functional = Expression{AbstractScalar}

###############################################################################
# Each `Expression` must specialize the following methods.

"Evaluate an expression. Returns a value of type `type(e)` if the value of all children expressions are known, and `nothing` otherwise."
function evaluate(e::Expression) end

###############################################################################
# Each `Expression` must either have the fields `head`, `id_hash`, `label`,
# `children`, `parents`, and `constraints`, or it must specialize the following
# methods.

"Custom display of an expression."
Base.show(io::IO, x::Expression) = println(io, "$(typeof(x))($(x.label))")

"Set the label of an expression."
label!(x::Expression, label::String) = (x.label = label; nothing)

"Get the label of an expression."
label(x::Expression) = x.label

"Children of an expression, which is the set of expressions for which this expression is a parent."
children(x::Expression)::Expressions = x.children

"Parents of an expression, which is a set/tuple/vector of expressions on which the atom is operated to produce the expression."
parents(x::Expression)::Expressions = x.parents

"Data type for the values of an expression."
type(::Expression{T}) where {T} = T

"Test if two expressions are equal."
function isequal(x::Expression, y::Expression)::Bool
  if typeof(x) == typeof(y) && parents(x) == parents(y)
    true
  else
    false
  end
end

###############################################################################
# Constant expression

mutable struct Constant{T} <: Expression{T}
  value::T
  label::Label
  
  Constant(value::T, label::Label = "") where {T} = new{T}(value, label)
end

evaluate(x::Constant) = x.value

"Test if two constants are equal."
isequal(x::Constant{T}, y::Constant{T}) where {T} = x.value == y.value

###############################################################################
# Zero expression

struct Zero{T} <: Expression{T} end

evaluate(x::Zero) = zero(T)

zero(::Type{Expression{T}}) where {T} = Zero{T}()

"Test if two zero expressions are equal."
isequal(x::Zero{T}, y::Zero{T}) where {T} = true

###############################################################################
# Variable expression

mutable struct Variable{T} <: Expression{T}
  value::Union{T,Nothing}
  label::Label
  children::Children
  constraints::Constraints
  oracles::Oracles
  
  Variable{T}(label::Label = "") where {T} = new{T}(nothing, label, Children(), Constraints(), Oracles())
end

"Evaluate a variable. Returns `nothing` if the value is unknown."
evaluate(x::Variable) = x.value

"Construct an expression as a variable."
Expression{T}(label::Label = "") where {T} = Variable{T}(label)

"The set of constraints that depend on a variable."
function constraints(x::Variable)
  cons = x.constraints
  for o ∈ x.oracles
    cons = cons ∪ interpolation_conditions(o)
  end
  cons
end

"Test if two variables are equal."
function isequal(x::Variable{T}, y::Variable{T}) where {T}
  x.value == y.value && x.children == y.children && x.constraints == y.constraints && x.oracles == y.oracles
end

###############################################################################
# Unary negation

mutable struct NegateAtom{T} <: Expression{T}
  label::Label
  parents::Parents
  children::Children
  
  function NegateAtom(x::Expression{T}, label::Label = "") where {T}
    parents = (x,)
    this = new{T}(label, parents, Children())
    push!(x.children,this)
    return this
  end
end

evaluate(x::NegateAtom) = -evaluate(x.parents[1])

-(x::Expression) = NegateAtom(x)

###############################################################################
# Addition

mutable struct AdditionAtom{T} <: Expression{T}
  label::Label
  parents::Parents
  children::Children
  
  function AdditionAtom(x::Expression{T}, y::Expression{T}, label::Label = "") where {T}
    parents = Parents()
    isa(x, AdditionAtom) ? append!(parents, x.parents) : push!(parents, x)
    isa(y, AdditionAtom) ? append!(parents, y.parents) : push!(parents, y)
    this = new{T}(label, parents, Children())
    push!(x.children,this)
    push!(y.children,this)
    return this
  end
end

evaluate(x::AdditionAtom) = mapreduce(evaluate, (a, b) -> a .+ b, x.parents)

+(x::Expression, y::Expression) = AdditionAtom(x, y)
+(x::Expression, y) = AdditionAtom(promote(x, y)...)
+(x, y::Expression) = AdditionAtom(promote(x, y)...)

-(x::Expression, y::Expression) = x + (-y)
-(x::Expression, y) = x + (-y)
-(x, y::Expression) = x + (-y)

###############################################################################
# Scaling

mutable struct ScaleAtom{T} <: Expression{T}
  label::Label
  parents::Parents
  children::Children
  
  function ScaleAtom(x::Expression{T1}, y::Expression{T2}, label::Label = "") where {T1<:Number,T2}
    parents = (x,y)
    this = new{T2}(label, parents, Children())
    push!(x.children,this)
    push!(y.children,this)
    return this
  end
end

evaluate(x::ScaleAtom) = evaluate(x.parents[1])*evaluate(x.parents[2])

*(x::Number, y::Expression) = ScaleAtom(Constant(x), y)

###############################################################################
# Inner product

mutable struct InnerProductAtom <: Expression{AbstractScalar}
  label::Label
  parents::Parents
  children::Children
  
  function InnerProductAtom(x::Expression{T}, y::Expression{T}, label::Label = "") where {T<:AbstractPoint}
    parents = (x,y)
    this = new(label, parents, Children())
    push!(x.children,this)
    push!(y.children,this)
    return this
  end
end

evaluate(x::InnerProductAtom) = evaluate(x.parents[1])'*evaluate(x.parents[2])

###############################################################################
# Squared norm

mutable struct SquaredNormAtom <: Expression{AbstractScalar}
  label::Label
  parents::Parents
  children::Tuple{Expression}
  
  function SquaredNormAtom(x::Expression{T}, label::Label = "") where {T<:AbstractPoint}
    parents = (x,)
    this = new(label, parents, Children())
    push!(x.children,this)
    return this
  end
end

evaluate(x::SquaredNormAtom) = evaluate(x.parents[1])'*evaluate(x.parents[1])

*(x::Expression{T}, y::Expression{T}) where {T<:AbstractPoint} = (isequal(x,y) ? SquaredNormAtom(x) : InnerProductAtom(x, y))

^(x::Expression{T}, n::Int) where {T<:AbstractPoint} = (n == 2 ? SquaredNormAtom(x) : error("Power not implemented for n ≠ 2."))

InnerProductAtom(x::SquaredNormAtom) = InnerProductAtom(x.parents[1],x.parents[1])



###############################################################################
# Decomposition

"Decomposition of an expression into a dictionary whose keys are leaf expressions (variables or constants) and whose values are the corresponding weights."
decomposition(x::Zero) = Dict()
decomposition(x::Constant) = Dict(x => 1)
decomposition(x::Variable) = Dict(x => 1)
decomposition(x::AdditionAtom) = mergewith(+, decomposition(x.parents[1]), decomposition(x.parents[2]))
decomposition(x::ScaleAtom) = Dict(keys(decomposition(x.parents[2])) .=> map(v -> x.parents[1]*v, values(decomposition(x.parents[2]))))
decomposition(x::NegateAtom) = Dict(keys(decomposition(x.parents[2])) .=> map(v -> -v, values(decomposition(x.parents[2]))))

function decomposition(x::InnerProductAtom)
  ancestors = Dict()
  for (key1, value1) ∈ decomposition(x.parents[1])
    for (key2, value2) ∈ decomposition(x.parents[2])
      mergewith!(+, ancestors, Dict( (key1,key2) => value1*value2 ))
    end
  end
end

decomposition(x::SquaredNormAtom) = decomposition(InnerProductAtom(x))









export decompose, variables, constraints, lift, lifted_expression, lifted_constraint, lifted_constraints, variables_constraints_constants, basis_vector

function maximize(P::AbstractScalar)
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
  
  var_points  = filter(x -> typeof(x) <: Variable{AbstractPoint},  vars)
  var_scalars = filter(x -> typeof(x) <: Variable{AbstractScalar}, vars)
  
  const_points  = filter(x -> typeof(x) <: Constant{AbstractPoint},  consts)
  const_scalars = filter(x -> typeof(x) <: Constant{AbstractScalar}, consts)
  
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
function lifted_constraint(c::ConeConstraint{PositiveOrthant}, 𝒳)
  Convex.GtConstraint(lifted_expression(c.x, 𝒳), Convex.Constant(0))
end

"Represent a semidefinite constraint in the lifted space."
function lifted_constraint(c::ConeConstraint{PositiveSemidefinite}, 𝒳)
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
