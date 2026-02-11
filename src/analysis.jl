function variables(o::OracleOrWrapper)
    # if !(typeof(unwrap(o)) <: AbstractLinearFunctional)
    vars = variables(inputs(o) ∪ outputs(o))
    # else
    #     vars = variables(outputs(o))
    # end
    # for a ∈ values(associations(o))
    for a ∈ associations(o)
        if first(a) != GradientOf
            union!(vars, variables(unwrap(last(a))))
        end
    end
    vars
end

variables(X::Union{ArrayOrSet,Generator}) = mapreduce(variables, ∪, X; init=Expressions())

function evaluate(P::PerformanceMeasure, f::Object, x::Object, xs::Object)
    if P == OptimalityGap
        f(x) - f(xs)
    elseif P == DistanceToOptimality
        (x - xs)^2
    elseif P == DistanceToStationarity
        f'(x)^2
    end
end

function constraints(X::Union{ArrayOrSet,Generator})
    prune!(mapreduce(constraints, ∪, X; init=Constraints()))
end

function oracles(X::Union{ArrayOrSet,Generator})
    mapreduce(oracles, ∪, X; init=Oracles())
end


############################################################################################
# Neighbors

neighbors(x::Expression) = variables(x) ∪ constraints(x) ∪ oracles(x)
neighbors(x::Constraint) = variables(x)
neighbors(x::Oracle) = variables(x) ∪ constraints(x)

# Get all objects in the graph using graph search
function nodes(x::Object)
    visited = Objects()
    queue = Objects([x])
    while !isempty(queue)
        node = pop!(queue)
        if node ∉ visited
            push!(visited, node)
            union!(queue, neighbors(node))
        end
    end
    visited
end


"""
    constraints_oracles

Recursively find all variables and constraints associated with an expression.
"""
function variables_constraints end

function variables_constraints(x::Object)
    xs = nodes(x)

    vars = Expressions( v for v ∈ xs if v isa Expression )
    cons = Constraints( c for c ∈ xs if c isa Constraint )

    cons = prune!(cons)

    vars, cons
end

function info(vars::Expressions)

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
    if length(get(con_dict, Semidefinite, Set())) > 1
        @info "$(get(con_dict, Semidefinite, Set()))"
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

isimplementable(e::Expression) = e isa R
isimplementable(c::Constraint) = expression(c) isa Union{R, ArrayOrSet{R}}
isimplementable(X::Union{ArrayOrSet,Generator}) = all( isimplementable(x) for x ∈ X )

function optvar(e::Expression, optvar_dict::Dict)
    if hasdecomposition(e)
        # mapreduce(p->last(p)*get(optvar_dict, first(p), value(first(p))), +, weights(e))
        x = 0
        for (key,val) ∈ weights(e)
            if haskey(optvar_dict, key)
                x += val * optvar_dict[key]
            else
                x += val * value(key)
            end
        end
        x
    else
        optvar_dict[e]
    end
end

optvar(m::AbstractArray, optvar_dict::Dict) = [ optvar(a, optvar_dict) for a ∈ m ]

