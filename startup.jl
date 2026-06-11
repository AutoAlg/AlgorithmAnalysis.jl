using Revise
using AlgorithmAnalysis

# ------------------------------------------------------
# PERFORMANCE ESTIMATION
# ------------------------------------------------------

@alg begin
  α, L ∈ R, x, xs ∈ Rⁿ, f ∈ F(Rⁿ)

  gs   = f'(xs)
  g    = f'(x)
  init = (x - xs)'(x - xs)
  x⁺   = x - α * g
  f⁺   = f(x⁺)
  c1   = smooth_convex(f, L)
  c2   = gs'(gs) == zero(R)
  c3   = init ≤ one(R)
  con  = c1 ∧ c2 ∧ c3
  obj  = f⁺ - f(xs)
  opt  = maximize(obj, con)
end

topt = simplify(opt)

with_numerics(parameters = Dict(α => 0.075, L => 10.0)) do
    evaluate(topt) ≈ 2.0
end


# TODO
#   @var a = one(R) overwrites the id, which is how we identify the multiplicative identity
