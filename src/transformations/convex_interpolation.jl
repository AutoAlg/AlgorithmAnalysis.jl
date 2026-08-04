# ------------------------------------------------------
# CONVEX INTERPOLATION
# ------------------------------------------------------

export convex_interpolation

convex_interpolation_is_applicable(::Any) = false

function convex_interpolation_is_applicable(opt::Node{<:Optimization})
    return !isempty(find_nodes(c -> isequal(symtype(c), Convex), opt))
end

"""
    convex_interpolation(opt::Node)

Given an optimization node, replaces all convex functions with their interpolation conditions.
"""
function convex_interpolation(opt::Node{<:Optimization})
    
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

function convex_interpolation(opt::Node{<:Optimization}, f::Node)

    points = find_evaluation_points(f, opt) ∪ find_evaluation_points(f', opt)

    pts = join(tostring.(points), ", ")

    @info "Applying convex interpolation to function $f with evaluation points $pts"

    if isempty(points)
        @info "No points found!"
        return opt
    end

    interp = satisfied()

    for x ∈ points, y ∈ points
        interp = interp ∧ ( f(x) ≥ f(y) + f'(y)'(x-y) )
    end

    new_opt = replace_node(opt, convex(f), interp)
    new_opt = flatten_evaluations(new_opt, [f, f'])

    return new_opt
end
