# ------------------------------------------------------
# LYAPUNOV ANALYSIS
# ------------------------------------------------------

export state

# Override the forward declaration from transformation.jl
lyapunov_transformation_is_applicable(::Node{LyapunovCertificate}) = true

function is_scalar_constant(node::Node{R})
    if !iscall(node)
        return false
    end
    op = operation(node)
    return isequal(op, constant) || isequal(op, zero) || isequal(op, one)
end

function unique_by_tostring(nodes)
    unique_nodes = Dict{String,Any}()
    for node in nodes
        key = tostring(node)
        if !haskey(unique_nodes, key)
            unique_nodes[key] = node
        end
    end
    return [unique_nodes[k] for k in sort(collect(keys(unique_nodes)))]
end

function collect_scalar_subexpressions(expr)
    nodes = find_nodes(n -> (n isa Node) && isequal(symtype(n), R), expr)
    return collect(nodes)
end

function lyapunov_basis_candidates(perf::Node{R}, oracle_con::Node{<:Prop})
    basis = Any[perf]

    for node in collect_scalar_subexpressions(perf)
        node isa Node{R} || continue
        is_scalar_constant(node) && continue
        push!(basis, node)
    end

    for con in oracle_con
        T = symtype(con)
        if T <: LessThanOrEqualTo{R} || T <: Equality{R}
            lhs, rhs = arguments(con)
            for expr in (lhs, rhs, lhs - rhs)
                expr isa Node{R} || continue
                for node in collect_scalar_subexpressions(expr)
                    node isa Node{R} || continue
                    is_scalar_constant(node) && continue
                    push!(basis, node)
                end
            end
        end
    end

    return unique_by_tostring(basis)
end

function lyapunov_certificate_transformation_is_applicable(opt::Node{Optimization})
    if convex_interpolation_is_applicable(opt)
        return false
    elseif smooth_convex_interpolation_is_applicable(opt)
        return false
    elseif gram_transformation_is_applicable(opt)
        return false
    end

    return any(c -> iscall(c) && isequal(operation(c), lyapunov_certificate), constraint(opt))
end

function scalar_constraints_without_marker(opt::Node{Optimization})
    marker = nothing
    remaining = Any[]

    for con in constraint(opt)
        if iscall(con) && isequal(operation(con), lyapunov_certificate)
            marker === nothing || error("Multiple Lyapunov certificate markers found")
            marker = con
        else
            push!(remaining, con)
        end
    end

    marker === nothing && error("Lyapunov certificate marker was not found")
    return marker, remaining
end

function split_scalar_constraints(cons)
    inequalities = Node{R}[]
    equalities = Node{R}[]
    passthrough = Any[]

    for con in cons
        T = symtype(con)
        if T <: LessThanOrEqualTo{R}
            lhs, rhs = arguments(con)
            push!(inequalities, lhs - rhs)
        elseif T <: Equality{R}
            lhs, rhs = arguments(con)
            push!(equalities, lhs - rhs)
        else
            push!(passthrough, con)
        end
    end

    return inequalities, equalities, passthrough
end

function scalar_leaf_nodes(expr)
    nodes = find_nodes(
        n -> (n isa Node) && !iscall(n) && isequal(symtype(n), R),
        expr,
    )
    return collect(nodes)
end

function collect_lyapunov_atoms(exprs)
    atoms = Set{Node{R}}()
    for expr in exprs
        for node in scalar_leaf_nodes(expr)
            push!(atoms, node)
        end
    end
    sorted_atoms = sort(collect(atoms), by = tostring)
    return sorted_atoms
end

function new_scalar_symbol(prefix::String, index::Int)
    sym = Symbol(prefix, index)
    return set_id(Sym{R}(sym), sym)
end

function contains_any_atom(expr::Node{R}, atom_set::Set{Node{R}})
    if expr in atom_set
        return true
    end
    if !iscall(expr)
        return false
    end
    for arg in arguments(expr)
        if arg isa Node{R} && contains_any_atom(arg, atom_set)
            return true
        end
    end
    return false
end

function scale_affine_form(coeffs::Dict{Node{R},Node{R}}, factor::Node{R})
    out = Dict{Node{R},Node{R}}()
    for (k, v) in coeffs
        out[k] = factor * v
    end
    return out
end

function add_affine_forms(a::Dict{Node{R},Node{R}}, b::Dict{Node{R},Node{R}})
    out = Dict{Node{R},Node{R}}()
    for (k, v) in a
        out[k] = v
    end
    for (k, v) in b
        out[k] = haskey(out, k) ? out[k] + v : v
    end
    return out
