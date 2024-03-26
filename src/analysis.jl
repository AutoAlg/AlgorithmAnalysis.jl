eye(n) = Matrix{Float64}(la.I, n, n)

function stateupdate(pair)
    vars     = mapreduce( x->keys(selfdecomp(x).weights), ∪, first(pair), init=Expressions() )
    nextvars = mapreduce( x->keys(selfdecomp(x).weights), ∪, last(pair), init=Expressions() )
    
    u = collect(setdiff(vars, nextvars) ∪ setdiff(nextvars, vars))
    
    A = Float64[ get(selfdecomp(xp).weights, x, 0) for xp ∈ last(pair), x ∈ first(pair) ]
    B = Float64[ get(selfdecomp(xp).weights, y, 0) for xp ∈ last(pair), y ∈ u ]
    
    return A, B, u
end

function getmatrix(e::Expression, v::Vector)
    M = [ get(weights(selfdecomp(e)), x'*y, 0) for x ∈ v, y ∈ v ]
    0.5*(M+M')
end

getparams(c::Constraint, x, u) = getmatrix(expression(c), [x; u])

getparams(cons::Constraints, x, u) = [getparams(c, x, u) for c in prune!(cons)]

function solve(A,B,Q,ℳ,ρ)
    
    # dimensions
    n = size(A,1)
    m = size(B,2)

    # optimization problem
    model = JuMP.Model(SCS.Optimizer)

    JuMP.set_silent(model)
    
    # variables
    JuMP.@variable(model, P[1:n,1:n], Symmetric )
    JuMP.@variable(model, λ1[1:length(ℳ)] ≥ 0)
    JuMP.@variable(model, λ2[1:length(ℳ)] ≥ 0)
    
    # multipliers
    Π1 = sum( first(p)*last(p) for p ∈ zip(λ1,ℳ) )
    Π2 = sum( first(p)*last(p) for p ∈ zip(λ2,ℳ) )
    
    X  = [eye(n) zeros(n,m)]
    Xp = [A B]

    # constraints
    JuMP.@constraint(model, 0 ≥ Xp'*P*Xp - ρ^2*(X'*P*X) + Π1, JuMP.PSDCone() )
    JuMP.@constraint(model, 0 ≥ X'*(Q-P)*X + Π2, JuMP.PSDCone() )

    JuMP.optimize!(model)

    # @show n, m
    # @show A
    # @show B
    # @show Q
    # @show P
    # @show ℳ
    # @show X
    # @show Xp
    # @show JuMP.value(P)
    # @show JuMP.value.(λ1)
    # @show JuMP.value.(λ2)
    # @show cvx.evaluate(LMI1)
    # @show la.eigvals(cvx.evaluate(LMI1))
    
    return JuMP.termination_status(model)
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


abstract type StateTransition end
abstract type LyapunovClass end
abstract type PerformanceClass end
abstract type MultiplierClass end

function rate(f::StateTransition,𝒱::LyapunovClass,𝒫::PerformanceClass,ℳ::MultiplierClass,ρ::Number)

    # optimization problem
    model = JuMP.Model(SCS.Optimizer)

    # variables
    JuMP.@variable(model, V ∈ 𝒱 )
    JuMP.@variable(model, P ∈ 𝒫 )
    JuMP.@variable(model, M₁ ∈ ℳ )
    JuMP.@variable(model, M₂ ∈ ℳ )

    # constraints
    JuMP.@constraint(model, 0 ≥ V ∘ f - ρ*V + M₁ )
    JuMP.@constraint(model, 0 ≥ P - V + M₂ )

    # options
    JuMP.set_silent(model)

    # solve
    JuMP.optimize!(model)
    
    return JuMP.termination_status(model)
end

struct LinearStateTransition <: StateTransition
    A::Matrix
    B::Matrix
end

struct QuadraticLyapunovClass <: LyapunovClass
    P::Matrix
end

struct QuadraticPerformanceClass <: PerformanceClass
    Q::Matrix
end

struct QuadraticMultiplierClass <: MultiplierClass
    M::Matrix
end

# # for each subspace with lift ℓ from state-input pairs to convex set C in S...
# X  = projection(ℓ)'
# X₊ = commutator(ℓ,f)'

# # commutator(::GramLift, A, B)' = [A B]
# JuMP.@constraint(model, 0 ≥ V ∘ X₊ - ρ*(V ∘ X) + M₁, C' )
# JuMP.@constraint(model, 0 ≥ (P - V) ∘ X + M₂, C' )
