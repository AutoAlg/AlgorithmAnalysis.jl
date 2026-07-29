export apply_s_procedure_to_single_constraint

function apply_s_procedure_to_single_constraint(opt::BasicSymbolic{Optimization},
    target_predicate::Function
)::BasicSymbolic{Optimization}

    all_constraints::Vector{BasicSymbolic{<:Constraint}} = get_all_constraints_of_optimization(opt)
    maybe_targets::Vector{BasicSymbolic{<:Constraint}} = filter(target_predicate, all_constraints)

    @assert length(maybe_targets) == 1 "Invalid number of passing constraints for S-Procedure"

    target_constraint::BasicSymbolic{<:Constraint} = convert(BasicSymbolic{<:Constraint}, maybe_targets[1])

    @info "Identified $target_constraint as the S-procedure target"

    scalar_constraints::Vector{BasicSymbolic{<:Constraint}} = BasicSymbolic{<:Constraint}[]
    non_scalar_constraints::Vector{BasicSymbolic{<:Constraint}} = BasicSymbolic{<:Constraint}[]

    for individual_constraint::Any ∈ all_constraints
        if isequal(individual_constraint, target_constraint)
            continue
        elseif iscall(individual_constraint) && symtype(individual_constraint) <: LessThanOrEqualTo
            push!(scalar_constraints, convert(BasicSymbolic{<:Constraint}, individual_constraint))
        else
            push!(non_scalar_constraints, convert(BasicSymbolic{<:Constraint}, individual_constraint))
        end
    end

    if isempty(scalar_constraints)
        return opt
    end

    for sc in scalar_constraints
        @info "Identified $sc for S-procedure"
    end

    target_lhs::BasicSymbolic = arguments(target_constraint)[1]
    target_rhs::BasicSymbolic = arguments(target_constraint)[2]

    s_procedure_working_expression::BasicSymbolic = target_lhs - target_rhs
    multipliers::Vector{BasicSymbolic{<:Constraint}} = BasicSymbolic{<:Constraint}[]

    for (index::Int64, scalar_constraint::BasicSymbolic{<:Constraint}) ∈ enumerate(scalar_constraints)
        scalar_lhs::BasicSymbolic = arguments(scalar_constraint)[1]
        scalar_rhs::BasicSymbolic = arguments(scalar_constraint)[2]

        T_n::BasicSymbolic{R} = leaf(Symbol("T_", index), R)
        push!(multipliers, T_n ≥ zero(R))

        s_procedure_working_expression = s_procedure_working_expression - (T_n * (scalar_lhs - scalar_rhs))
    end

    output_constraints::BasicSymbolic{<:Constraint} = s_procedure_working_expression ≤ zero(R)

    for multiplier_constraint::BasicSymbolic{<:Constraint} ∈ multipliers
        output_constraints = output_constraints ∧ multiplier_constraint
    end

    for non_scalar_constraint::BasicSymbolic{<:Constraint} ∈ non_scalar_constraints
        output_constraints = output_constraints ∧ non_scalar_constraint
    end

    if is_feasibility(opt)
        return Term{Optimization}(operation(opt), [output_constraints])
    end

    return Term{Optimization}(
        operation(opt),
        [objective(opt), output_constraints]
    )
end
