# ------------------------------------------------------
# NUMERIC
# ------------------------------------------------------

export with_numerics, with_parameters, evaluate
export inspect, inspect_constraints
export is_parameter, get_parameter, multiplier
export value, hasvalue, evaluate_node, get_parameters
export with_additional_parameters

import JuMP, Hypatia, Clarabel
import MathOptInterface as MOI


const JUMP_MODEL = Base.ScopedValues.ScopedValue{Union{JuMP.GenericModel,Nothing}}()
const PARAMETERS = Base.ScopedValues.ScopedValue{Dict}(Dict())

active_model() = isassigned(JUMP_MODEL) && !isnothing(JUMP_MODEL[])
get_parameters() = PARAMETERS[]

function default_model(T::DataType)
    if isequal(T, Float64)
        model = JuMP.Model(Clarabel.Optimizer)
    else
        model = JuMP.GenericModel{T}(Hypatia.Optimizer{T})
    end
    JuMP.set_silent(model)
    return model
end

is_parameter(x::Node) = x ∈ keys(get_parameters())

function get_parameter(x::Node)
    if is_parameter(x)
        return get_parameters()[x]
    end
end

hasvalue(x::Node) = is_constant(x) || is_parameter(x)

function value(x::Node)
    if is_constant(x)
        return arguments(x)[1]
    elseif is_parameter(x)
        return get_parameters()[x]
    else
        error("$x has no value")
    end
end

function with_parameters(code::Function, parameters::Dict)
    return Base.ScopedValues.with(code, PARAMETERS => parameters)
end

function with_additional_parameters(code::Function, parameters::Dict)
    return with_parameters(code, merge(parameters, get_parameters()))
end

function with_numerics(code::Function;
    T::DataType = Float64,
    model_constructor::Function = () -> default_model(T),
    parameters::Dict = Dict()
    )
    with_additional_parameters(parameters) do
        verbose() && @info "Initializing JuMP model with parameters $(get_parameters())"
        val = Base.ScopedValues.with(code, JUMP_MODEL => model_constructor())
        verbose() && @info "JuMP model complete!"
        return val
    end
end

function without_numerics(code::Function)
    Base.ScopedValues.with(code, JUMP_MODEL => nothing)
end

function model()
    if active_model()
        JUMP_MODEL[]
    else
        error("No JuMP model instantiated. Use with_numerics() to run code inside of an optimizer.")
    end
end

function in_model(x::Node)
    active_model() && has_id(x) && id(x) ∈ keys(JuMP.object_dictionary(model()))
end

function get_from_model(x::Node)
    val = model()[id(x)]
    return JuMP.has_values(model()) ? JuMP.value(val) : val
end

instantiate_in_model(::Any) = nothing

function instantiate_in_model(x::Node{R})
    sym = id(x)
    model()[sym] = JuMP.@variable(model(), base_name = string(sym))
    verbose() && @info "Object $node is in R, so initializing in JuMP as $(model()[sym])"
    return model()[sym]
end

function instantiate_in_model(x::Node{Sⁿ})
    n = size(node)
    sym = id(x)
    model()[sym] = JuMP.@variable(model(), [1:n,1:n], Symmetric, base_name = string(sym))
    verbose() && @info "Object $node is in Sⁿ, so initializing in JuMP as $(model()[sym])"
    return model()[sym]
end

function instantiate_in_model(c::Node{Equality{T}}) where T
    lhs, rhs = arguments(c)
    verbose() && @info "Enforcing equality constraint $lhs = $rhs"
    if isequal(T, R)
        JuMP.@constraint(model(), lhs == rhs)
    else
        JuMP.@constraint(model(), lhs .== rhs)
    end
end

function instantiate_in_model(c::Node{LessThanOrEqualTo{T}}) where T
    lhs, rhs = arguments(c)
    verbose() && @info "Enforcing inequality constraint $lhs ≤ $rhs"
    if isequal(T, R)
        JuMP.@constraint(model(), lhs ≤ rhs)
    else
        error("Unknown inequality type $T")
    end
end

function instantiate_in_model(c::Node{PositiveSemidefinite})
    A = arguments(c)[1]
    T = typeof(model()).parameters[1]
    AA = convert.(JuMP.GenericAffExpr{T, JuMP.GenericVariableRef{T}}, A)
    verbose() && @info "Enforcing positive semidefinite constraint 0 ⪯ $A"
    return JuMP.@constraint(model(), AA in JuMP.PSDCone())
end

function instantiate_in_model(cons::Node{Conjunction})
    for con ∈ cons
        instantiate_in_model(con)
    end
end

function instantiate_in_model(opt::Node{Feasibility})
    con = constraint(opt)
    verbose() && @info "Solving feasibility of $con"

    try
        JuMP.optimize!(model())
    catch
        error("Failed to solve optimization problem. Consider first simplifying the problem symbolically using `simplify($node)`")
    end

    return JuMP.is_solved_and_feasible(model())
