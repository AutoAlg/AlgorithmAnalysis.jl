using Revise
using AlgorithmAnalysis, SymbolicUtils
using AlgorithmAnalysis: expand, simplify

# ------------------------------------------------------
# PERFORMANCE ESTIMATION
# ------------------------------------------------------

@alg begin
  α ∈ R, x ∈ Rⁿ, xs ∈ Rⁿ, f ∈ F(Rⁿ)

  gs   = f'(xs)
  g    = f'(x)
  init = (x - xs)'(x - xs)
  x⁺   = x - α * g
  c1   = f ∈ Convex
  c2   = gs'(gs) == zero(R)
  c3   = init ≤ one(R)
  con  = c1 ∧ c2 ∧ c3
  obj  = (x⁺ - xs)'(x⁺ - xs)
  opt  = maximize(obj, con)
end

topt = simplify(opt)

SymbolicUtils.symtype.(AlgorithmAnalysis.flatten_constraints(constraint(opt)))
SymbolicUtils.symtype.(AlgorithmAnalysis.flatten_constraints(constraint(topt)))