function optcon(model::JuMP.Model, con::Constraint, optvar_dict::Dict)
    ex = optvar(expression(con), optvar_dict)
    if con isa Equality
        JuMP.@constraint(model, 0 == ex )
    elseif con isa Positive
        JuMP.@constraint(model, 0 ≤ ex )
    elseif con isa Semidefinite
        JuMP.@constraint(model, ex .== ex' )
        JuMP.@constraint(model, ex >= 0, JuMP.PSDCone() )
    else
        error("Optimization with constraint $con not implemented")
    end
end

function optimization_variable_dictionary(model::JuMP.Model, vars::Expressions)
    optvar_dict = Dict{R, JuMP.VariableRef}()
    for var ∈ vars
        if var isa R
            optvar_dict[var] = JuMP.@variable(model)
        else
            error("Optimization with variable $var not implemented")
        end
    end
    optvar_dict
end

"""
    multiplier(model, con)

Given a constraint, return the corresponding multiplier variable in the optimization model. The multiplier is an element of the dual cone of the constraint, so the inner product of the multiplier with the expression of the constraint is nonnegative for all feasible points.
"""
multiplier(model::JuMP.Model, c::ConeConstraint) = get_element(model, cone(c)', size(c))

"""
    maximize(performance)

Use the performance estimation methodology to find the worst-case value of the performance measure.

## Requirements
- The performance measure must be a real expression (that is, an element of `R`).
"""
function maximize(performance::Expression)

    if !isa(performance, R)
        error("The performance measure must be a real number in $R.")
    end

    @info "Maximizing the performance measure $performance"

    # variables, constraints, and oracles associated with the performance measure
    vars, cons, orcs = variables_constraints_oracles(performance)

    if !isimplementable(cons ∪ variables(cons))
        error("Analysis is not implementable! All constraints and associated variables must be implementable.")
    end

    # optimization variables
    optvars = filter( isimplementable, vars )

    # optimization problem
    model = JuMP.Model(SCS.Optimizer)

    JuMP.set_silent(model)

    @info "Setting up the optimization problem"

    # optimization variables
    optvar_dict = optimization_variable_dictionary(model, optvars)

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

    # interpolate each oracle
    foreach( interpolate, orcs )

    @info "Objective value: $(evaluate(performance))"

    @info "Analysis complete! Use `evaluate()` to obtain the value of any expression in the algorithm."
end

"""
    stateupdate(vars)

Given a set of variables, find the state update equations. The state update equations are defined as the equations that relate the current state to the next state. The function returns the linear forms of the current state and next state, as well as the state vector `x` and input vector `u`.
"""
function stateupdate(vars)
    x  = collect(v for v ∈ vars if !ismissing(next(v)) && v isa R)
    x⁺ = next(x)
    u  = collect(v for v ∈ vars if ismissing(next(v)) && v isa R)
    X  = linearform([x; u] => x)
    X⁺ = linearform([x; u] => x⁺)
    
    X, X⁺, x, u
end

dot(x, y::Expression) = x*y
dot(x, y::Gram) = la.tr(x * evaluate(y))

function negative!(model, vars, cons, f)
    for con ∈ cons
        λ = multiplier(model, con)
        e = expression(con)
        f += vec(linearform( vars => λ ⋅ e ))
    end
    JuMP.@constraint(model, f .== 0 )
end

"""
    certify(performance, rate)

Use the control methodology to search for a Lyapunov function that certifies convergence of the performance measure for all problem instances with the specified rate.

## Requirements
- The performance measure must be a real expression (that is, an element of `R`).
"""
function certify(performance::Expression, ρ::Number; solver = SCS.Optimizer, verbose=false)

    if !isa(performance, R)
        error("The performance measure must be a real number in $R.")
    end
    
    # variables and constraints associated with the performance measure
    vars, cons = variables_constraints(performance)
    vars = collect(vars)

    # state update
    X, X⁺, x, u = stateupdate(vars)

    # JuMP model
    model = JuMP.Model(solver)
    JuMP.set_silent(model)
    θ = JuMP.@variable(model, [1:length(x)])

    # Lyapunov function
    V = X'*θ
    V⁺ = X⁺'*θ

    # performance measure
    P = vec(linearform( [x; u] => performance ))

    # negative linear forms
    negative!(model, [x; u], cons, P - V)
    negative!(model, [x; u], cons, V⁺ - ρ * V)

    JuMP.optimize!(model)

    if verbose
        @info "Rate: $ρ, Termination status: $(JuMP.termination_status(model))"
    end

    JuMP.termination_status(model) == JuMP.OPTIMAL
end

linearform(p::Pair) = [ get(weights(selfdecomp(y)), x, 0) for y ∈ last(p), x ∈ first(p) ]

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

"""
    ρ = rate(performance)

Use the control theoretic methodology to search for a Lyapunov function that certifies convergence of the performance measure for all problem instances with the fastest possible rate. The analysis guarantees that the performance measure satisfies the bound

``\\text{performance}(k) \\leq c\\,\\rho^k``

at each iteration ``k``.

## Requirements
- The performance measure must be a real expression (that is, an element of `R`).
"""
function rate(performance::Expression; lb=0, ub=1, tol=1e-5, solver = SCS.Optimizer, verbose=false)
    if !isa(performance, R)
        error("The performance measure must be a real number in $R")
    end
    if verbose
        @info "Computing the convergence rate of $performance between $lb and $ub with tolerance $tol"
    end
    bsmin( ρ -> certify(performance, ρ; solver=solver, verbose=verbose), lb, ub, tol )
end
