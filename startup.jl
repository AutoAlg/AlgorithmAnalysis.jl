using Revise
using AlgorithmAnalysis

# TODO
# Lyapunov analysis
# @var a = one(R) overwrites the id, which is how we identify the multiplicative identity
# does show() actually need to construct a separate semantic_ast?

@alg begin
    α, L, ρ ∈ R, x, xn ∈ Rⁿ, f ∈ F(Rⁿ), P ∈ Sⁿ

    c_f = smooth_convex(f, L)
    c_p = P ≻ 0 # TODO: map this to ⪰ 1e-6 and then implement it in `representation.jl:191`

    u = f'(x) # g
    c_xn = (xn == x - α * u) # X_{k+1} = Ax + Bu
    # why tf is this a constraint just write `xn = x - α * u`


    V = x'(P * x) # note, keep in mind that this will eventually be arbitarly argumented
    Vn = xn'(P * xn)

    c_vnv = (Vn - ρ * V) ≤ zero(R)

    cons = c_f ∧ c_p ∧ c_xn ∧ c_vnv
    opt = feasible(cons)
end
topt1 = apply_interpolation_conditions(opt, ...)
topt2 = apply_s_procedure(topt1, c_vnv) # -> c_vnv_with_τ_1...
topt3 = apply_gram_transformation(topt2)

with_numeric( inject ρ)
    do_bisection_search(evaluate(topt3)) 

# function w/ interpolation conditions
# s procedure
# gram stuff

# Meeting things

# how does this frontend look?
# How does the test case look?

# Sⁿ * Rⁿ representation.jl

# is the epsilon semidefinite -> definite thing fine? numeric:142
# I did add ≻ correctely, right? in representation.jl


# going forward the plan is to do seperate passes
# im thinking [
#   algebra,
#   expand sc & propagate x->xn,
#   algebra,
#   s-procedure,
#   algebra,
#   gram
#]
# breaking up the theory into multiple parts that can be segmented
# I'm also going to apply this to the pep stuff too but just vcat so it doesnt matter