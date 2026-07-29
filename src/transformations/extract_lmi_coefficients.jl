export extract_lmi_coefficients

function expand_bilinear(v1::BasicSymbolic, P::BasicSymbolic, v2::BasicSymbolic)::BasicSymbolic{R}
    if iszero(v1) || iszero(v2)
        return zero(R)
    end

    if iscall(v1)
        op = operation(v1)
        args = arguments(v1)
        if isequal(op, +)
            return reduce(+, map(v -> expand_bilinear(v, P, v2), args))
        elseif isequal(op, -)
            if length(args) == 2
                return expand_bilinear(args[1], P, v2) - expand_bilinear(args[2], P, v2)
            else
                return -expand_bilinear(args[1], P, v2)
            end
        elseif isequal(op, *)
            if is_scalar(args[1])
                return args[1] * expand_bilinear(args[2], P, v2)
            elseif is_scalar(args[2])
                return args[2] * expand_bilinear(args[1], P, v2)
            end
        end
    end

    if iscall(v2)
        op = operation(v2)
        args = arguments(v2)
        if isequal(op, +)
            return reduce(+, map(v -> expand_bilinear(v1, P, v), args))
        elseif isequal(op, -)
            if length(args) == 2
                return expand_bilinear(v1, P, args[1]) - expand_bilinear(v1, P, args[2])
            else
                return -expand_bilinear(v1, P, args[1])
            end
        elseif isequal(op, *)
            if is_scalar(args[1])
                return args[1] * expand_bilinear(v1, P, args[2])
            elseif is_scalar(args[2])
                return args[2] * expand_bilinear(v1, P, args[1])
            end
        end
    end

    return Term{R}(tr, [Term{symtype(P)}(*, [P, Term{symtype(P)}(outer, [v2, v1])])])
end

struct CoefficientExtractorState
    basis_vectors::Vector{BasicSymbolic}
    scalar_variables::Vector{BasicSymbolic}
end
function extract_lmi_coefficients(
    optimization_problem::BasicSymbolic{Optimization}
)::BasicSymbolic{Optimization}
    flattened_constraints::Vector{Any} = flatten_constraints(constraint(optimization_problem))
    target_inequality_index::Union{Int,Nothing} = findfirst(c -> iscall(c) && symtype(c) <: LessThanOrEqualTo, flattened_constraints)

    if target_inequality_index === nothing
        return optimization_problem
    end

    target_inequality::BasicSymbolic{<:Constraint} = flattened_constraints[target_inequality_index]
    left_hand_side::BasicSymbolic = arguments(target_inequality)[1]
    right_hand_side::BasicSymbolic = arguments(target_inequality)[2]

    normalized_expression::BasicSymbolic = right_hand_side - left_hand_side


    flatten_p_rule::Any = @rule adjoint(~v1)(~P * ~v2) => expand_bilinear(~v1, ~P, ~v2)
    flatten_rule::Any = @rule adjoint(~v1)(~v2) => flatten_inner_product(~v1, ~v2)

    canonicalized_expression::BasicSymbolic = rewrite(
        normalized_expression,
        [flatten_p_rule, flatten_rule]
    )

    all_vectors::Set{Any} = find_nodes(x -> symtype(x) <: VectorSpace, normalized_expression)
    basis_vectors::Vector{BasicSymbolic} = unique!(filter(issym, collect(all_vectors)))
    basis_dimension::Int = length(basis_vectors)

    all_r_symbols::Vector{Any} = unique!(filter(issym, collect(find_nodes(x -> isequal(symtype(x), R), canonicalized_expression))))

    # Identify scalar function evaluation symbols (e.g., var"f(x)")
    scalar_evaluation_symbols::Vector{BasicSymbolic} = filter(s -> contains(string(s), "(") && !contains(string(s), "⟨") && !contains(string(s), "‖"), all_r_symbols)

    # Identify all possible inner product symbols from the basis
    inner_product_symbols::Vector{BasicSymbolic} = BasicSymbolic[]
    for v1 in basis_vectors
        for v2 in basis_vectors
            push!(inner_product_symbols, flatten_inner_product(v1, v2))
        end
    end
    unique!(inner_product_symbols)

    # 1. Extract LMI Matrix Coefficients (Quadratic terms)
    lmi_matrix::Matrix{BasicSymbolic{R}} = Matrix{BasicSymbolic{R}}(undef, basis_dimension, basis_dimension)
    for i::Int in 1:basis_dimension
        for j::Int in 1:basis_dimension
            lmi_matrix[i, j] = extract_bilinear_coefficient(
                canonicalized_expression,
                basis_vectors[i],
                basis_vectors[j],
                scalar_evaluation_symbols,
                inner_product_symbols
            )
        end
    end

    psd_constraint::BasicSymbolic{<:Constraint} = Term{PositiveSemidefinite}(
        ⪰,
        vcat([Sⁿ(lmi_matrix), zero(R)], basis_vectors)
    )
    deleteat!(flattened_constraints, target_inequality_index)
    push!(flattened_constraints, psd_constraint)

    # 2. Extract Scalar Equality Constraints (Linear terms)
    for scalar_sym in scalar_evaluation_symbols
        scalar_coeff = extract_scalar_coefficient(
            canonicalized_expression,
            scalar_sym,
            scalar_evaluation_symbols,
            inner_product_symbols
        )
        # Only add the constraint if the coefficient isn't trivially zero
        if !isequal(scalar_coeff, zero(R))
            push!(flattened_constraints, scalar_coeff == zero(R))
        end
    end

    master_constraint::BasicSymbolic{<:Constraint} = satisfied()
    for con::BasicSymbolic{<:Constraint} in flattened_constraints
        master_constraint = master_constraint ∧ con
    end

    if is_feasibility(optimization_problem)
        return Term{Optimization}(operation(optimization_problem), [master_constraint])
    end

    return Term{Optimization}(
        operation(optimization_problem),
        [objective(optimization_problem), master_constraint]
    )
