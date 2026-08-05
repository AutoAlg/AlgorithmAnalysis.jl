export with_numerics, without_numerics
export model, active_model, default_model
export instantiate_in_model

const JUMP_MODEL = Base.ScopedValues.ScopedValue{Union{JuMP.GenericModel,Nothing}}()

active_model() = isassigned(JUMP_MODEL) && !isnothing(JUMP_MODEL[])

function default_model(::Type{Float64})
    model = JuMP.Model(Clarabel.Optimizer)
    JuMP.set_silent(model)
    return model
end

function default_model(T::DataType)
    model = JuMP.GenericModel{T}(Hypatia.Optimizer{T})
    JuMP.set_silent(model)
    return model
end

"""
    with_numerics(code;
        T = Float64,
        model_constructor = () -> default_model(T),
        parameters = Dict())

Execute code within a local scope with the given JuMP model with data type `T` and (additional) parameters.
"""
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

"""
    model()

Access the JuMP model within a numeric scope. See `with_numerics()`.
"""
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

"""
    instantiate_in_model(x)

Instantiate an expression (e.g., variable or constraint) in the JuMP model.
"""
instantiate_in_model(::Any) = nothing

function instantiate_in_model(x::Node{R})
    sym = id(x)
    model()[sym] = JuMP.@variable(model(), base_name = string(sym))
    return model()[sym]
end

function instantiate_in_model(x::Node{Sⁿ})
    n = size(node)
    sym = id(x)
    model()[sym] = JuMP.@variable(model(), [1:n,1:n], Symmetric, base_name = string(sym))
    return model()[sym]
end

function instantiate_in_model(c::Node{Equality{T}}) where T
    lhs, rhs = evaluate.(arguments(c))
    if isequal(T, R)
        JuMP.@constraint(model(), lhs == rhs)
    else
        JuMP.@constraint(model(), lhs .== rhs)
    end
end

function instantiate_in_model(c::Node{LessThanOrEqualTo{T}}) where T
    lhs, rhs = evaluate.(arguments(c))
    if isequal(T, R)
        JuMP.@constraint(model(), lhs ≤ rhs)
    else
        error("Unknown inequality type $T")
    end
end

function instantiate_in_model(c::Node{PositiveSemidefinite})
    A = evaluate(arguments(c)[1])
    T = typeof(model()).parameters[1]
    AA = convert.(JuMP.GenericAffExpr{T, JuMP.GenericVariableRef{T}}, A)
    return JuMP.@constraint(model(), AA in JuMP.PSDCone())
end

function instantiate_in_model(cons::Node{Conjunction})
    for con ∈ cons
        instantiate_in_model(con)
    end
end

function instantiate_in_model(opt::Node{Feasibility})
    con = evaluate(constraint(opt))
    verbose() && @info "Solving feasibility of $con"

    try
        JuMP.optimize!(model())
    catch
        error("Failed to solve optimization problem. Consider first simplifying the problem symbolically using `simplify($opt)`")
    end

    status = JuMP.termination_status(model())

    return status ∈ [MOI.OPTIMAL, MOI.ALMOST_OPTIMAL]
end

function instantiate_in_model(node::Node{<:Optimization})
    obj = evaluate(objective(node))
    con = evaluate(constraint(node))
    verbose() && @info "Optimizing $obj subject to $con"

    try
        if is_minimization(node)
            JuMP.@objective(model(), Min, obj)
        elseif is_maximization(node)
            JuMP.@objective(model(), Max, obj)
        end
        JuMP.optimize!(model())
        
        status = JuMP.termination_status(model())
        if status ∈ [MOI.OPTIMAL, MOI.ALMOST_OPTIMAL]
            return JuMP.value(obj)
        end
        @warn "Optimization terminated with status $status; numeric results are unreliable. Returning the JuMP model. Use `inspect(model)` to see the results."
        return model()
    catch
        error("Failed to solve optimization problem. Consider first simplifying the problem symbolically using `simplify($node)`")
    end
end
