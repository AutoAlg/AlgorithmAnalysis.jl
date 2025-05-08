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
        if first(a) != GradientOf && first(a) != Gradient2Of
            union!(vars, variables(unwrap(last(a))))
        end
    end        
    vars
end

function variables(X::Union{ArrayOrSet,Generator})
    mapreduce(variables, ∪, X; init=Expressions())
end
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

# function grams(s::Set, X::Union{ArrayOrSet,Generator})
#     for i in X
#         push!(s, gram(i))
#     end
#     s
# end
# function push!(s::Set, g::Gram)
#     push = true
#     for i in s
#         if grams_compare(g, i)
#             delete!(s,i)
#         end
#         if grams_compare(i, g)
#             push = false
#         end
#     end
#     if push
#         push!(s, g)
#     end
#     s
# end

"""
    constraints_oracles

Recursively find all variables, constraints, and oracles associated with an expression.
"""
function variables_constraints_oracles end

function variables_constraints_oracles(e::Expression)
    
    vars = variables(e)
    orcs = oracles(vars)
    cons = constraints(vars ∪ orcs)
    
    variables_constraints_oracles(vars, cons, orcs)
end

function variables_constraints_oracles(vars::Expressions, cons::Constraints, orcs::Oracles)
    count = 1
    while true
        # get the variables associated with the constraints and the oracles
        vars_new = variables(cons ∪ orcs)

        # get the constraints associated with the oracles
        cons_new = constraints(vars ∪ orcs)

        # get the oracles associated with the variables
        orcs_new = oracles(vars)

        union!( vars_new, variables(filter(!ismissing, next.(vars_new))) )

        # if there are no new variables, constraints, or oracles, then exit
        if vars_new ⊆ vars && orcs_new ⊆ orcs# && cons_new ⊆ cons
            non_grams_new = Constraints()
            subset_or_equal = 0
            for coni in cons_new
                if expression(coni) isa Gram
                    subset_or_equal += 1
                    for conj in cons
                        if expression(conj) isa Gram && issetequal(expression(conj).vecs, expression(coni).vecs)
                            subset_or_equal -= 1
                            break
                        end
                    end
                else
                    push!(non_grams_new, coni)
                end
            end
            if subset_or_equal == 0 && non_grams_new ⊆ cons
                break
            end
        end

        # otherwise, append the new information and repeat
        union!( vars, vars_new )
        union!( orcs, orcs_new )
        union!( cons, cons_new )

        
        # check for an infinite loop
        if count > 10
            error("Iteration limit reached while finding variables, constraints, and oracles")
        end
        
        count += 1
    end
    # info(cons)
    cons = prune!(cons)
    cons = prune_grams(cons)
    # @info "Algorithmic objects"
    # info(vars)
    # info(cons)
    # info(orcs)
    
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

function maximize(performance::Expression)

    @info "PERFORMANCE ESTIMATION"

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
    # u  = collect(setdiff(variables(real_vars), variables(x)))
    a = real_vars
    X  = linearform([x; u] => x)
    X⁺ = linearform([x; u] => x⁺)
    
    X, X⁺, x, u
