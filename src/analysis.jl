function stateupdate(pair)
    vars     = mapreduce( x->keys(selfdecomp(x).weights), ∪, first(pair), init=Expressions() )
    nextvars = mapreduce( x->keys(selfdecomp(x).weights), ∪, last(pair), init=Expressions() )
    
    u = collect(setdiff(vars, nextvars) ∪ setdiff(nextvars, vars))
    
    A = Float64[ get(selfdecomp(xp).weights, x, 0) for xp ∈ last(pair), x ∈ first(pair) ]
    B = Float64[ get(selfdecomp(xp).weights, y, 0) for xp ∈ last(pair), y ∈ u ]
    
    return A, B, u
end

getmatrix(e::Expression, v::Vector) = [ get(weights(selfdecomp(e)), x'*y, 0) for x ∈ v, y ∈ v ]

getparams(c::Constraint, x, u) = getmatrix(expression(c), [x; u])

getparams(cons::Constraints, x, u) = [getparams(c, x, u) for c in prune!(cons)]

function solve(A,B,Q,ℳ,ρ)
    
    problem = cvx.satisfy()
    
    n = size(A,1)
    m = size(B,2)
    
    # variables
    P  = cvx.Variable(n,n)
    λ1 = cvx.Variable(length(ℳ), 1)
    λ2 = cvx.Variable(length(ℳ), 1)
    
    # multipliers
    Π1 = sum( first(p)*last(p) for p ∈ zip(λ1,ℳ) )
    Π2 = sum( first(p)*last(p) for p ∈ zip(λ2,ℳ) )
    
    X  = [LinearAlgebra.I zeros(n,m)]
    Xp = [A B]
    
    # constraints
    problem.constraints += [ ρ^2*X'*P*X - Xp'P*Xp - Π1 in :SDP ]
    problem.constraints += [ X'*(P-Q)*X - Π2 in :SDP ]
    problem.constraints += [ λ1 ≥ 0, λ2 ≥ 0 ]

    cvx.solve!(problem, SCS.Optimizer, verbose = false, silent_solver = true)
    
    return problem.status
end

"""
    Bisection search to find minimum

```julia
xopt = bsmin( f, a, b, tol=1e-5 )
```
Given a function `f` that returns true or false where `f(a) == false` and `f(b) == true`
and the function is monotone (only one cross-over point), returns the smallest input in
the interval `[a,b]` that still returns true within `tol`.
"""
function bsmin( f, a, b, tol=1e-5 )
    a,b = min(a,b),max(a,b)
    if f(a)
        return a
    end
    if !f(b)
        return b
    end
    while (b-a) > tol
        c = (a+b)/2
        if f(c)
            b = c
        else
            a = c
        end
    end
    return b
end

function rate(x,xp,𝒫,f)
    A, B, u = stateupdate(x => xp)
    ℳ = getparams(constraints(f), x, u)
    Q = getmatrix(𝒫,x)
    bsmin( ρ -> (solve(A,B,Q,ℳ,ρ) == MOI.OPTIMAL), 0, 1 )
end