end

function instantiate_in_model(node::Node{<:Optimization})
    obj = objective(node)
    con = constraint(node)
    verbose() && @info "Optimizing $obj subject to $con"

    try
        if is_minimization(node)
            JuMP.@objective(model(), Min, obj)
        elseif is_maximization(node)
            JuMP.@objective(model(), Max, obj)
        end
        JuMP.optimize!(model())
        
        status = JuMP.termination_status(model())
        if status == MOI.OPTIMAL
            return JuMP.value(obj)
        end
        @warn "Optimization terminated with status $status; numeric results are unreliable. Returning the JuMP model. Use `inspect(model)` to see the results."
        return model()
    catch
        error("Failed to solve optimization problem. Consider first simplifying the problem symbolically using `simplify($node)`")
    end
end

function instantiate_in_model(prob::Node{LyapunovCertificate})

    # !active_model() && error("Searching for a Lyapunov certificate requires numerics")

    con, perf, ρ = constraint(prob), performance(prob), rate(prob)

    vars = filter(node -> !is_constant(node) && !is_parameter(node), leaves(prob))

    nonreal = filter(v -> !(v isa Node{R}), vars)

    if !isempty(nonreal)
        error("Problem has variables not in R: $nonreal\nConsider first simplifying the problem.")
    end

    basis = collect(Node{R}, vars)

    x, x₊ = state(prob)

    # number of states
    n = length(x)

    ctx = Set{Symbol}()

    if isnothing(ρ)
        sym = get_safe_symbol(:ρ, ctx)
        ρ = leaf(R, sym)
        push!(ctx, sym)
        bisect_rate = true
    else
        bisect_rate = false
    end

    # Lyapunov candidate parameters
    θ = Node{R}[]
    for _ in 1:n
        sym = get_safe_symbol(:θ, ctx, force_subscript = true)
        push!(θ, leaf(R, sym))
        push!(ctx, sym)
    end
    
    # Lyapunov candidate
    V  = θ ⋅ x
    V₊ = θ ⋅ x₊

    L₁, c₁, ctx = s_procedure(con, ctx, perf - V)
    L₂, c₂, ctx = s_procedure(con, ctx, V₊ - ρ * V)

    push!(basis, one(R))

    M₁ = as_matrix(basis => L₁)
    M₂ = as_matrix(basis => L₂)

    opt = feasible(c₁ ∧ c₂ ∧ mapreduce(c -> c == 0, ∧, M₁) ∧ mapreduce(c -> c == 0, ∧, M₂))

    if verbose()
        @info "Formulating the search for a Lyapunov certificate"
        @info "Basis: $basis"
        show(opt)
        println()
    end

    if bisect_rate
        f(ρval) = with_numerics(parameters = Dict(ρ => ρval)) do
            evaluate(opt)
        end
        return bsmin(f, 0.0, 1.0)
    end

    return with_numerics() do
        evaluate(opt)
    end
end

evaluate(x::Node) = postwalk_with_operators(evaluate_node, x)

evaluate_node(node::Any) = node

function evaluate_node(node::Node)

    if isequal(symtype(node), R)
        iszero(node) && return 0.0
        isone(node) && return 1.0
    end

    # -------------------------------------------
    # LEAF NODES
    # -------------------------------------------
    if is_parameter(node)
        verbose() && @info "Object $node is a parameter"
        return get_parameter(node)
    end
    
    if in_model(node)
        verbose() && @info "Object $node exists in the JuMP model"
        return get_from_model(node)
    end

    # Handle initialization of raw variables (leaves) in JuMP
    if active_model() && !iscall(node)
        val = instantiate_in_model(node)
        !isnothing(val) && return val
    end

    # -------------------------------------------
    # OPERATORS
    # -------------------------------------------
    if iscall(node)
        op = operation(node)
        args = arguments(node)
        T = symtype(node)

        if isequal(op, constant)
            return args[1]
        elseif op ∈ [+, -, *, /]
            return op(args...)
        elseif isequal(op, tr)
            verbose() && @info "Evaluating the trace of $(args[1])"
            return tr(args[1])
        elseif isequal(T, Sⁿ)
            return mat(node)
        end
    end

    # ---------------------------------------------------------
    # CONSTRAINTS & METAFUNCTIONS
    # ---------------------------------------------------------
    T = symtype(node)

    # if T <: Prop && isequal(operation(node), ∧)
    #     return arguments(node)
    # end

    if active_model()
        val = instantiate_in_model(node)
        !isnothing(val) && return val
    end

    if symtype(node) <: LyapunovCertificate
        return instantiate_in_model(node)
    end

    return node
end


