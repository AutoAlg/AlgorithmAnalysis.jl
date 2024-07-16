"Set of variables in a constraint or set of constraints."
variables(c::Constraint) = variables(expression(c))

function variables(o::OracleOrWrapper)
    vars = variables(inputs(o) ∪ outputs(o))
    for a ∈ values(associations(o))
        union!(vars, variables(inputs(a) ∪ outputs(a)))
    end
    vars
end

# Set of variables and constraints that depend on a set of variables
function variables(X::Union{AbstractArray,AbstractSet})
    mapreduce(variables, ∪, X; init=Variables())
end
function constraints(X::Union{AbstractArray,AbstractSet})
    mapreduce(constraints, ∪, X; init=Constraints())
end
function oracles(X::Union{AbstractArray,AbstractSet})
    mapreduce(oracles, ∪, X; init=Oracles())
end

variables(g::Generator) = variables(Set(x for x ∈ g))
constraints(g::Generator) = constraints(Set(x for x ∈ g))
oracles(g::Generator) = oracles(Set(x for x ∈ g))

"""
    variables_constraints_oracles

Recursively find all variables, constraints, and oracles associated with an expression.
"""
function variables_constraints_oracles end

function variables_constraints_oracles(x::Expression)
    
    vars = variables(x)
    orcs = oracles(vars)
    cons = prune!(constraints(vars) ∪ constraints(orcs))
    
    variables_constraints_oracles(vars, cons, orcs)
end

function variables_constraints_oracles(vars::Variables, cons::Constraints, orcs::Oracles)

    count = 1
    
    while true
        
        # get the oracles associated with the variables
        orcs_new = oracles(vars)

        # get the constraints associated with the oracles
        cons_new = prune!(constraints(orcs_new))
        
        # get the variables associated with the constraints and the oracles
        vars_new = variables(cons) ∪ variables(orcs_new)

        union!(vars_new, variables(filter(!ismissing, next.(vars_new))))

        # if there are no new variables, constraints, or oracles, then exit
        if vars_new ⊆ vars && orcs_new ⊆ orcs && cons_new ⊆ cons
            break
        end
        
        # otherwise, append the new information and repeat
        union!(vars, vars_new)
        union!(orcs, orcs_new)
        union!(cons, cons_new)
        
        # check for an infinite loop
        if count > 10
            error("Recursion limit reached while finding variables, constraints, and oracles")
        end
        
        count += 1
    end

    @info "Algorithmic objects"
    info(vars)
    info(cons)
    info(orcs)
    
    vars, cons, orcs
end

function info(vars::Variables)

    # types of variables
    var_types = Set( typeof(v) for v ∈ vars )

    # dictionary of variables of each type
    var_dict = Dict( T => Set{T}( v for v ∈ vars if v isa T ) for T ∈ var_types )

    @info " ⋅ Variables"
    for var_type ∈ var_types
        @info "   ⋅ $(length(var_dict[var_type])) variables in $(var_type)"
        @debug "     ⋅ $(var_dict[var_type])"
    end
end

function info(cons::Constraints)

    # types of constraints
    con_types = Set( typeof(c) for c ∈ cons )

    # dictionary of constraints of each type
    con_dict = Dict( T => Set{T}( c for c ∈ cons if c isa T ) for T ∈ con_types )
    
    @info " ⋅ Constraints"
    for con_type ∈ con_types
        @info "   ⋅ $(length(con_dict[con_type])) $(con_type)"
        @debug "     ⋅ $(con_dict[con_type])"
    end
end

function info(orcs::Oracles)

    # types of oracles
    orc_types = Set( typeof(o) for o ∈ orcs )

    # dictionary of oracles of each type
    orc_dict = Dict( T => Set{T}( o for o ∈ orcs if o isa T ) for T ∈ orc_types )
    
    @info " ⋅ Oracles"
    for orc_type ∈ orc_types
        @info "   ⋅ $(length(orc_dict[orc_type])) $(orc_type)"
        @debug "     ⋅ $(orc_dict[orc_type])"
    end
end


function transform!(vars, cons, f)

    # types of variables
    var_types = Set( typeof(v) for v ∈ vars )

    # dictionary of variables of each type
    var_dict = Dict( T => Set{T}( v for v ∈ vars if v isa T ) for T ∈ var_types )

    removed_vars = Variables()

    for (T,vals) ∈ var_dict
        if T <: InnerProductSpace
            vecs = collect(vals)
            if isdisjoint( vecs, variables(cons) ∪ variables(f) )
                setdiff!( vars, vecs )
                union!( removed_vars, vecs )
                union!( vars, variables(vecs ⊗ vecs) )
                push!( cons, vecs ⊗ vecs ⪰ 0 )

                for v ∈ vecs, w ∈ vecs
                    if !ismissing(next(v)) && !ismissing(next(w))
                        update!( v'*w => next(v)'*next(w) )
                    end
                end
                
                newvars = variables(vecs ⊗ vecs)
                con = (vecs ⊗ vecs ⪰ 0)

                for newvar ∈ newvars
                    add_constraint!(newvar, con)
                end
            end
        end
    end

    @info "Transformed problem"
    info(vars)
    info(cons)

    removed_vars
end

