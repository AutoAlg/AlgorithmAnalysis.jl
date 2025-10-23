# Set of variables in a constraint or set of constraints
variables(c::Constraint) = variables(expression(c))

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

# function constraints(X::Union{ArrayOrSet,Generator})
#     cons = Constraints()
#     for c ∈ X
#         if length(associations(c))>0 && (first(first(associations(c))) == GradientOf || first(associations(c)) == GradientOf || first(first(associations(c))) == Gradient || first(associations(c)) == Gradient)
#         else
#             union!(cons, constraints(c))
#         end
#     end        
#     prune!(cons)
#     # prune!(mapreduce(constraints, ∪, X; init=Constraints()))
# end
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

Recursively find all variables, constraints, and oracles associated with an expression.
"""
function variables_constraints_oracles end

function variables_constraints_oracles(x::Object)
    xs = nodes(x)

    vars = Expressions( v for v ∈ xs if v isa Expression )
    cons = Constraints( c for c ∈ xs if c isa Constraint )
    orcs = Oracles( o for o ∈ xs if o isa Oracle )

    cons = prune!(cons)

    vars, cons, orcs
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
        JuMP.@constraint(model, 0 ≤ ex, JuMP.PSDCone() )
    else
        error("Optimization with constraint $con not implemented")
    end
end

function variable_dictionary(vars::Expressions)
    Dict( T => Set{T}( v for v ∈ vars if v isa T ) for T ∈ Set( typeof(v) for v ∈ vars ) )
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

function multiplier(model::JuMP.Model, con::ConeConstraint)
    K = cone(con)
    sz = size(con)
    if sz == (1,1)
        var = JuMP.@variable(model)
    else
        var = JuMP.@variable(model, [1:sz[1],1:sz[2]])
    end

    if con isa Equality
        # no constraints
    elseif con isa Positive
        JuMP.@constraint(model, var .≥ 0 )
    elseif con isa Semidefinite
        JuMP.@constraint(model, var .== var' )
        JuMP.@constraint(model, 0 ≤ var, JuMP.PSDCone() )
    else
        error("Optimization with constraint $con not implemented")
    end

    var
end

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

function stateupdate(vars)
    x  = collect(v for v ∈ vars if !ismissing(next(v)) && v isa R)
    real_vars = collect(v for v ∈ vars if v isa R)
    x⁺ = next(x)
    # u  = collect(setdiff(variables(x⁺), variables(vars)))
    u  = collect(v for v ∈ vars if ismissing(next(v)) && v isa R)
    # u  = setdiff(variables(real_vars), variables(x))
    X  = linearform([x; u] => x)
    X⁺ = linearform([x; u] => x⁺)
    
    X, X⁺, x, u
end

function nonnegative(λ, e, vars)
    if e isa Gram
        e = evaluate(e)
    end
    if e isa Expression
        vec(linearform(vars => λ * e))
    elseif e isa Vector
        vec(linearform(vars => λ' * e))
    elseif e isa Matrix
        vec(linearform(vars => la.tr(λ * e)))
    end
end

"""
    certify(performance, rate)

Use the control theoretic methodology to search for a Lyapunov function that certifies convergence of the performance measure for all problem instances with the specified rate.