end
function certifyTMM(performance::Expression, ρ::Number, m, L, q0s, qs1, q01)
    if !isa(performance, R)
        error("The performance measure must be a real number in $R.")
    end
    # ρ = 0.15
    # delta = (ρ^2)/(1-ρ^2)
    # performance = ((1+delta)*(x2) - delta*(x1) -xs)^2
    vars, cons, orcs = variables_constraints_oracles(performance)
    vars = collect(vars)
    X, X⁺, x, u = stateupdate(vars)

    model = JuMP.Model(SCS.Optimizer)
    JuMP.set_silent(model)
    # optimization variables
    JuMP.@variable(model, P[1:length(x)])
    # L1 = vec(linearform([x;u] => (m*L*performance + q0s))).*[P; vec(zeros(1,length(u)))]
    # L2 = vec(linearform([x;u] => -((1-ρ^2)*qs1 + ρ^2*q01))).*[P; vec(zeros(1,length(u)))]
    L1 = vec(linearform([x;u] => (m*L*performance)))#.*[P; vec(zeros(1,length(u)))]
    # L2 = vec(linearform([x;u] => -((1-ρ^2)*qs1 + ρ^2*q01))).*[P; vec(zeros(1,length(u)))]
    λ = multiplier(model, q0s≥0); M = vec(linearform( [x; u] => λ * q0s ))
    L1 += M
    μ1 = multiplier(model, qs1≥0); N1 = vec(linearform( [x; u] => μ1 * qs1*(1-ρ^2) ))
    μ2 = multiplier(model, q01≥0); N2 = vec(linearform( [x; u] => μ2 * q01*(ρ^2) ))
    L2 = -N1 - N2
       
    # JuMP.@variable(model, P[1:length([x;u])])
    # L1 = vec(linearform([x;u] => 1.5*performance+q0s)).*P
    # L2 = vec(linearform([x;u] => -((1-ρ^2)*qs1 + ρ^2*q01))).*P

    # JuMP.@constraint(model, L1 .<= 0 )
    JuMP.@constraint(model, L2 .<= 0 )
    JuMP.optimize!(model)
    JuMP.termination_status(model) == JuMP.OPTIMAL
