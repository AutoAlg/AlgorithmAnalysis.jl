export propagate_constants

# Takes in a an optimization problem and finds all constraints in the form of
# (expression == constant) and replaces all instances of that expression with
# that constant
function propagate_constants(opt::BasicSymbolic{Optimization})::BasicSymbolic{Optimization}
    all_constraints::Vector{BasicSymbolic{<:Constraint}} = get_all_constraints_of_optimization(opt)

    replacement_rules::Vector{SymbolicUtils.Rule} = Vector{SymbolicUtils.Rule}()
    constraints_without_constants::Vector{BasicSymbolic{<:Constraint}} = Vector{BasicSymbolic{<:Constraint}}()

    for c::BasicSymbolic{<:Constraint} ∈ all_constraints
        if iscall(c) && symtype(c) <: Equality # constraints of the form x == y
            @info "Identified constraint against constant $c"

            lhs::BasicSymbolic = arguments(c)[1]
            rhs::BasicSymbolic = arguments(c)[2]

            is_lhs_a_constant::Bool = iscall(lhs) && operation(lhs) ∈ (zero, one, constant)
            is_rhs_a_constant::Bool = iscall(rhs) && operation(rhs) ∈ (zero, one, constant)

            if is_rhs_a_constant && !is_lhs_a_constant
                push!(replacement_rules, @rule(~x => rhs where isequal(~x, lhs)))
                continue
            elseif is_lhs_a_constant && !is_rhs_a_constant
                push!(replacement_rules, @rule(~x => lhs where isequal(~x, rhs)))
                continue
            else
                @warn "constant == constant style constraint $lhs and $rhs"
            end
        else
            push!(constraints_without_constants, convert(BasicSymbolic{<:Constraint}, c))
        end
    end

    if isempty(replacement_rules)
        return opt
    end

    working_output_constraint::BasicSymbolic{<:Constraint} = satisfied()
    for c::BasicSymbolic{<:Constraint} ∈ constraints_without_constants
        # take c, apply all of the constant subsitution rules and form it back as expected
        working_output_constraint = working_output_constraint ∧ rewrite(c, replacement_rules)
    end

    if (is_feasibility(opt))
        return Term{Optimization}(operation(opt), [working_output_constraint])
    end

    new_obj::BasicSymbolic = rewrite(objective(opt), replacement_rules)
    return Term{Optimization}(operation(opt), [new_obj, working_output_constraint])
end

