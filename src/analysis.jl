eye(n) = Matrix{Float64}(la.I, n, n)

tr(A) = sum(la.diag(A))

function linearform(p::Pair)
    A = Float64[ get(weights(selfdecomp(y)), x, 0) for y ∈ last(p), x ∈ first(p) ]
    if !isequal(last(p), A*first(p))
        error("The expression $(last(p)) is not a linear form in the variable $(first(p))")
    end
    A
end

function linearform(G::GramMatrix{V}, x::F) where {F<:Field, V<:InnerProductSpace{F}}
    if any(!isvariable(a) for a ∈ decomposition(G))
        error("The Gram matrix $G must consist of only variables to construct linear forms.")
    end
    A = Float64[ get(weights(selfdecomp(x)), a, 0) for a ∈ decomposition(G) ]
    if !isequal(x, tr(A*G))
        error("The expression $x is not a linear form in the Gram matrix $G")
    end
    A
end

function quadraticform(p::Pair)
    Q = Float64[ get(weights(selfdecomp(last(p))), x'*y, 0) for x ∈ first(p), y ∈ first(p) ]
    if !isequal(last(p), first(p)'*Q*first(p))
        error("The expression $(last(p)) is not a quadratic form in the variable $(first(p))")
    end
    Q
end

function stateupdate(vars)
    x  = collect(v for v ∈ vars if !ismissing(next(v)))
    xp = next(x)
    u  = collect(setdiff(variables(xp), variables(x)))
    X  = linearform([x; u] => x)
    Xp = linearform([x; u] => xp)
    
    X, Xp, x, u
end

function certify(performance::Field, ρ::Number)
    
    # variables, constraints, and oracles associated with the performance measure
    vars, cons, orcs = variables_constraints_oracles(performance)

    # # types of variables
    # var_types = Set( typeof(v) for v ∈ vars )
    
    # # dictionary of variables of each type
    # var_dict = Dict( T => Set{T}( v for v ∈ vars if v isa T ) for T ∈ var_types )
    
    lifted_vars = Expressions()
    lifted_cons = Constraints()
    
    # for each type of variable...
    for T ∈ Set( typeof(v) for v ∈ vars )
        
        # get the variables of that type
        vals = Set{T}( v for v ∈ vars if v isa T )
        
        if T <: InnerProductSpace
            
            X, Xp, x, u = stateupdate(vals)
            
            G = T[x; u] ⊗ T[x; u]
            
            Q = linearform(G, performance)
            
            push!(lifted_cons, G ⪰ 0)
            push!(lifted_vars, G)
            setdiff!(lifted_vars, [a for a ∈ decomposition(G)])
            
        elseif T <: Field
            
            union!(lifted_vars, vals)
            union!(lifted_cons, constraints(vals))
            
        end
    end
    
    # the constraints can couple the subspaces...
    # ℳ = [ linearform(G, expression(c)) for c in prune!(lifted_cons) ]
    
    lifted_vars, lifted_cons
    
    # nums = Set( v for v ∈ vars if v isa Field )
    # vecs = Set( v for v ∈ vars if v isa VectorSpace )
    
    # # state update
    # X, Xp, x, u = stateupdate(vecs)
    
    # G = [x; u] ⊗ [x; u]
    
    # Q = linearform(G, performance)
    
    # ℳ = [ linearform(G, expression(c)) for c in prune!(cons) ]
    
    # feas = solve(X,Xp,Q,ℳ,ρ) == MOI.OPTIMAL
end

function solve(X,Xp,Q,ℳ,ρ)
    
    # dimensions
    n = size(X,1)
    m = size(X,2)-n

    # optimization problem
    model = JuMP.Model(SCS.Optimizer)

    JuMP.set_silent(model)
    
    # variables
    JuMP.@variable(model, P[1:n,1:n], Symmetric )
    JuMP.@variable(model, λ1[1:length(ℳ)] ≥ 0)
    JuMP.@variable(model, λ2[1:length(ℳ)] ≥ 0)
    JuMP.@variable(model, G1[1:n+m,1:n+m], PSD )
    JuMP.@variable(model, G2[1:n+m,1:n+m], PSD )
    
    # multipliers
    Π1 = sum( first(p)*last(p) for p ∈ zip(λ1,ℳ) )
    Π2 = sum( first(p)*last(p) for p ∈ zip(λ2,ℳ) )

    # constraints
    JuMP.@constraint(model, 0 .== Xp'*P*Xp - ρ^2*(X'*P*X) + Π1 + G1 )
    JuMP.@constraint(model, 0 .== X'*(Q-P)*X + Π2 + G2 )

    JuMP.optimize!(model)
    
    return JuMP.termination_status(model)
end

rate(performance::Field) = bsmin( ρ -> certify(performance,ρ), 0, 1 )


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

