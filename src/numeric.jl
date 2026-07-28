# ------------------------------------------------------
# NUMERIC
# ------------------------------------------------------

export with_numerics, with_parameters, evaluate
export inspect, inspect_constraints
export isparameter, get_parameter_value, multiplier
export value, hasvalue

import JuMP, Hypatia
import MathOptInterface as MOI


const JUMP_MODEL = Base.ScopedValues.ScopedValue{JuMP.GenericModel}()
const PARAMETERS = Base.ScopedValues.ScopedValue{Dict}(Dict())

active_model() = isassigned(JUMP_MODEL)
parameters() = PARAMETERS[]

function default_model(T::DataType)
    model = JuMP.GenericModel{T}(Hypatia.Optimizer{T})
    JuMP.set_silent(model)
    return model
end

isparameter(x::Node) = x ∈ keys(parameters())

hasvalue(x::Node) = isconstant(x) || isparameter(x)

function value(x::Node)
    if isconstant(x)
        return arguments(x)[1]
    elseif isparameter(x)
        return parameters()[x]
    else
        error("$x has no value")
    end
end

function with_parameters(code::Function, params::Dict)
    return Base.ScopedValues.with(code, PARAMETERS => params)
end

function with_numerics(code::Function; T::DataType = Float64, model_constructor::Function = () -> default_model(T), parameters::Dict = Dict())
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

function get_parameter_value(node::Node)
    if node ∈ keys(parameters())
        return parameters()[node]
    end
end

function evaluate(x::Node)
    
    eval_node = function (node)

        !(node isa Node) && return node

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

        if T <: Prop && isequal(operation(node), ∧)
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
                T = typeof(model()).parameters[1]
                AA = convert.(JuMP.GenericAffExpr{T, JuMP.GenericVariableRef{T}}, A)
                verbose() && @info "Enforcing positive semidefinite constraint 0 ⪯ $A"
                return JuMP.@constraint(model(), AA in JuMP.PSDCone())

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
                        status = JuMP.termination_status(model())
                        if status == MOI.OPTIMAL || status == MOI.ALMOST_OPTIMAL
                            return JuMP.value(obj)
                        end
                        @warn "Optimization terminated with status $status; numeric results are unreliable. Returning the JuMP model. Use `inspect(model)` to see the results."
                        return model()

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

function evaluate(prob::Node{LyapunovCertificate})
    !active_model() && error("Searching for a Lyapunov certificate requires numerics")

    vars = filter(node -> !isconstant(node) && !isparameter(node), leaves(prob))

    nonreal = filter(v -> !(v isa Node{R}), vars)

    if !isempty(nonreal)
        error("Problem has variables not in R: $nonreal")
    end

    basis = collect(Node{R}, vars)

    @info "Basis: $basis"

    con, performance, rate = arguments(prob)

    x, x₊ = state(prob)

    @info "State: $x"

    cons = filter(c -> !(symtype(c) <: Transition), arguments(con))

    X  = evaluate.(as_matrix(basis => x))
    X₊ = evaluate.(as_matrix(basis => x₊))
    P  = evaluate.(as_matrix(basis => performance))

    # number of states
    n = length(x)

    # Lyapunov candidate parameters
    θ = JuMP.@variable(model(), [1:n])

    @show X
    @show X₊

    # Lyapunov function
    V  = X' * θ
    V₊ = X₊' * θ

    # negative linear forms
    negative!(basis, cons, P - V)
    negative!(basis, cons, V₊ - rate * V)

    JuMP.optimize!(model())

    if verbose
        @info "Rate: $ρ, Termination status: $(JuMP.termination_status(model()))"
    end

    return JuMP.is_solved_and_feasible(model())
end

"""
    negative!(model, vars, cons, f)

Constrains a given linear form `f` with variables `vars` to be negative by adding nonnegative terms associated with the constraints `cons` and then setting the result to zero in the optimization `model`.
"""
function negative!(basis, cons, f)
    for con ∈ cons
        @show expression(con)
        # f += as_matrix( basis => multiplier(con) ⋅ expression(con) )
        e = expression(con)
        λ = multiplier(con)
        T = symtype(con)

        if T <: Equality || T <: LessThanOrEqualTo
            f += λ ⋅ evaluate.(as_matrix(basis => e))
        elseif T <: PositiveSemidefinite
            f += λ ⋅ evaluate.(as_matrix(basis => e))
        else
            error("Unknown constraint type $T")
        end
    end
    JuMP.@constraint(model(), f .== 0 )
end

multiplier(::Node{Equality{R}}) = JuMP.@variable(model())

function multiplier(::Node{LessThanOrEqualTo{R}})
    JuMP.@variable(model(), Nonnegative)
end

function multiplier(c::Node{PositiveSemidefinite})
    A = arguments(c)[1]
    n = size(A,1)
    JuMP.@variable(model(), [1:n, 1:n], PSD)
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