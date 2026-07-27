export algebra_simplify, pep_simplify, lyap_simplify, find_nodes, find_evaluation_points, replace_node, smooth_convex_interpolation, apply_s_procedure, propagate_constants, extract_lmi_coefficients

using SymbolicUtils
using SymbolicUtils.Rewriters: Chain, Postwalk, Fixpoint

is_vector(x) = symtype(x) <: VectorSpace
is_scalar(x) = symtype(x) <: Field
is_scalar_or_vector(x) = is_scalar(x) || is_vector(x)
is_scalar_and_vector(a, x) = is_scalar(a) && is_vector(x) && isequal(symtype(a), field(x))
are_scalars(a, b) = is_scalar(a) && isequal(symtype(a), symtype(b))
are_vectors(u, v) = is_vector(u) && isequal(symtype(u), symtype(v))

are_vectors(xs...) = all(map(is_vector, xs))
are_scalars(xs...) = all(map(is_scalar, xs))
are_scalars_or_vectors(xs...) = all(map(is_scalar_or_vector, xs))

function add_constraint(opt::BasicSymbolic{T}, con::BasicSymbolic{<:Constraint}) where {T<:Optimization}
    return Term{T}(operation(opt), [objective(opt), constraint(opt) ∧ con])
end

# ------------------------------------------------------
# CONVEX INTERPOLATION
# ------------------------------------------------------

convex_interpolation_is_applicable(::Any) = false

function convex_interpolation_is_applicable(opt::BasicSymbolic{Optimization})
    return !isempty(find_nodes(c -> isequal(symtype(c), Convex), opt))
end

function convex_interpolation(opt::BasicSymbolic{Optimization})

    cvx_cons = find_nodes(c -> isequal(symtype(c), Convex), opt)

    if isempty(cvx_cons)
        error("Optimization problem has no convexity constraints")
    end

    for con ∈ cvx_cons
        f = first(arguments(con))
        opt = convex_interpolation(opt, f)
    end

    return opt
end