"""
    negative!(model, vars, cons, f)

Constrains a given linear form `f` with variables `vars` to be negative by adding nonnegative terms associated with the constraints `cons` and then setting the result to zero in the optimization `model`.
"""
function s_procedure(constraint::Node{<:Prop}, ctx, f)
    con = satisfied()
    for c ∈ constraint
        symtype(c) <: Transition && continue
        λ, λ_con, ctx = multiplier(ctx, c)
        f += λ ⋅ expression(c)
        con = con ∧ λ_con
    end
    return f, con, ctx
end

function multiplier(ctx, ::Node{Equality{R}})
    sym = get_safe_symbol(:λ, ctx, force_subscript = true)
    λ = leaf(R, sym)
    push!(ctx, sym)
    return λ, satisfied(), ctx
end

function multiplier(ctx, ::Node{LessThanOrEqualTo{R}})
    sym = get_safe_symbol(:λ, ctx, force_subscript = true)
    λ = leaf(R, sym)
    push!(ctx, sym)
    return λ, λ ≥ zero(R), ctx
end

function multiplier(ctx, c::Node{PositiveSemidefinite})
    A = arguments(c)[1]
    n = size(A,1)
    λ = Matrix{Node{R}}(undef, (n,n))
    for i ∈ 1:n, j ∈ i:n
        sym = get_safe_symbol(:λ, ctx, force_subscript = true)
        λ[i,j] = leaf(R, sym)
        push!(ctx, sym)
    end
    for i ∈ 1:n, j ∈ 1:i-1
        λ[i,j] = λ[j,i]
    end
    Λ = Sⁿ(λ)
    return Λ, Λ ⪰ 0, ctx
end

function inspect(model::JuMP.Model, tolerance = 1e-6)
    status = JuMP.termination_status(model)
    println("-"^50)
    println("Termination status: ", status)
    println("Primal status:      ", JuMP.primal_status(model))
    println("Dual status:        ", JuMP.dual_status(model))
    println("Objective Value:    ", JuMP.objective_value(model))
    println("-"^50)
    println("VARIABLES")
    for var in JuMP.all_variables(model)
        @printf("%20s : %.6f\n", JuMP.name(var), JuMP.value(var))
    end
    println("-"^50)
    println("CONSTRAINTS")

    for (F, S) in JuMP.list_of_constraint_types(model)
        for con in JuMP.all_constraints(model, F, S)
            residual = JuMP.value(con)
            
            if S <: MOI.LessThan
                is_violated = residual > tolerance
                println("0 ≥ $residual")
            elseif S <: MOI.GreaterThan
                is_violated = residual < -tolerance
                println("0 ≤ $residual")
            elseif S <: MOI.EqualTo
                is_violated = abs(residual) > tolerance
                println("0 = $residual")
            elseif S <: MOI.Interval
                is_violated = abs(residual) > tolerance
                println("0 = |$residual|")
            end
        end

        if S <: MOI.PositiveSemidefiniteConeTriangle
            for con in JuMP.all_constraints(model, F, S)
                c_name = JuMP.name(con)
                display_name = isempty(c_name) ? "[unnamed PSD Prop]" : c_name
                raw_data = JuMP.value.(JuMP.constraint_object(con).func)
                matrix_val = unpack_triangular_vector(raw_data)
                evals = la.eigen(la.Symmetric(matrix_val)).values
                min_eval = minimum(evals)
                
                display(matrix_val)

                if min_eval < tolerance
                    println("❌ VIOLATION in PSD Prop: $display_name")
                    println("   Minimum Eigenvalue: $min_eval (Should be ≥ 0)")
                    println("   Full Spectrum: ", evals)
                else
                    println("✅ PSD Prop Satisfied: $display_name")
                    println("   Minimum Eigenvalue: $min_eval")
                end
            end
        end
    end
    println("-"^50)
end

"""
    unpack_triangular_vector(flat_vec::Vector{Float64})

Takes a 1D vector of packed lower-triangular elements and reconstructs 
a square, symmetric 2D Matrix.
"""
function unpack_triangular_vector(vec::Vector{Float64})
    len = length(vec)
    N_float = (-1.0 + sqrt(1 + 8 * len)) / 2.0
    
    if !isinteger(N_float)
        error("Vector length ($len) does not correspond to a packed triangular symmetric matrix.")
    end
    
    N = Int(N_float)
    mat = zeros(Float64, N, N)
    
    idx = 1
    for i in 1:N
        for j in 1:i
            mat[i, j] = vec[idx]
            mat[j, i] = vec[idx]
            idx += 1
        end
    end
    return mat
end

function inspect_constraints(model::JuMP.Model)
    for (F, S) in JuMP.list_of_constraint_types(model)
        for con in JuMP.all_constraints(model, F, S)
            c_obj = JuMP.constraint_object(con)
            # We only care about the scalar constraints (the interpolation inequalities)
            if !(S <: MOI.PositiveSemidefiniteConeTriangle)
                println(JuMP.name(con), " : ", c_obj.func, " in ", c_obj.set)
            end
        end
    end
end