end
function certify(performance::Expression, ρ::Number)
    if !isa(performance, R)
        error("The performance measure must be a real number in $R.")
    end
    # variables, constraints, and oracles associated with the performance measure
    vars, cons, orcs = variables_constraints_oracles(performance)
    # order the variables
    vars = collect(vars)
    X, X⁺, x, u = stateupdate(vars) 
    # model = JuMP.Model(SCS.Optimizer)
    model = JuMP.Model(Mosek.Optimizer) 
    JuMP.set_silent(model)
    # optimization variables
    JuMP.@variable(model, P[1:length(x)])
    # Lyapunov function
    V = X'*P
    V⁺ = X⁺'*P
    𝒫 = vec(linearform( [x; u] => performance ))
    L1 = 𝒫 - V
    L2 = V⁺ - ρ^2*V
    # optimization constraints
    for con ∈ cons
        λ = multiplier(model, con)
        μ = multiplier(model, con)
        e = expression(con)
        if e isa Gram
            e = evaluate(e)
        end
        if e isa Expression
            M = vec(linearform( [x; u] => λ * e ))
            N = vec(linearform( [x; u] => μ * e ))
        elseif e isa Vector
            M = vec(linearform( [x; u] => λ' * e ))
            N = vec(linearform( [x; u] => μ' * e ))
        elseif e isa Matrix
            M = vec(linearform( [x; u] => la.tr(λ * e) ))
            N = vec(linearform( [x; u] => la.tr(μ * e) ))
        end

        L1 += M
        L2 += N
    end
    JuMP.@constraint(model, L1 .== 0 )
    JuMP.@constraint(model, L2 .== 0 )
    # t = 1e-10
    # JuMP.@constraint(model, L1 .<= t)
    # JuMP.@constraint(model, L2 .<= t)
    JuMP.optimize!(model)

    # L1_vals = JuMP.value.(L1)
    # L2_vals = JuMP.value.(L2)
    # JuMP.all_variables(model)
    # for (i, val) in enumerate(L1_vals)
    #     println("L1[", i, "] = ", val)
    # end
    # for (i, val) in enumerate(L2_vals)
    #     println("L2[", i, "] = ", val)
    # end

    # allv = JuMP.all_variables(model)
    # for i in allv
    #     println(i, " ", JuMP.value(i))
    # end
    JuMP.termination_status(model) == JuMP.OPTIMAL
end

# function solve(X,Xp,Q,ℳ,ρ)
    
#     # dimensions
#     n = size(X,1)
#     m = size(X,2)-n

#     # optimization problem
#     model = JuMP.Model(SCS.Optimizer)

#     JuMP.set_silent(model)
    
#     # variables
#     JuMP.@variable(model, P[1:n,1:n], Symmetric )
#     JuMP.@variable(model, λ1[1:length(ℳ)] ≥ 0)
#     JuMP.@variable(model, λ2[1:length(ℳ)] ≥ 0)
#     JuMP.@variable(model, G1[1:n+m,1:n+m], PSD )
#     JuMP.@variable(model, G2[1:n+m,1:n+m], PSD )
    
#     # multipliers
#     Π1 = sum( first(p)*last(p) for p ∈ zip(λ1,ℳ) )
#     Π2 = sum( first(p)*last(p) for p ∈ zip(λ2,ℳ) )

#     # constraints
#     JuMP.@constraint(model, 0 .== Xp'*P*Xp - ρ^2*(X'*P*X) + Π1 + G1 )
#     JuMP.@constraint(model, 0 .== X'*(Q-P)*X + Π2 + G2 )

#     JuMP.optimize!(model)
    
#     return JuMP.termination_status(model)
# end

# eye(n) = Matrix{Float64}(la.I, n, n)

# tr(A) = sum(la.diag(A))

function linearform(p::Pair)
    A = [ get(weights(selfdecomp(y)), x, 0) for y ∈ last(p), x ∈ first(p) ]
    # if !isequal(last(p), A*first(p))
    #     error("The expression $(last(p)) is not a linear form in the variable $(first(p))")
    # end
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

# function quadraticform(p::Pair)
#     Q = Float64[ get(weights(selfdecomp(last(p))), x'*y, 0) for x ∈ first(p), y ∈ first(p) ]
#     if !isequal(last(p), first(p)'*Q*first(p))
#         error("The expression $(last(p)) is not quadratic in the variable $(first(p))")
#     end
#     Q
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

# function rate(performance::Expression)
#     @info "CONTROL ANALYSIS"
#     if !isa(performance, R)
#         error("The performance measure must be a real number in $R")
#     end
#     @info "Finding the rate of convergence of performance measure $performance"
#     bsmin( ρ -> certify(performance,ρ), 0, 1 )
# end

function rate(performance::Expression, tracker=0)
    # @info "CONTROL ANALYSIS"
    if !isa(performance, R)
        error("The performance measure must be a real number in $R")
    end
    @info "Finding the rate of convergence of performance measure $performance"
    if tracker > 0 && !certify(performance, tracker)
        @info "Searching for ρ between $tracker and 1"
        bsmin( ρ -> certify(performance,ρ), tracker, 1 )
    else
        @info "Searching for ρ between 0 and 1"
        bsmin( ρ -> certify(performance,ρ), 0, 1 )
    end
end


function analysis(currentState, nextState)
    currentVariables, nextVariables = Set(), Set()
    for i in range(1, length(currentState))
        currentVariables = union(currentVariables, keys(selfdecomp(currentState[i]).weights))
        nextVariables = union(nextVariables, keys(selfdecomp(nextState[i]).weights))
    end
    algorithmInputs = collect(union(setdiff(currentVariables, nextVariables), setdiff(nextVariables, currentVariables)))
    
    A = zeros(length(currentState),length(currentState))
    B = zeros(length(currentState), length(algorithmInputs))
    C = zeros(length(algorithmInputs), length(currentState))
    for i in range(1, length(nextState))
        decomp = selfdecomp(nextState[i]).weights
        for j in range(1, length(currentState))
            A[i, j] = get(decomp, currentState[j], 0)
        end
        for j in range(1, length(algorithmInputs))
            B[i, j] = get(decomp, algorithmInputs[j], 0)
        end
    end
    for i in range(1, length(algorithmInputs))
        decomp = selfdecomp(algorithmInputs[i]).weights
        for j in range(1, length(currentState))
            C[i, j] = get(decomp, currentState[j], 0)
        end
    end 
    return A, B, C, algorithmInputs
end

function createFunctionValues(currentState, nextState, f)
    return [f(s) for s in currentState[1:length(currentState)-1]], [f(s) for s in nextState[1:length(nextState)-1]]
end

function createMatrix(expression::Expression, vectors, scalars)
    #Create matrix M
    dict = weights(selfdecomp(expression)) 
    Q = zeros(length(vectors), length(vectors))
    for i in range(1,length(vectors))
        for j in range(1,length(vectors))
            Q[i,j] = get(dict, vectors[i]'*vectors[j], 0)
        end
    end
    q = zeros(length(scalars))
    for i in range(1,length(scalars))
        q[i] = get(dict, scalars[i], 0)
    end
    return Q, q
end

function solve(A,B,M,m,Q,q,fcs,fns,rho)
    # state dimension
    n = size(A,1); #number of states
    nn = size(B,2) #number of inputs
    P = cvx.Variable(n,n);#Variable(nn, nn); #P
    p = cvx.Variable(n,1)

    numberOfConstraints = length(M)
    liftingDimension = length(fcs)

    λ1 = cvx.Variable(numberOfConstraints, 1); #lambda1
    λ2 = cvx.Variable(numberOfConstraints, 1); #lamnda2

    μ1 = cvx.Variable(numberOfConstraints, 1); #lambda1
    μ2 = cvx.Variable(numberOfConstraints, 1); #lamnda2

    Π1 = zeros(n+nn, n+nn)
    Π2 = zeros(n+nn, n+nn)

    π1 = zeros(size(m,1), size(m,2))
    π2 = zeros(size(m,1), size(m,2))
    
    problem = cvx.satisfy();
    for i in range(start = 1, stop = length(M))
        Π1 = Π1 + λ1[i]*M[i]
        Π2 = Π2 + λ2[i]*M[i]
        problem.constraints += (λ1[i] >= 0)
        problem.constraints += (λ2[i] >= 0)
    end

    for i in range(start = 1, stop = length(m))
        π1 = π1 + μ1[i]*m[i]
        π2 = π2 + μ2[i]*m[i]
        problem.constraints += (μ1[i] >= 0)
        problem.constraints += (μ2[i] >= 0)
    end

    #decrease conditions
    # problem.constraints += P in :SDP
    # problem.constraints += LinearAlgebra.tr(P) >= 1
    problem.constraints += (-[A B]'P*[A B] + rho^2*[LinearAlgebra.I zeros(n,nn)]'*P*[LinearAlgebra.I zeros(n,nn)] - Π1) in :SDP;
    problem.constraints += -p'*fns + rho^2*p'*fcs + π1
    
    problem.constraints += [P zeros(n,nn); zeros(m, n+nn)] - Q - Π2 in :SDP
    problem.constraints += p - q - π2 in :SDP

    cvx.solve!(problem, SCS.Optimizer, silent_solver = true);
    return problem.status
end

createConstraintMatrix(constraint::Constraint, vectors, scalars) = createMatrix(expression(constraint), vectors, scalars)
createConstraintMatrix(cons::Constraints, vectors, scalars) = [createConstraintMatrix(constraint, vectors, scalars) for constraint in prune!(cons)]

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
            label!(decomp, "$(i)th_lift_$(length(inputs)+1)th_input") # to create "4th_lift_state" we use "4th_lift_nth_input"
            input = sample(input_oracle, decomp)
            push!(inputs, input)
        end
        state_decomp = vec(state_formula[2]) # Get the decomp of the next state
        state_components = [current_states; inputs] # Get the states and inputs needed to create the next state
        next_state = sum(state_decomp * state_components for (state_decomp, state_components) in zip(state_decomp, state_components))
        label!(next_state, "$(i)th_lift_state") # label the new state
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
    if !(e isa Gram) && hasmethod(hasdecomposition, Tuple{typeof(e)}) && hasdecomposition(e) # hasmethod arg is Tuple{typeof}
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
    # states = []
    # for i in first_state_candidates
    #     head = i
    #     push!(states, [])
    #     while !ismissing(next(head))
    #         push!(states[end], head)
    #         head = next(head)
    #     end
    # end
    return states, inputs
end

PDstate(p::Rᵐ, q::Rⁿ) = PDstate(q, p)
function PDstate(p::Rⁿ, q::Rᵐ)
    f = missing
    for i in oracles(p) ∪ oracles(q)
        f = get(associations(i), GradientOf, get(associations(i), Gradient2Of, missing))
        if !ismissing(f)
            break
        end
    end
    if !ismissing(f)
        f([p ; q])
    else
        error("Couldn't find any functional oracle sampled at p or q")
    end
end   