function convex_interpolation(opt::BasicSymbolic{Optimization}, f::BasicSymbolic)

    points = find_evaluation_points(f, opt) ∪ find_evaluation_points(f', opt)

    pts = join(tostring.(points), ", ")

    @info "Applying convex interpolation to function $f with evaluation points $pts"

    if isempty(points)
        @info "No points found!"
        return opt
    end

    interp = satisfied()

    for x ∈ points, y ∈ points
        interp = interp ∧ (f(x) ≥ f(y) + f'(y)'(x-y))
    end

    new_opt = replace_node(opt, convex(f), interp)
    new_opt = flatten_evaluations(new_opt, [f, f'])

    return new_opt
end

# ------------------------------------------------------
# SMOOTH CONVEX INTERPOLATION
# ------------------------------------------------------

smooth_convex_interpolation_is_applicable(::Any) = false

function smooth_convex_interpolation_is_applicable(opt::BasicSymbolic{Optimization})
    predicate = function (c)
        isequal(symtype(c), Constraint) && iscall(c) && isequal(operation(c), smooth_convex)
    end
    return !isempty(find_nodes(predicate, opt))
end

function smooth_convex_interpolation(opt::BasicSymbolic{Optimization})::BasicSymbolic{Optimization}

    predicate = (node::Any) -> isequal(symtype(node), Constraint) && iscall(node) && isequal(operation(node), smooth_convex)
    constraints::Set{Any} = find_nodes(predicate, opt)

    if isempty(constraints)
        error("optimization problem has no smooth convexity constraints")
    end

    topt::BasicSymbolic{Optimization} = opt

    for constraint_node::BasicSymbolic{<:Constraint} ∈ constraints
        f = arguments(constraint_node)[1]
        L = arguments(constraint_node)[2]
        topt = smooth_convex_interpolation(topt, f, L)
    end

    return topt
end

function smooth_convex_interpolation(
    opt::BasicSymbolic{Optimization},
    f::BasicSymbolic{FnType{Tuple{V},F,DifferentiableFunctional}},
    L::BasicSymbolic{F}
)::BasicSymbolic{Optimization} where {F<:Field,V<:VectorSpace{F}}

    function_points::Set{BasicSymbolic{V}} = Set(find_evaluation_points(f, opt))
    gradient_points::Set{BasicSymbolic{V}} = Set(find_evaluation_points(f', opt))
    evaluation_points::Set{BasicSymbolic{V}} = function_points ∪ gradient_points

    if isempty(evaluation_points)
        return opt
    end

    all_constraints::BasicSymbolic{<:Constraint} = satisfied()

    for x::BasicSymbolic{V} ∈ evaluation_points
        for y::BasicSymbolic{V} ∈ evaluation_points
            if !isequal(x, y)

                ∇fx::BasicSymbolic{V} = f'(x)
                ∇fy::BasicSymbolic{V} = f'(y)

                c::BasicSymbolic{<:Constraint} = f(x) ≥ f(y) + ∇fy'(x - y) + (one(F) / (2 * L)) * (∇fx - ∇fy)'(∇fx - ∇fy)
                all_constraints = all_constraints ∧ c
            end
        end
    end

    return flatten_evaluations(
        replace_node(
            opt,
            smooth_convex(f, L),
            all_constraints
        ),
        [f, f']
    );
end

# ------------------------------------------------------
# GRAM TRANSFORMATION
# ------------------------------------------------------

export gram_transformation

gram_transformation_is_applicable(::Any) = false

function gram_transformation_is_applicable(opt::BasicSymbolic{Optimization})
    if convex_interpolation_is_applicable(opt)
        return false
    elseif smooth_convex_interpolation_is_applicable(opt)
        return false
    elseif isempty(find_nodes(x -> symtype(x) <: VectorSpace, opt))
        return false
    end
    return true
end

function gram_transformation(opt::BasicSymbolic{Optimization})

    all_vecs = find_nodes(x -> symtype(x) <: VectorSpace, opt)
    vectorspaces = Set(symtype.(all_vecs))

    for vectorspace in vectorspaces
        vecs = [v for v in all_vecs if isequal(symtype(v), vectorspace) && issym(v)]
        vecs = unique!(vecs)

        G = Sⁿ([x'(y) for x in vecs, y in vecs])

        vec_str = join(tostring.(vecs), ", ")

        @info "Applying Gram transformation to vector space $vectorspace with vectors $vec_str"

        opt = add_constraint(opt, G ⪰ 0)

        rule = @rule adjoint(~v1)(~v2) => flatten_inner_product(~v1, ~v2)

        opt = rewrite(opt, [rule])
    end

    return opt
end

function apply_s_procedure(
    optimization_problem::BasicSymbolic{Optimization},
    target_constraint_predicate::Function
)::BasicSymbolic{Optimization}

    all_flattened_constraints::Vector{Any} = flatten_constraints(constraint(optimization_problem))

    identified_targets::Vector{Any} = filter(target_constraint_predicate, all_flattened_constraints)

    if length(identified_targets) != 1
        error("Target constraint predicate did not isolate exactly one constraint")
    end

    target_inequality_constraint::BasicSymbolic{<:Constraint} = convert(BasicSymbolic{<:Constraint}, identified_targets[1])

    domain_inequality_constraints::Vector{BasicSymbolic{<:Constraint}} = BasicSymbolic{<:Constraint}[]
    retained_non_inequality_constraints::Vector{BasicSymbolic{<:Constraint}} = BasicSymbolic{<:Constraint}[]

    for individual_constraint::Any ∈ all_flattened_constraints
        if isequal(individual_constraint, target_inequality_constraint)
            continue
        elseif iscall(individual_constraint) && symtype(individual_constraint) <: LessThanOrEqualTo
            push!(domain_inequality_constraints, convert(BasicSymbolic{<:Constraint}, individual_constraint))
        else
            push!(retained_non_inequality_constraints, convert(BasicSymbolic{<:Constraint}, individual_constraint))
        end
    end

    if isempty(domain_inequality_constraints)
        return optimization_problem
    end

    target_left_hand_side::BasicSymbolic = arguments(target_inequality_constraint)[1]
    target_right_hand_side::BasicSymbolic = arguments(target_inequality_constraint)[2]
    normalized_target_expression::BasicSymbolic = target_left_hand_side - target_right_hand_side

    s_procedure_summation_expression::BasicSymbolic = normalized_target_expression
    lagrange_multiplier_constraints::Vector{BasicSymbolic{<:Constraint}} = BasicSymbolic{<:Constraint}[]

    for (index::Int64, domain_inequality::BasicSymbolic{<:Constraint}) ∈ enumerate(domain_inequality_constraints)

        domain_left_hand_side::BasicSymbolic = arguments(domain_inequality)[1]
        domain_right_hand_side::BasicSymbolic = arguments(domain_inequality)[2]
        normalized_domain_expression::BasicSymbolic = domain_left_hand_side - domain_right_hand_side

        lagrange_multiplier::BasicSymbolic{R} = leaf(Symbol("T_", index), R)

        s_procedure_summation_expression = s_procedure_summation_expression - (lagrange_multiplier * normalized_domain_expression)
        push!(lagrange_multiplier_constraints, lagrange_multiplier ≥ zero(R))
    end

    s_procedure_master_constraint::BasicSymbolic{<:Constraint} = s_procedure_summation_expression ≤ zero(R)

    final_recombined_constraints::BasicSymbolic{<:Constraint} = s_procedure_master_constraint

    for multiplier_constraint::BasicSymbolic{<:Constraint} ∈ lagrange_multiplier_constraints
        final_recombined_constraints = final_recombined_constraints ∧ multiplier_constraint
    end

    for retained_constraint::BasicSymbolic{<:Constraint} ∈ retained_non_inequality_constraints
        final_recombined_constraints = final_recombined_constraints ∧ retained_constraint
    end

    if is_feasibility(optimization_problem)
        return Term{Optimization}(operation(optimization_problem), [final_recombined_constraints])
    end

    return Term{Optimization}(
        operation(optimization_problem),
        [objective(optimization_problem), final_recombined_constraints]
    )
end


function propagate_constants(opt::BasicSymbolic{Optimization})::BasicSymbolic{Optimization}
    all_constraints::Vector{Any} = flatten_constraints(constraint(opt))

    substitution_rules::Vector{Any} = Vector{Any}()
    retained_constraints::Vector{BasicSymbolic{<:Constraint}} = Vector{BasicSymbolic{<:Constraint}}()

    for con::Any ∈ all_constraints
        if iscall(con) && symtype(con) <: Equality
            lhs::BasicSymbolic = arguments(con)[1]
            rhs::BasicSymbolic = arguments(con)[2]

            lhs_is_const::Bool = iscall(lhs) && operation(lhs) ∈ (zero, one, constant)
            rhs_is_const::Bool = iscall(rhs) && operation(rhs) ∈ (zero, one, constant)

            if rhs_is_const && !lhs_is_const
                push!(substitution_rules, @rule(~x => rhs where isequal(~x, lhs)))
                continue
            elseif lhs_is_const && !rhs_is_const
                push!(substitution_rules, @rule(~x => lhs where isequal(~x, rhs)))
                continue
            end
        end
        push!(retained_constraints, convert(BasicSymbolic{<:Constraint}, con))
    end

    isempty(substitution_rules) && return opt

    master_constraint::BasicSymbolic{<:Constraint} = satisfied()
    for con::BasicSymbolic{<:Constraint} ∈ retained_constraints
        substituted_con::BasicSymbolic{<:Constraint} = postwalk_with_operators(Chain(substitution_rules), con)
        master_constraint = master_constraint ∧ substituted_con
    end

    is_feasibility(opt) && return Term{Optimization}(operation(opt), [master_constraint])

    new_obj::BasicSymbolic = postwalk_with_operators(Chain(substitution_rules), objective(opt))
    return Term{Optimization}(operation(opt), [new_obj, master_constraint])
end


const algebra_theory = [
    # TODO: are these needed?
    @rule ~x + ~y => ~x where (iscall(~y) && isequal(operation(~y), zero))
    @rule ~x + ~y => ~y where (iscall(~x) && isequal(operation(~x), zero))
    @rule ~x - ~y => ~x where (iscall(~y) && isequal(operation(~y), zero))
    @rule ~x - ~y => -(~y) where (iscall(~x) && isequal(operation(~x), zero))

    # --------------------------------------------------
    # ADDITIVE IDENTITY
    # --------------------------------------------------
    @rule ~x::is_scalar + ~y => ~x where (iscall(~y) && isequal(operation(~y), zero))
    @rule ~x + ~y::is_scalar => ~y where (iscall(~x) && isequal(operation(~x), zero))

    # --------------------------------------------------
    # ADDITIVE INVERSES & INVOLUTION
    # --------------------------------------------------
    @rule +(~x, -(~x)) => zero(symtype(~x)) where is_scalar_or_vector(~x)
    @rule +(-(~x), ~x) => zero(symtype(~x)) where is_scalar_or_vector(~x)
    @rule -(-(~x)) => ~x where is_scalar_or_vector(~x)

    # --------------------------------------------------
    # SCALAR MULTIPLICATION IDENTITIES
    # --------------------------------------------------
    @rule ~x * ~y => ~y where (is_scalar_and_vector(~x, ~y) && isequal(~x, one(symtype(~x))))
    @rule ~x * ~y => ~y where (are_scalars(~x, ~y) && isequal(~x, one(symtype(~x))))
    @rule ~x * ~y => zero(symtype(~y)) where (is_scalar_and_vector(~x, ~y) && isequal(~x, zero(symtype(~x))))];

const pep_theory = [

    # --------------------------------------------------
    # CONVEX INTERPOLATION
    # --------------------------------------------------
    @rule ~opt => convex_interpolation(~opt) where convex_interpolation_is_applicable(~opt)
    @rule ~opt => smooth_convex_interpolation(~opt) where smooth_convex_interpolation_is_applicable(~opt)


    # --------------------------------------------------
    # GRAM TRANSFORMATION
    # --------------------------------------------------
    @rule ~opt => gram_transformation(~opt) where gram_transformation_is_applicable(~opt)
];

# gram_transformation_is_applicable iff !ssc & convex

const lyap_theory = [
    # TODO: verify that this is applicable, I think it might need to be changed a little
    # @rule ~opt => smooth_convex_interpolation(~opt) where smooth_convex_interpolation_is_applicable(~opt)

    # @rule ~opt => propagate_x_into_xn, litterally rewrite the xns into their coresponding x because of that relational constraint
    # @rule ~opt => s_procedure, collect everything into a single large inequality

    #
    @rule ~opt => gram_transformation(~opt) where gram_transformation_is_applicable(~opt)];

# TODO: maybe split into a seperated pass of [algebra, expand, algebra, gram]?

algebra_simplify = Fixpoint(Postwalk(Chain(algebra_theory)))
pep_simplify = Fixpoint(Postwalk(Chain(vcat(algebra_theory, pep_theory))))

function lyap_simplify(opt::BasicSymbolic{Optimization})
    interop1 = Fixpoint(Postwalk(Chain(algebra_theory)))
    interop2 = Fixpoint(Postwalk(Chain(lyap_theory)))

    interop2(interop1())
end

# eliminate the algebra stuff?

# ask
# í remove algebra, clean up rest? ffe
# other codebase cleanups

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