end

function affine_decompose(expr::Node{R}, atom_set::Set{Node{R}})
    if expr in atom_set
        return zero(R), Dict(expr => one(R)), true
    end

    if !iscall(expr)
        return expr, Dict{Node{R},Node{R}}(), true
    end

    op = operation(expr)
    args = arguments(expr)

    if isequal(op, constant)
        return expr, Dict{Node{R},Node{R}}(), true
    end

    if isequal(op, +)
        c = zero(R)
        coeffs = Dict{Node{R},Node{R}}()
        for arg in args
            arg isa Node{R} || return zero(R), Dict{Node{R},Node{R}}(), false
            ci, ai, ok = affine_decompose(arg, atom_set)
            ok || return zero(R), Dict{Node{R},Node{R}}(), false
            c = c + ci
            coeffs = add_affine_forms(coeffs, ai)
        end
        return c, coeffs, true
    elseif isequal(op, -)
        if length(args) == 1
            arg = args[1]
            arg isa Node{R} || return zero(R), Dict{Node{R},Node{R}}(), false
            c, coeffs, ok = affine_decompose(arg, atom_set)
            ok || return zero(R), Dict{Node{R},Node{R}}(), false
            return -c, scale_affine_form(coeffs, -one(R)), true
        elseif length(args) == 2
            lhs, rhs = args
            lhs isa Node{R} || return zero(R), Dict{Node{R},Node{R}}(), false
            rhs isa Node{R} || return zero(R), Dict{Node{R},Node{R}}(), false
            c1, a1, ok1 = affine_decompose(lhs, atom_set)
            c2, a2, ok2 = affine_decompose(rhs, atom_set)
            (ok1 && ok2) || return zero(R), Dict{Node{R},Node{R}}(), false
            return c1 - c2, add_affine_forms(a1, scale_affine_form(a2, -one(R))), true
        end
    elseif isequal(op, *)
        length(args) == 2 || return zero(R), Dict{Node{R},Node{R}}(), false
        a, b = args
        (a isa Node{R} && b isa Node{R}) || return zero(R), Dict{Node{R},Node{R}}(), false
        contains_a = contains_any_atom(a, atom_set)
        contains_b = contains_any_atom(b, atom_set)

        if contains_a && contains_b
            return zero(R), Dict{Node{R},Node{R}}(), false
        elseif contains_a
            c, coeffs, ok = affine_decompose(a, atom_set)
            ok || return zero(R), Dict{Node{R},Node{R}}(), false
            return b * c, scale_affine_form(coeffs, b), true
        elseif contains_b
            c, coeffs, ok = affine_decompose(b, atom_set)
            ok || return zero(R), Dict{Node{R},Node{R}}(), false
            return a * c, scale_affine_form(coeffs, a), true
        else
            return a * b, Dict{Node{R},Node{R}}(), true
        end
    elseif isequal(op, /)
        length(args) == 2 || return zero(R), Dict{Node{R},Node{R}}(), false
        a, b = args
        (a isa Node{R} && b isa Node{R}) || return zero(R), Dict{Node{R},Node{R}}(), false
        contains_any_atom(b, atom_set) && return zero(R), Dict{Node{R},Node{R}}(), false
        c, coeffs, ok = affine_decompose(a, atom_set)
        ok || return zero(R), Dict{Node{R},Node{R}}(), false
        return c / b, scale_affine_form(coeffs, one(R) / b), true
    end

    return zero(R), Dict{Node{R},Node{R}}(), false
end

function affine_certificate_constraints(expr::Node{R}, atoms::Vector{Node{R}}; require_nonnegative_constant::Bool)
    atom_set = Set(atoms)
    constant_term, coeffs, ok = affine_decompose(expr, atom_set)
    ok || error("Lyapunov certificate expression is not affine in extracted scalar atoms")

    cons = Any[]
    for atom in atoms
        coeff = get(coeffs, atom, zero(R))
        push!(cons, coeff == zero(R))
    end

    if require_nonnegative_constant
        push!(cons, zero(R) ≤ constant_term)
    else
        push!(cons, constant_term == zero(R))
    end

    return cons
end

