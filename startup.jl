using Revise
using AlgorithmAnalysis, SymbolicUtils

########################################################
# PERFORMANCE ESTIMATION
########################################################

@alg begin
  α  ∈ R
  x  ∈ Rⁿ
  xs ∈ Rⁿ
  f  ∈ F(Rⁿ)

  gs   = f'(xs)
  g    = f'(x)
  init = (x - xs)'(x - xs)
  x⁺   = x - α * g
  c1   = f ∈ Convex
  c2   = gs == zero(Rⁿ)
  c3   = init ≤ one(R)
  con  = c1 ∧ c2 ∧ c3
  obj  = (x⁺ - xs)'(x⁺ - xs)
  opt  = maximize(obj, con)
end

topt = simplifier(opt)

using SymbolicUtils, TermInterface
using SymbolicUtils: Sym, BasicSymbolic, Term, FnType, symtype, Rewriters, @rule, term



# z = SymTerm{FnType{Tuple{R}, R, Nothing}}( :∇f, [f] )

# using JuMP

# with_optimizer() do

#   !implementable(objective) && error("Objective $objective is not implementable.")
#   !implementable(constraint) && error("Constraint $constraint is not implementable")

#   try
#       evaluate(constraint)
#       JuMP.@objective(model(), Max, evaluate(objective))
#       JuMP.optimize!(model())
#       return evaluate(objective)
#   catch
#       @info "The optimization problem maximize($objective, $constraint) is not directly solvable. Searching for a convexifying transformation…"

#   end
# end

########################################################
# LIST OF TRANSFORMATIONS
########################################################

# Transformation(
#     "Convex interpolation",
#     Spaces([Space(:F)]),
#     Spaces([Space(:Rⁿ), Space(:R)]),
#     () -> begin
#         for f ∈ elements(Space(:F))
#             xs = inputs(f) ∪ inputs(f')
#             for x ∈ xs, y ∈ xs
#                 f(y) ≥ f(x) + f'(x)'(y-x)
#             end
#             # value!(f, nothing)
#         end
#     end
#     # Given a set {x,fx,gx)} ⊂ Rⁿ × R × Rⁿ,
#     # ∃ f ∈ F : f(x) == fx ∧ f'(x) == gx ⟺ ∀(x,fx,gx),(y,fy,gy), fy ≥ fx + gx'(y-x)
# )

# Transformation(
#     "Gram transformation",
#     Spaces([Space(:Rⁿ)]),
#     Spaces([Space(:R)]),
#     () -> begin
#         xs = collect(elements(Space(:Rⁿ)))
#         @var G ∈ PSD(Space(:R), length(xs))
#         value!(G, [ x'(y) for x ∈ xs, y ∈ xs ])
#         # for x ∈ xs
#         #     value!(x, nothing)
#         # end
#     end
# )


# t = collect(transformations())

# U1 = get_universe()
# U2 = apply!(t[1], U1, :U2)
# U3 = apply!(t[2], U2, :U3)

# s = collect(spaces(U1))

# vars = variables(performance)
# ss = Spaces(space.(vars))

# @set M
# @trait M, Order(:≤)
# @var a ∈ M, b ∈ M


# convexify!(performance)


# PEP: maximize performance over f ∈ F, x0 ∈ Rⁿ s.t. ‖x0-xs‖² ≤ 1
# min t s.t. ∀ f ∈ F, ∀ x0 ∈ Rⁿ, ‖x0-xs‖² ≤ 1 ⟹ performance ≤ t

# General: min t s.t. P(t) where P : T → Prop, T ∈ Order

# @var t ∈ R

# P = ∀(f, ∀(x, ∀(xs, ((gs == zero(Rⁿ)) ∧ (init ≤ one(R))) ⟹ performance ≤ t)))

# opt = min(t, P)

# JuMP
# every variable is either VariableRef{T} or a container of them
# model = GenericModel{Real}()
# @variable(model, x[1:2, 1:2], PSD)
# eltype(x).parameters[1]

########################################################
# TODO
########################################################
# • analysis
# • simplifications? e.g., x + zero(Rⁿ) → x, a - b → a + (-b)
# • generic terms with set as a trait?
# • set-valued maps
# • relationship with proof assistants and dependent type theory
# • search for simplifying (e.g., convexifying) sequence of transformations
