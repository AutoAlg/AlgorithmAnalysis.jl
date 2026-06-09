# ------------------------------------------------------
# NUMERIC
# ------------------------------------------------------

export with_numerics, evaluate, feasible

import JuMP, Hypatia


const JUMP_MODEL = Base.ScopedValues.ScopedValue{JuMP.GenericModel}()
const PARAMETERS = Base.ScopedValues.ScopedValue{Dict}(Dict())

active_model() = isassigned(JUMP_MODEL)
parameters() = PARAMETERS[]

function default_model()
    model = JuMP.Model(Hypatia.Optimizer)
    JuMP.set_silent(model)
    return model
end

function with_parameters(code::Function, params::Dict)
    return Base.ScopedValues.with(code, PARAMETERS => params)
end

function with_numerics(code::Function; model_constructor::Function = () -> default_model(), parameters::Dict = Dict())
    with_parameters(parameters) do
        if active_model()
            code()
        else
            verbose() && @info "Initializing JuMP model..."
            val = Base.ScopedValues.with(code, JUMP_MODEL => model_constructor())
            verbose() && @info "JuMP model complete!"
            return val
        end
    end
end

function model()
    if active_model()
        JUMP_MODEL[]
    else
        error("No JuMP model instantiated. Use with_numerics() to run code inside of an optimizer.")
    end
end

function evaluate(x::BasicSymbolic)
    
    eval_node = function (node)

        !(node isa BasicSymbolic) && return node

        if iscall(node) && isequal(symtype(node), R)
            isequal(operation(node), zero) && return 0.0
            isequal(operation(node), one) && return 1.0
        end

        # ---------------------------------------------------------
        # LEAF TERMINALS
        # ---------------------------------------------------------
        if node ∈ keys(parameters())
            verbose() && @info "Object $node is a parameter"
            return parameters()[node]
        end
        
        if active_model() && has_id(node) && id(node) ∈ keys(JuMP.object_dictionary(model()))
            verbose() && @info "Object $node exists in the JuMP model"
            val = model()[id(node)]
            return JuMP.has_values(model()) ? JuMP.value(val) : val
        end

        # Handle initialization of raw variables (leaves) in JuMP
        if active_model() && !iscall(node)
            T = symtype(node)
            sym = id(node)
            if isequal(T, R)
                model()[sym] = JuMP.@variable(model(), base_name = string(sym))
                verbose() && @info "Object $node is in R, so initializing in JuMP as $(model()[sym])"
                return model()[sym]
            elseif isequal(T, Sⁿ)
                n = size(node)
                model()[sym] = JuMP.@variable(model(), [1:n,1:n], Symmetric, base_name = string(sym))
                verbose() && @info "Object $node is in Sⁿ, so initializing in JuMP as $(model()[sym])"
                return model()[sym]
            end
        end

        # ---------------------------------------------------------
        # OPERATORS
        # ---------------------------------------------------------
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

        if T <: Constraint && isequal(operation(node), ∧)
            return arguments(node)
        end

        if active_model()
            if T <: Equality
                lhs, rhs = arguments(node)
                verbose() && @info "Enforcing equality constraint $lhs = $rhs"
                return isequal(T, Equality{R}) ? 
                    JuMP.@constraint(model(), lhs == rhs) : 
                    JuMP.@constraint(model(), lhs .== rhs)

            elseif T <: LessThanOrEqualTo{R}
                lhs, rhs = arguments(node)
                verbose() && @info "Enforcing inequality constraint $lhs ≤ $rhs"
                return JuMP.@constraint(model(), lhs ≤ rhs)

            elseif T <: PositiveSemidefinite
                A = arguments(node)[1]
                verbose() && @info "Enforcing positive semidefinite constraint 0 ⪯ $A"
                return JuMP.@constraint(model(), la.Symmetric(convert(Matrix{JuMP.AffExpr}, A)) in JuMP.PSDCone())

            elseif isequal(T, Optimization)
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
                    
                    if is_minimization(node) || is_maximization(node)
                        return JuMP.value(obj)
                    elseif is_feasibility(node)
                        return JuMP.is_solved_and_feasible(model())
                    end
                catch
                    error("Failed to solve optimization problem. Consider first simplifying the problem symbolically using `simplify(opt)`")
                end
            end
        end
        return node
    end

    return postwalk_with_operators(eval_node, x)
end