function lyapunov_certificate_transformation(opt::Node{Optimization})
    marker, base_constraints = scalar_constraints_without_marker(opt)
    marker_args = arguments(marker)
    if length(marker_args) == 3
        perf, perf_next, rate = marker_args
        basis_now = Any[perf]
        basis_next = Any[perf_next]
    elseif length(marker_args) == 5
        perf, perf_next, rate, basis_now, basis_next = marker_args
    else
        error("Lyapunov certificate marker has unexpected arity: $(length(marker_args))")
    end

    inequalities, equalities, passthrough = split_scalar_constraints(base_constraints)

    length(basis_now) == length(basis_next) || error("Lyapunov basis and next-basis lengths do not match")

    basis_now = [b for b in basis_now if b isa Node{R}]
    basis_next = [b for b in basis_next if b isa Node{R}]

    length(basis_now) == length(basis_next) || error("Lyapunov basis filtering changed basis lengths")

    atoms = collect_lyapunov_atoms(vcat([perf, perf_next], basis_now, basis_next, inequalities, equalities))

    if isempty(atoms)
        @warn "Lyapunov: no scalar atoms extracted for template basis; certificate may be overly restrictive"
    end

    v = [new_scalar_symbol("lyap_v_", i) for i in eachindex(basis_now)]
    λ = [new_scalar_symbol("lyap_lambda_", i) for i in eachindex(inequalities)]
    μ = [new_scalar_symbol("lyap_mu_", i) for i in eachindex(inequalities)]
    ν = [new_scalar_symbol("lyap_nu_", i) for i in eachindex(equalities)]
    ω = [new_scalar_symbol("lyap_omega_", i) for i in eachindex(equalities)]

    V_now = zero(R)
    V_next = zero(R)
    for i in eachindex(basis_now)
        V_now = V_now + v[i] * basis_now[i]
        V_next = V_next + v[i] * basis_next[i]
    end

    perf_gap = V_now - perf
    dec_gap = rate * V_now - V_next

    for i in eachindex(inequalities)
        perf_gap = perf_gap - λ[i] * inequalities[i]
        dec_gap = dec_gap - μ[i] * inequalities[i]
    end

    for i in eachindex(equalities)
        perf_gap = perf_gap - ν[i] * equalities[i]
        dec_gap = dec_gap - ω[i] * equalities[i]
    end

    cert_cons = Any[]
    append!(cert_cons, affine_certificate_constraints(perf_gap, atoms; require_nonnegative_constant = true))
    append!(cert_cons, affine_certificate_constraints(dec_gap, atoms; require_nonnegative_constant = true))

    for i in eachindex(λ)
        push!(cert_cons, zero(R) ≤ λ[i])
        push!(cert_cons, zero(R) ≤ μ[i])
    end

    all_constraints = vcat(passthrough, cert_cons)

    combined = isempty(all_constraints) ? satisfied() : foldl(∧, all_constraints)
    return feasible(combined)
end

"""
    lyapunov_transformation(prob::Node{LyapunovCertificate})

Transform a Lyapunov certification problem into a fixed-rate feasibility program.

Stage 1:
1. Compute `perf_next` = performance measure at the next state via `apply_transition`.
2. Return `feasible(oracle_con ∧ lyapunov_certificate(perf, perf_next, rate))`.

Stage 2 (triggered later in `simplify` after interpolation and Gram transformation):
1. Replace the certificate marker with affine coefficient-matching constraints.
2. Introduce Lyapunov and multiplier decision variables.
3. Enforce feasibility conditions for `V(x) ≥ P(x)` and `V(x⁺) ≤ rate * V(x)`.
"""
function lyapunov_transformation(prob::Node{LyapunovCertificate})
    con, perf, rate = arguments(prob)

    trans = transitions(con)

    perf_next  = apply_transitions(trans, perf)
    basis      = lyapunov_basis_candidates(perf, con)
    basis_next = map(expr -> apply_transitions(trans, expr), basis)
    state_strs = join([tostring(arguments(t)[1]) for t in trans], ", ")
    @info "Lyapunov: building parameterized certificate for rate ≤ $rate (state variables: [$state_strs], basis size: $(length(basis)))"

    # Stage 1: inject a marker. Interpolation + Gram simplify this into scalar space.
    # Stage 2: lyapunov_certificate_transformation converts marker into feasibility constraints.
    cert_marker = Term{LyapunovCertificate}(nothing, [perf, perf_next, rate, basis, basis_next])
    return feasible(con ∧ cert_marker)
end

function state(prob::Node{LyapunovCertificate})
    con = arguments(prob)[1]
    ts = transitions(con)
    if isnothing(ts)
        return nothing, nothing
    end
    states = [ arguments(t)[1] for t ∈ ts ]
    next_states = [ next(state, prob) for state ∈ states ]

    return states, next_states
end