## Requirements
- The performance measure must be a real expression (that is, an element of `R`).
"""
function certify(performance::Expression, ρ::Number)
    if !isa(performance, R)
        error("The performance measure must be a real number in $R.")
    end
    # variables, constraints, and oracles associated with the performance measure
    vars, cons, _ = variables_constraints_oracles(performance)
    vars = collect(vars)
    X, X⁺, x, u = stateupdate(vars)
    model = JuMP.Model(SCS.Optimizer)
    JuMP.set_silent(model)
    JuMP.@variable(model, P[1:length(x)])

    # Lyapunov function
    V = X'*P
    V⁺ = X⁺'*P

    # performance measure
    𝒫 = vec(linearform( [x; u] => performance ))

    # linear forms
    L1 = 𝒫 - V
    L2 = V⁺ - ρ*V
    for con ∈ cons
        λ = multiplier(model, con)
        μ = multiplier(model, con)
        e = expression(con)
        L1 += nonnegative(λ, e, [x; u])
        L2 += nonnegative(μ, e, [x; u])
    end
    JuMP.@constraint(model, L1 .== 0 )
    JuMP.@constraint(model, L2 .== 0 )

    JuMP.optimize!(model)

    JuMP.termination_status(model) == JuMP.OPTIMAL
end

linearform(p::Pair) = [ get(weights(selfdecomp(y)), x, 0) for y ∈ last(p), x ∈ first(p) ]

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
    rate(performance)

Use the control theoretic methodology to search for a Lyapunov function that certifies convergence of the performance measure for all problem instances with the fastest possible rate.

## Requirements
- The performance measure must be a real expression (that is, an element of `R`).
"""
function rate(performance::Expression, lb=0)
    if !isa(performance, R)
        error("The performance measure must be a real number in $R")
    end
    @info "Finding the convergence rate of $performance"
    @info "Searching for ρ between $lb and 1"
    bsmin( ρ -> certify(performance,ρ), lb, 1 )
end

function lift(state::Expression, dimension::Int)
    initial_state, initial_inputs = get_states_inputs(state)
    state_formula = get_formulas([initial_state; initial_inputs], Expressions(state))[1]
    input_formulas = get_formulas(initial_state, initial_inputs)

    all_states = [initial_state; state]
    depth = length(initial_state) # How many state is used to update
    for i in length(all_states)+1:dimension+length(all_states) # if 3 states have been created, next state is "lift_4_state"
        current_states = all_states[end-depth+1:end] # Get the states needed to create the inputs
        inputs = [] # Get the inputs needed for this update
        for input_formula in input_formulas
            input_oracle = input_formula[1]
            input_decomp = vec(input_formula[2]) # Get the decomp of the input
            decomp = sum(input_decomp * current_states for (input_decomp, current_states) in zip(input_decomp, current_states))
            label!(decomp, "lift_$(i)_input_$(length(inputs)+1)") # to create "lift_4_state" we use "lift_4_input_n"
            input = sample(input_oracle, decomp)
            push!(inputs, input)
        end
        state_decomp = vec(state_formula[2]) # Get the decomp of the next state
        state_components = [current_states; inputs] # Get the states and inputs needed to create the next state
        next_state = sum(state_decomp * state_components for (state_decomp, state_components) in zip(state_decomp, state_components))
        label!(next_state, "lift_$(i)_state") # label the new state
        @algorithm all_states[end] => next_state # define as next state
        push!(all_states, next_state)
        # push!(all_states)
    end
end

function get_formulas(components, targets)
    # components, targets = collect(components), collect(targets)
    formulas = []  
    for target in (targets)
        oracle = get_oracle_input(target)[1]
        if !ismissing(oracle) # target e is the result of sampling an oracle
            e = get_oracle_input(target)[2]
        else # target is just what it is
            e = target
        end
        if hasmethod(hasdecomposition, Tuple{typeof(e)}) && hasdecomposition(e) # if e is a decomposition
            if !⊆(Expressions(collect(keys(weights(decomposition(e))))), Expressions(components))
                return missing # break if anything in e's decomposition is not in components
            end
        else # if e is a variable
            if !⊆(Expressions(e), Expressions(components))
                return missing # break if e is not in component
            end
        end
        push!(formulas, (oracle, linearform(collect(components) => e)))
    end
    return formulas # Every target in targets can be created using the components
end

function get_states_inputs(e::Expression)
    states, inputs = Set(), []
    if !(e isa Gram) && hasmethod(hasdecomposition, Tuple{typeof(e)}) && hasdecomposition(e)
        for i in keys(weights(decomposition(e)))
            oracle = first(get_oracle_input(i))
            if !ismissing(oracle) # if the expression has an oracle, it is an input state
                push!(inputs, i)
            else
                push!(states, i)
            end
        end
    end
    first_state_candidates = copy(states)
    for state in states
        if !ismissing(next(state))
            delete!(first_state_candidates, next(state)) # If another state have "state" as its next state, "state" is not the first state)
        end
    end
    head = only(first_state_candidates)
    states = Any[]
    while !ismissing(next(head))
        push!(states, head)
        head = next(head)
    end
    return states, inputs
end