export s_procedure, multiplier

"""
    s_procedure(constraint, ctx, f)
"""
function s_procedure(constraint::Node{<:Prop}, ctx, f)
    con = satisfied()
    for c ∈ constraint
        symtype(c) <: Transition && continue
        λ, λ_con, ctx = multiplier(ctx, c)
        f += λ ⋅ expression(c)
        con = con ∧ λ_con
    end
    return f, con, ctx
end

function multiplier(ctx, ::Node{Equality{R}})
    sym = get_safe_symbol(:λ, ctx, force_subscript = true)
    λ = leaf(R, sym)
    push!(ctx, sym)
    return λ, satisfied(), ctx
end

function multiplier(ctx, ::Node{LessThanOrEqualTo{R}})
    sym = get_safe_symbol(:λ, ctx, force_subscript = true)
    λ = leaf(R, sym)
    push!(ctx, sym)
    return λ, λ ≥ zero(R), ctx
end

function multiplier(ctx, c::Node{PositiveSemidefinite})
    A = arguments(c)[1]
    n = size(A,1)
    λ = Matrix{Node{R}}(undef, (n,n))
    for i ∈ 1:n, j ∈ i:n
        sym = get_safe_symbol(:λ, ctx, force_subscript = true)
        λ[i,j] = leaf(R, sym)
        push!(ctx, sym)
    end
    for i ∈ 1:n, j ∈ 1:i-1
        λ[i,j] = λ[j,i]
    end
    Λ = Sⁿ(λ)
    return Λ, Λ ⪰ 0, ctx
end
