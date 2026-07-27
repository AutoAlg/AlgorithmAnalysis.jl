# ------------------------------------------------------
# NUMERIC
# ------------------------------------------------------

export with_numerics, evaluate, feasible, model
export inspect, inspect_constraints

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

function with_parameters(code::Function, params::Dict)
    return Base.ScopedValues.with(code, PARAMETERS => params)
end

function with_numerics(code::Function; T::DataType=Float64, model_constructor::Function=() -> default_model(T), parameters::Dict=Dict())
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
    vecs = []
    if iscall(x) && isequal(symtype(x), Optimization)
        all_vecs = find_nodes(v -> symtype(v) <: VectorSpace, x)
        vecs = [v for v in all_vecs if issym(v)]
        unique!(vecs)
    end

    eval_node = function (node)
        !(node isa BasicSymbolic) && return node

        if iscall(node) && isequal(operation(node), outer)
            vr, vl = arguments(node)
            M = zeros(Float64, length(vecs), length(vecs))

            if iszero(vr) || iszero(vl)
                return M
            end

            ir = findfirst(v -> isequal(v, vr), vecs)
            il = findfirst(v -> isequal(v, vl), vecs)

            (ir === nothing || il === nothing) && error("vector matrix mapping failed for [$vr] and [$vl]")

            M[ir, il] = 1.0
            return M
        end

        if iscall(node) && isequal(symtype(node), R)
            isequal(operation(node), zero) && return 0.0
            isequal(operation(node), one) && return 1.0
        end

        if node ∈ keys(parameters())
            verbose() && @info "Object $node is a parameter"
            return parameters()[node]
        end

        if active_model() && has_id(node) && id(node) ∈ keys(JuMP.object_dictionary(model()))
            verbose() && @info "Object $node exists in the JuMP model"
            val = model()[id(node)]
            return JuMP.has_values(model()) ? JuMP.value(val) : val
        end

        if active_model() && !iscall(node)
            T = symtype(node)
            sym = id(node)
            if isequal(T, R)
                model()[sym] = JuMP.@variable(model(), base_name = string(sym))
                verbose() && @info "Object $node is in R, so initializing in JuMP as $(model()[sym])"
                return model()[sym]
            elseif isequal(T, Sⁿ)
                n = length(vecs)
                model()[sym] = JuMP.@variable(model(), [1:n, 1:n], Symmetric, base_name = string(sym))
                verbose() && @info "Object $node is in Sⁿ, so initializing in JuMP as $(model()[sym])"
                return model()[sym]
            end
        end

        if iscall(node)
            op = operation(node)
            args = arguments(node)
            T = symtype(node)

            if isequal(op, constant)
                return args[1]
            elseif isequal(op, +)
                contains_matrix_operand::Bool = any(operand -> operand isa AbstractArray, args)
                if contains_matrix_operand
                    first_matrix_operand::AbstractArray = first(filter(operand -> operand isa AbstractArray, args))
                    matrix_dimension0::Int64 = size(first_matrix_operand, 1)
                    return reduce(+, map(operand -> operand isa AbstractArray ? operand : operand * la.I(matrix_dimension0), args))
                else
                    return +(args...)
                end
            elseif isequal(op, -)
                if length(args) == 2
                    left_operand::Any = args[1]
                    right_operand::Any = args[2]
                    if left_operand isa AbstractArray && !(right_operand isa AbstractArray)
                        matrix_dimension1::Int64 = size(left_operand, 1)
                        return left_operand - (right_operand * la.I(matrix_dimension1))
                    elseif !(left_operand isa AbstractArray) && right_operand isa AbstractArray
                        matrix_dimension2::Int64 = size(right_operand, 1)
                        return (left_operand * la.I(matrix_dimension2)) - right_operand
                    end
                end
                return -(args...)
            elseif op ∈ [*, /]
                return op(args...)
            elseif isequal(op, tr)
                verbose() && @info "Evaluating the trace of $(args[1])"
                return tr(args[1])
            elseif isequal(T, Sⁿ)
                return mat(node)
            end
        end

        T = symtype(node)

        if T <: Constraint && isequal(operation(node), ∧)
            return arguments(node)
        end

        if active_model()
            if T <: Equality
                lhs, rhs = arguments(node)
                verbose() && @info "Enforcing equality constraint $lhs = $rhs"
                return isequal(T, Equality{R}) ? JuMP.@constraint(model(), lhs == rhs) : JuMP.@constraint(model(), lhs .== rhs)

            elseif T <: LessThanOrEqualTo{R}
                lhs, rhs = arguments(node)
                verbose() && @info "Enforcing inequality constraint $lhs ≤ $rhs"
                return JuMP.@constraint(model(), lhs ≤ rhs)

            elseif T <: PositiveSemidefinite
                A = arguments(node)[1]
                ϵ = arguments(node)[2]
                verbose() && @info "Enforcing positive definite constraint $ϵ ⪯ $A"

                function sanitize_jump_expr(val)
                    if val isa JuMP.GenericQuadExpr
                        JuMP.drop_zeros!(val)
                        if isempty(val.terms)
                            return val.aff
                        else
                            error("Strictly non-linear (bilinear/quadratic) term detected in LMI matrix. Offending term: $val")
                        end
                    elseif val isa AbstractArray
                        return map(sanitize_jump_expr, val)
                    end
                    return val
                end

                eval_A = map(sanitize_jump_expr, A)
                has_blocks = any(x -> x isa AbstractMatrix, eval_A)
                T_type = typeof(model()).parameters[1]
                AffExprType = JuMP.GenericAffExpr{T_type,JuMP.GenericVariableRef{T_type}}

                if has_blocks
                    block_dim = 1
                    for x in eval_A
                        if x isa AbstractMatrix
                            block_dim = size(x, 1)
                            break
                        end
                    end

                    flat_dim = size(eval_A, 1) * block_dim
                    flat_AA = Matrix{AffExprType}(undef, flat_dim, flat_dim)

                    for i in 1:size(eval_A, 1)
                        for j in 1:size(eval_A, 2)
                            elem = eval_A[i, j]
                            row_start = (i-1)*block_dim + 1
                            row_end = i*block_dim
                            col_start = (j-1)*block_dim + 1
                            col_end = j*block_dim

                            if elem isa AbstractMatrix
                                flat_AA[row_start:row_end, col_start:col_end] = convert.(AffExprType, elem)
                            else
                                flat_AA[row_start:row_end, col_start:col_end] = convert.(AffExprType, elem * la.I(block_dim))
                            end
                        end
                    end
                    AA = flat_AA
                else
                    AA = convert.(AffExprType, eval_A)
                end

                symmetric_AA = la.Symmetric(AA)
                matrix_dimension = size(symmetric_AA, 1)

                if iszero(ϵ)
                    return JuMP.@constraint(model(), symmetric_AA in JuMP.PSDCone())
                else
                    return JuMP.@constraint(model(), symmetric_AA - (ϵ * la.I(matrix_dimension)) in JuMP.PSDCone())
                end
            elseif isequal(T, Optimization)
                obj = objective(node)
                con = constraint(node)
                verbose() && @info "Optimizing $obj subject to $con"

                if is_minimization(node)
                    JuMP.@objective(model(), Min, obj)
                elseif is_maximization(node)
                    JuMP.@objective(model(), Max, obj)
                end

                println("=== DEBUG: JUMP MODEL ===")
                print(model())
                println("=========================")

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
            end
        end
        return node
    end

    return postwalk_with_operators(eval_node, x)
end


function inspect(model::JuMP.Model, tolerance=1e-6)
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
                display_name = isempty(c_name) ? "[unnamed PSD Constraint]" : c_name
                raw_data = JuMP.value.(JuMP.constraint_object(con).func)
                matrix_val = unpack_triangular_vector(raw_data)
                evals = la.eigen(la.Symmetric(matrix_val)).values
                min_eval = minimum(evals)

                display(matrix_val)

                if min_eval < tolerance
                    println("❌ VIOLATION in PSD Constraint: $display_name")
                    println("   Minimum Eigenvalue: $min_eval (Should be ≥ 0)")
                    println("   Full Spectrum: ", evals)
                else
                    println("✅ PSD Constraint Satisfied: $display_name")
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