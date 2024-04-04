function maximize(performance::R; optimizer=SCS.Optimizer)

    # variables and constraints associated with the performance measure
    vars, cons, _ = variables_constraints_oracles(performance)

    # construct the lifted transformation
    t = transform(vars, cons)

    # lifted objective
    𝒫 = lift(performance, t)

    # lifted constraints
    𝒞 = collect(lift(cons, t))

    # solve the optimization problem in the lifted space
    problem = cvx.maximize( 𝒫, 𝒞 )
    cvx.solve!(problem, optimizer; silent_solver=true)
    
    # project the solution onto the original variables
    project(t)

    # return the optimal value
    problem.optval
end

"Set of variables in a constraint or set of constraints."
variables(c::Constraint) = variables(expression(c))

function variables(o::OracleOrWrapper)
    vars = variables(inputs(o) ∪ outputs(o))
    for a ∈ values(associations(o))
        union!(vars, variables(inputs(a) ∪ outputs(a)))
    end
    vars
end

# Set of variables and constraints that depend on a set of variables.
variables(X::Union{AbstractArray,AbstractSet}) = mapreduce(variables, ∪, X; init=Expressions())
constraints(X::Union{AbstractArray,AbstractSet}) = mapreduce(constraints, ∪, X; init=Constraints())
oracles(X::Union{AbstractArray,AbstractSet}) = mapreduce(oracles, ∪, X; init=Oracles())

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

function variables_constraints_oracles(vars::Expressions, cons::Constraints, orcs::Oracles)

    count = 1
    
    while true
        
        # get the oracles associated with the variables
        orcs_new = oracles(vars)

        # get the constraints associated with the oracles
        cons_new = prune!(constraints(orcs_new))
        
        # get the variables associated with the constraints and the oracles
        vars_new = variables(cons) ∪ variables(orcs_new)

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
    
    vars, cons, orcs
end

function transform(vars, cons)
    
    # types of variables
    var_types = Set( typeof(v) for v ∈ vars )

    # dictionary mapping variable types to the associated variables
    var_dict = Dict( T => Set{T}( v for v ∈ vars if v isa T ) for T ∈ var_types )

    # lifted variables and constraints
    lifted_vars = vars
    lifted_cons = cons

    for (T,vals) ∈ var_dict
        if T <: InnerProductSpace
            v = collect(vals)
            push!(lifted_cons, v ⊗ v ⪰ 0)
            setdiff!(lifted_vars, v)
        end
    end

    scalars = collect(v for v ∈ vars if v isa R)
    points  = collect(v for v ∈ vars if v isa Rⁿ)

    X = (points, scalars)

    n = length(points)
    m = length(scalars)

    # lifted variables
    G = cvx.Semidefinite(n)
    F = cvx.Variable(m)
    𝒳 = (G,F)

    X, 𝒳
end

function project(t)

    X, 𝒳 = t
    points, scalars = X
    G, F = 𝒳

    # populate the values of the variables with the solution
    E = LinearAlgebra.eigen(G.value)
    Λ = E.values
    if any(Λ .≤ 0)
        @warn "Gram matrix is not positive semidefinite; eigenvalues are $Λ."
        Λ = abs.(Λ)
    end
    for i = 1:length(points)
        points[i].value = Rⁿ(sqrt.(Λ) .* E.vectors[i,:])
    end
    for i = 1:length(scalars)
        scalars[i].value = R(F.value[i])
    end
    nothing
end

"Lift an affine expression or constraint."
function lift(x::R, t)

    X, 𝒳 = t

    points, scalars = X

    n = length(points)
    m = length(scalars)
    
    A = Float64[ get(weights(selfdecomp(x)), points[i]'*points[j], 0.0) for i = 1:n, j = 1:n ]
    b = Float64[ get(weights(selfdecomp(x)), scalars[i], 0.0) for i = 1:m ]
    c = constant(selfdecomp(x))

    # the off-diagonal of A gets double-counted since the inner product is symmetric (x*y == y*x)
    D = LinearAlgebra.diagm(LinearAlgebra.diag(A))
    A = D + 0.5*(A-D)
    b = reshape(b, m, 1)
    
    G, F = 𝒳
    
    @show A
    @show b
    @show c
    @show G
    @show F
    
    cvx.tr(G * A) + (m>1 ? F'*b : 0.0) + c
end

# equivalent to just [ lift(x,X,𝒳) for x ∈ a ], but Convex.jl only overloads hvcat
lift(a::AbstractArray{<:Field}, t) = hvcat( size(a), [ lift(x,t) for x ∈ a ]... )

lift(cons::Constraints, t) = mapreduce(c->lift(c,t), push!, cons; init=Set{cvx.Constraint}())
lift(c::Constraint, t) = error("Lifted constraint not implemented for constraint of type $(typeof(c)).")
lift(c::Equality, t) = cvx.EqConstraint(lift(c.x,t), cvx.Constant(0.0))
lift(c::Positive, t) = cvx.GtConstraint(lift(c.x,t), cvx.Constant(0.0))
lift(c::Semidefinite, t) = cvx.SDPConstraint(lift(c.x,t))
