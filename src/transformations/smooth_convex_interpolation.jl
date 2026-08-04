# ------------------------------------------------------
# SMOOTH CONVEX INTERPOLATION
# ------------------------------------------------------

export smooth_convex_interpolation

smooth_convex_interpolation_is_applicable(::Any) = false

function smooth_convex_interpolation_is_applicable(opt::Node{<:Optimization})
    predicate = function (c)
        isequal(symtype(c), Prop) && iscall(c) && isequal(operation(c), smooth_convex)
    end
    return !isempty(find_nodes(predicate, opt))
end

"""
    smoot_convex_interpolation(opt::Node)

Given an optimization node, replaces all smooth convex functions with their interpolation conditions.
"""
function smooth_convex_interpolation(opt::Node{<:Optimization})
    
    predicate = function (c)
        isequal(symtype(c), Prop) && iscall(c) && isequal(operation(c), smooth_convex)
    end
    cons = find_nodes(predicate, opt)

    if isempty(cons)
        error("Optimization problem has no smooth convexity constraints")
    end

    for con ∈ cons
        f, L = arguments(con)
        opt = smooth_convex_interpolation(opt, f, L)
    end

    return opt
end

function smooth_convex_interpolation(opt::Node{<:Optimization}, f::Node, L::Node)

    points = find_evaluation_points(f, opt) ∪ find_evaluation_points(f', opt)

    pts = join(tostring.(points), ", ")

    @info "Applying $L-smooth convex interpolation to function $f with evaluation points $pts"

    if isempty(points)
        @info "No points found!"
        return opt
    end

    interp = satisfied()

    for x ∈ points, y ∈ points
        gx = f'(x)
        gy = f'(y)
        interp = interp ∧ ( f(x) ≥ f(y) + gy'(x-y) + 1/2L * (gx-gy)'(gx-gy) )
    end

    new_opt = replace_node(opt, smooth_convex(f, L), interp)
    new_opt = flatten_evaluations(new_opt, [f, f'])

    return new_opt
end
