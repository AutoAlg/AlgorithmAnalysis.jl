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
        println(JuMP.name(var), JuMP.value(var))
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
