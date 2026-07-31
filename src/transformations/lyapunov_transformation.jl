# ------------------------------------------------------
# LYAPUNOV TRANSFORMATION
# ------------------------------------------------------

export lyapunov_transformation

lyapunov_transformation_is_applicable(::Any) = false

function lyapunov_transformation_is_applicable(node::Node{LyapunovCertificate})
    if convex_interpolation_is_applicable(node)
        return false
    elseif smooth_convex_interpolation_is_applicable(node)
        return false
    elseif sector_bound_is_applicable(node)
        return false
    elseif gram_transformation_is_applicable(node)
        return false
    end
    return true
end

function lyapunov_transformation(prob::Node{LyapunovCertificate})
    
    con, perf, ρ = constraint(prob), performance(prob), rate(prob)

    @info "Applying Lyapunov transformation to performance measure $performance with rate $ρ"

    vars = filter(node -> !is_constant(node) && !is_parameter(node), leaves(prob))

    nonreal = filter(v -> !(v isa Node{R}), vars)

    if !isempty(nonreal)
        error("Problem has variables not in R: $nonreal\nConsider first simplifying the problem.")
    end

    basis = collect(Node{R}, vars)

    x, x₊ = state(prob)

    # number of states
    n = length(x)

    ctx = Set{Symbol}()

    if isnothing(ρ)
        sym = get_safe_symbol(:ρ, ctx)
        ρ = leaf(R, sym)
        push!(ctx, sym)
        bisect_rate = true
    else
        bisect_rate = false
    end

    # Lyapunov candidate parameters
    θ = Node{R}[]
    for _ in 1:n
        sym = get_safe_symbol(:θ, ctx, force_subscript = true)
        push!(θ, leaf(R, sym))
        push!(ctx, sym)
    end
    
    # Lyapunov candidate
    V  = θ ⋅ x
    V₊ = θ ⋅ x₊

    L₁, c₁, ctx = s_procedure(con, ctx, perf - V)
    L₂, c₂, ctx = s_procedure(con, ctx, V₊ - ρ * V)

    push!(basis, one(R))

    M₁ = as_matrix(basis => L₁)
    M₂ = as_matrix(basis => L₂)

    opt = feasible(c₁ ∧ c₂ ∧ mapreduce(c -> c == 0, ∧, M₁) ∧ mapreduce(c -> c == 0, ∧, M₂))

    if verbose()
        @info "Formulating the search for a Lyapunov certificate"
        @info "Basis: $basis"
        show(opt)
        println()
    end

    bisect_rate && return bisection(ρ, opt, 0.0, 1.0, 1e-8)
    
    return opt
end