function optvar(x::LinearDecomposition, optvar_dict::Dict)
    mapreduce( p -> last(p) * get(optvar_dict, first(p), value(first(p))), +, weights(x) )
end

optvar(v::Variable, optvar_dict::Dict) = optvar_dict[v]

optvar(m::AbstractArray, optvar_dict::Dict) = [ optvar(a, optvar_dict) for a ∈ m ]

function optcon(model::JuMP.Model, con::Constraint, optvar_dict::Dict)
    ex = optvar(expression(con), optvar_dict)
    if con isa Equality
        JuMP.@constraint(model, 0 == ex )
    elseif con isa Positive
        JuMP.@constraint(model, 0 ≤ ex )
    elseif con isa Semidefinite
        JuMP.@constraint(model, ex .== ex' )
        JuMP.@constraint(model, 0 ≤ ex, JuMP.PSDCone() )
    else
        error("Optimization with constraint $con not implemented")
    end
end

function performance_estimation(performance)
    
    @info "PERFORMANCE ESTIMATION"

    # variables, constraints, and oracles associated with the performance measure
    vars, cons, orcs = variables_constraints_oracles(performance)

    # transformed variables and constraints
    removed_vars = transform!(vars, cons, performance)

    # optimization problem
    model = JuMP.Model(SCS.Optimizer)

    JuMP.set_silent(model)

    @info "Setting up the optimization problem"

    # optimization variables
    optvar_dict = Dict{R, JuMP.VariableRef}()
    for var ∈ vars
        if var isa R
            optvar_dict[var] = JuMP.@variable(model)
        else
            error("Optimization with variable $var not implemented")
        end
    end

    @info "  ✓ variables"

    # optimization objective
    JuMP.@objective(model, Max, optvar(performance, optvar_dict))

    @info "  ✓ objective"

    # optimization constraints
    foreach( con -> optcon(model, con, optvar_dict), cons )

    @info "  ✓ constraints"

    JuMP.optimize!(model)

    @info "Termination status: $(JuMP.termination_status(model))"

    @info "Assigning values to original variables"

    # set the value of each variable
    foreach( p -> value!(first(p), JuMP.value(last(p))), optvar_dict )

    # add the removed variables back in
    union!(vars, removed_vars)

    # types of variables
    var_types = Set( typeof(v) for v ∈ vars )

    # dictionary of variables of each type
    var_dict = Dict( T => Set{T}( v for v ∈ vars if v isa T ) for T ∈ var_types )

    # factor Gram matrices to set the value of each vector
    for (T,vals) ∈ var_dict
        if T <: InnerProductSpace
            vecs = collect(vals)
            if isempty( vecs ∩ ( variables(cons) ∪ variables(performance) ) )
                G = vecs ⊗ vecs
                Gval = [ value(g) for g ∈ G ]
                E = la.eigen(Gval)
                Λ = E.values
                if any(Λ .≤ 0)
                    @warn "Gram matrix is not positive semidefinite; eigenvalues are $Λ."
                    Λ = abs.(Λ)
                end
                for i = 1:length(vecs)
                    value!( vecs[i], sqrt.(Λ) .* E.vectors[i,:] )
                end
            end
        end
    end

    @info "Objective value: $(evaluate(performance))"

    @info "Analysis complete! Use `evaluate()` to obtain the value of any expression in the algorithm."
end

function control_analysis(performance)
    
    
end


function stateupdate(vars)
    x  = collect(v for v ∈ vars if !ismissing(next(v)))
    x⁺ = next(x)
    u  = collect(setdiff(variables(x⁺), variables(x)))
    X  = linearform([x; u] => x)
    X⁺ = linearform([x; u] => x⁺)
    
    X, X⁺, x, u
end

function certify(performance::Field, ρ::Number)
    
    # variables, constraints, and oracles associated with the performance measure
    vars, cons, orcs = variables_constraints_oracles(performance)
    
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
            
            F, Fp, xf, uf = stateupdate(vals)
            
            union!(lifted_vars, vals)
            union!(lifted_cons, constraints(vals))
            
        else
            error("Unknown variable type $T")
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


eye(n) = Matrix{Float64}(la.I, n, n)

tr(A) = sum(la.diag(A))

function linearform(p::Pair)
    A = Float64[ get(weights(selfdecomp(y)), x, 0) for y ∈ last(p), x ∈ first(p) ]
    if !isequal(last(p), A*first(p))
        error("The expression $(last(p)) is not a linear form in the variable $(first(p))")
    end
    A
end

# function linearform(G::GramMatrix{V}, x::F) where {F<:Field, V<:InnerProductSpace{F}}
#     if any(!isvariable(a) for a ∈ decomposition(G))
#         error("The Gram matrix $G must contain only variables to construct linear forms.")
#     end
#     A = Float64[ get(weights(selfdecomp(x)), a, 0) for a ∈ decomposition(G) ]
#     if !isequal(x, tr(A*G))
#         error("The expression $x is not a linear form in the Gram matrix $G")
#     end
#     A
# end

function quadraticform(p::Pair)
    Q = Float64[ get(weights(selfdecomp(last(p))), x'*y, 0) for x ∈ first(p), y ∈ first(p) ]
    if !isequal(last(p), first(p)'*Q*first(p))
        error("The expression $(last(p)) is not quadratic in the variable $(first(p))")
    end
    Q
end

