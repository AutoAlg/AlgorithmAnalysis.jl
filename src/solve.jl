function maximize(performance::R; optimizer=SCS.Optimizer)

    # variables and constraints associated with the objective
    vars, cons = variables_constraints(performance)

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

"""
    variables_constraints

Recursively find all variables and constraints associated with a real scalar expression.
"""
function variables_constraints end

function variables_constraints(x::Expression)
    vars = variables(x)
    cons = constraints(vars) ∪ constraints(oracles(vars))
    
    vars, cons
    # (vars ∪ variables(vars), cons ∪ constraints(cons))
end

# function variables_constraints(x::R)

#     scalars = variables(x)
#     vectors = Set(o' for o ∈ oracles(scalars))
#     orcs = oracles(vectors ∪ scalars)
#     cons = constraints(outputs(orcs))

#     count = 0

#     while true

#         # get the variables associated with those constraints
#         vars_new = variables(cons)

#         # get the constraints associated with those variables
#         cons_new = constraints(vars_new)

#         # if no new variables or constraints are found, then exit
#         if vars_new ⊆ vars && cons_new ⊆ cons
#             break

#         # otherwise, append the new variables and constraints and repeat
#         else
#             vars = vars ∪ vars_new
#             cons = cons ∪ cons_new
#         end

#         if count > 10
#             @warn "Limit reached before all variables and constraints were found."
#             break
#         else
#             count += 1
#         end
#     end
#     vars, cons
# end

"Set of constraints that depend on a set of variables."
constraints(vars::Set{<:Expression}) = mapreduce(constraints, ∪, vars; init=Constraints())

"Set of variables in a constraint or set of constraints."
variables(c::ConeConstraint) = variables(expression(c))
variables(cons::Set{<:Constraint}) = mapreduce(variables, ∪, cons; init=Expressions())
variables(A::AbstractArray{<:Expression}) = mapreduce(variables, ∪, A)

function transform(vars, cons)

    scalars = collect(filter(x -> x isa R, vars))
    points  = collect(filter(x -> x isa Rⁿ, vars))

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
