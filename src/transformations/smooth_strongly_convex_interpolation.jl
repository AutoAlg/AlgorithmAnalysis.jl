# ------------------------------------------------------
# SMOOTH STRONGLY CONVEX INTERPOLATION
# ------------------------------------------------------

export smooth_strongly_convex_interpolation

smooth_strongly_convex_interpolation_is_applicable(::Any) = false

function smooth_strongly_convex_interpolation_is_applicable(opt::Node{<:Optimization})
    predicate = function (c)
        isequal(symtype(c), Prop) && iscall(c) && isequal(operation(c), smooth_strongly_convex)
    end
    return !isempty(find_nodes(predicate, opt))
end

"""
    smooth_strongly_convex_interpolation(opt)

Given an optimization node, replaces all smooth convex functions with their interpolation conditions.
"""
function smooth_strongly_convex_interpolation(opt::Node{<:Optimization})
    
    predicate = function (c)
        isequal(symtype(c), Prop) && iscall(c) && isequal(operation(c), smooth_strongly_convex)
    end
    cons = find_nodes(predicate, opt)

    if isempty(cons)
        error("Optimization problem has no smooth strong convexity constraints")
    end

    for con ∈ cons
        f, μ, L = arguments(con)
        opt = smooth_strongly_convex_interpolation(opt, f, μ, L)
    end

    return opt
end

function smooth_strongly_convex_interpolation(opt::Node{<:Optimization}, f::Node, μ::Node, L::Node)

    points = find_evaluation_points(f, opt) ∪ find_evaluation_points(f', opt)

    pts = join(tostring.(points), ", ")

    @info "Applying $L-smooth $μ-strongly convex interpolation to function $f with evaluation points $pts"

    if isempty(points)
        @info "No points found!"
        return opt
    end

    interp = satisfied()

    for x ∈ points, y ∈ points
        gx = f'(x)
        gy = f'(y)
        interp = interp ∧ ( f(x) ≥ f(y) + gy'(x-y) + 1/(2(1-μ/L)) * ( 1/L * (gx-gy)^2 + μ * (x-y)^2 - 2μ/L * (x-y)'(gx-gy) ) )
    end

    opt = replace_node(opt, smooth_strongly_convex(f, μ, L), interp)
    opt = propagate_and_remove_transitions(opt, [f, f'])
    opt = flatten_evaluations(opt, [f, f'])

    return opt
end