end

function extract_bilinear_coefficient(
    canonicalized_expression::BasicSymbolic,
    first_basis_vector::BasicSymbolic,
    second_basis_vector::BasicSymbolic,
    scalar_evaluation_symbols::Vector{BasicSymbolic},
    all_inner_product_symbols::Vector{BasicSymbolic}
)::BasicSymbolic{R}
    substitution_rules::Vector{Any} = Vector{Any}()

    # Zero out all linear scalar evaluations
    for scalar_sym in scalar_evaluation_symbols
        push!(substitution_rules, @rule ~x => zero(R) where isequal(~x, scalar_sym))
    end

    target_symbol_forward::BasicSymbolic = flatten_inner_product(first_basis_vector, second_basis_vector)
    target_symbol_backward::BasicSymbolic = flatten_inner_product(second_basis_vector, first_basis_vector)

    # Substitute inner product symbols
    for ip_sym in all_inner_product_symbols
        is_target::Bool = isequal(ip_sym, target_symbol_forward) || isequal(ip_sym, target_symbol_backward)
        replacement_value::BasicSymbolic{R} = is_target ? one(R) : zero(R)
        push!(substitution_rules, @rule ~x => replacement_value where isequal(~x, ip_sym))
    end

    # Substitute matrix-weighted trace terms
    matrix_weighted_rule = @rule ~t => begin
        if iscall(~t) && isequal(operation(~t), tr)
            args = arguments(~t)
            if length(args) == 1 && iscall(args[1]) && isequal(operation(args[1]), *)
                inner_args = arguments(args[1])
                if length(inner_args) == 2 && iscall(inner_args[2]) && isequal(operation(inner_args[2]), outer)
                    outer_args = arguments(inner_args[2])
                    is_target_forward = isequal(outer_args[1], second_basis_vector) && isequal(outer_args[2], first_basis_vector)
                    is_target_backward = isequal(outer_args[1], first_basis_vector) && isequal(outer_args[2], second_basis_vector)
                    if is_target_forward || is_target_backward
                        return inner_args[1]
                    end
                    return zero(R)
                end
            end
        end
        return nothing
    end
    push!(substitution_rules, matrix_weighted_rule)

    isolated_coefficient_expression::BasicSymbolic = rewrite(canonicalized_expression, substitution_rules)
    expanded_isolated_coefficient::BasicSymbolic = SymbolicUtils.expand(isolated_coefficient_expression)

    if !isequal(first_basis_vector, second_basis_vector)
        expanded_isolated_coefficient = expanded_isolated_coefficient / R(2.0)
    end

    return algebra_simplify(expanded_isolated_coefficient)
end

function extract_scalar_coefficient(
    canonicalized_expression::BasicSymbolic,
    target_scalar_symbol::BasicSymbolic,
    all_scalar_symbols::Vector{BasicSymbolic},
    all_inner_product_symbols::Vector{BasicSymbolic}
)::BasicSymbolic{R}
    substitution_rules::Vector{Any} = Vector{Any}()

    # Zero out all quadratic matrix trace terms
    push!(substitution_rules, @rule ~t => zero(R) where (iscall(~t) && isequal(operation(~t), tr)))

    # Zero out all quadratic inner product symbols
    for ip_sym in all_inner_product_symbols
        push!(substitution_rules, @rule ~x => zero(R) where isequal(~x, ip_sym))
    end

    # Isolate target linear scalar
    for scalar_sym in all_scalar_symbols
        is_target::Bool = isequal(scalar_sym, target_scalar_symbol)
        replacement_value::BasicSymbolic{R} = is_target ? one(R) : zero(R)
        push!(substitution_rules, @rule ~x => replacement_value where isequal(~x, scalar_sym))
    end

    isolated_coefficient_expression::BasicSymbolic = rewrite(canonicalized_expression, substitution_rules)
    expanded_isolated_coefficient::BasicSymbolic = SymbolicUtils.expand(isolated_coefficient_expression)

    return algebra_simplify(expanded_isolated_coefficient)
end
