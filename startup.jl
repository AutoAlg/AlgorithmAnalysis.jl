using Revise
using AlgorithmAnalysis
import AlgorithmAnalysis: ≡

default_setup()

########################################################
# LINEAR PROGRAMMING
########################################################

@var x ∈ R, y ∈ R
@def c1 = 50.0 * x + 24.0 * y ≤ 2400.0
@def c2 = 30.0 * x + 33.0 * y ≤ 2100.0
@def c3 = x ≥ 45.0
@def c4 = y ≥ 5.0
@def cons = c1 ∧ c2 ∧ c3 ∧ c4
@def obj = x + y - 50.0
@def opt = maximize(obj, cons)

evaluate(opt)

# with_verbose() do
#   evaluate(opt)
# end

# to evaluate other expressions, evaluate them in the same optimizer
with_optimizer() do
  evaluate(opt)
  @show evaluate(x)
  @show evaluate(y)
  nothing
end

let
  @def con = zero(Sym(R, 2)) ⪯ [ x y; y x ]
  @def opt = maximize(x, con)
  evaluate(opt) ≈ 1.0
end

evaluate(maximize(x, zero(Sym(R, 2)) ⪯ [2.0 x; x 2.0]))

feasible( zero(Sym(R,2)) ⪯ [-2.0 x; x -2.0] )

# with_optimizer() do
#   # evaluate(X)
#   # evaluate(zero(Sym(R, 2)))
#   evaluate(zero(R))
# end

let
  @var X ∈ Sym(R, 2)
  @def A = Object[1.0 0.0; 0.0 0.0]
  @def B = Object[0.0 0.0; 0.0 1.0]
  @def C = Object[0.0 1.0; 1.0 0.0]
  @def b = one(R)
  @def c1 = zero(Sym(R, 2)) ⪯ X
  @def c2 = tr(A * X) ≡ b
  @def c3 = tr(B * X) ≤ b
  @def con = c1 ∧ c2 ∧ c3
  @def obj = tr(C * X)
  @def opt = minimize(obj, con)
  with_optimizer() do
    @show evaluate(opt)
    @show evaluate(X)
    @show evaluate(tr(A*X))
    @show evaluate(tr(B*X))
    @show evaluate(tr(C*X))
    @show evaluate(b)
    @show as_array(X)
    @show tr(X)
    nothing
  end
end


########################################################
# PERFORMANCE ESTIMATION
########################################################

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
