using Revise
using AlgorithmAnalysis


#########################################################
# LINEAR PROGRAMMING
#########################################################

@set Prop, R
@trait Prop, PropositionalLogic, Numeric(Bool)
@trait R, Equality(Prop), Ring, Order(Prop), Numeric(Float64)
@var x ∈ R, y ∈ R
50.0 * x + 24.0 * y ≤ 2400.0
30.0 * x + 33.0 * y ≤ 2100.0
x ≥ 45.0
y ≥ 5.0
@def val = x + y - 50.0

sol = maximize(val)

# SOLUTION: x=45, y=6.25, val=1.25

evaluate(val, dict = sol)

#########################################################
# PERFORMANCE ESTIMATION
#########################################################

# U = Universe(:U)

# in_universe(U) do
#   Prop = Space(:Prop)
#   @trait Prop, PropositionalLogic, Numeric(Bool)
#   @set R, Rⁿ, F
#   @trait R, Equality(Prop), Ring, Order(Prop), Numeric
#   @trait Rⁿ, Equality(Prop), InnerProductSpace(R)
#   @trait F, Equality(Prop), Subdifferential(Rⁿ → R)
#   @var α ∈ R, x ∈ Rⁿ, xs ∈ Rⁿ, f ∈ F
#   @def gs = f'(xs)
#   @def g = f'(x)
#   gs == zero(Rⁿ)
#   @def init = (x - xs)'(x-xs)
#   init ≤ one(R)
#   @def x⁺ = x - α ⋅ g
#   @def performance = (x⁺ - xs)'(x⁺ - xs)
# end

# @set Prop, R, Rⁿ, F
# @trait Prop, PropositionalLogic, Numeric(Bool)
# @trait R, Equality(Prop), Ring, Order(Prop), Numeric
# @trait Rⁿ, Equality(Prop), InnerProductSpace(R)
# @trait F, Equality(Prop), Subdifferential(Rⁿ → R)
# @var α ∈ R, x ∈ Rⁿ, xs ∈ Rⁿ, f ∈ F
# @def gs = f'(xs)
# @def g = f'(x)
# gs == zero(Rⁿ)
# @def init = (x - xs)'(x - xs)
# init ≤ one(R)
# @def x⁺ = x - α ⋅ g
# @def performance = (x⁺ - xs)'(x⁺ - xs)





#########################################################
# LIST OF TRANSFORMATIONS
#########################################################

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

#########################################################
# TODO
#########################################################
# • analysis
# • simplifications? e.g., x + zero(Rⁿ) → x, a - b → a + (-b)
# • generic terms with set as a trait?
# • set-valued maps
# • relationship with proof assistants and dependent type theory
# • search for simplifying (e.g., convexifying) sequence of transformations
