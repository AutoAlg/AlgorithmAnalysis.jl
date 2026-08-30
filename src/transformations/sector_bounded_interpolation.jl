# ------------------------------------------------------
# SECTOR BOUNDED INTERPOLATION
# ------------------------------------------------------

export sector_bounded_interpolation

sector_bound_is_applicable(::Any) = false

function sector_bound_is_applicable(opt::Node{<:Optimization})
    predicate = function (c)
        isequal(symtype(c), Prop) && iscall(c) && isequal(operation(c), sector_bounded)
    end
    return !isempty(find_nodes(predicate, opt))
end

"""
    sector_bounded_interpolation(opt::Node)

Given an optimization node, replaces all sector functions with their interpolation conditions.
"""
function sector_bounded_interpolation(opt::Node{<:Optimization})
    
    predicate = function (c)
        isequal(symtype(c), Prop) && iscall(c) && isequal(operation(c), sector_bounded)
    end
    cons = find_nodes(predicate, opt)

    if isempty(cons)
        error("Optimization problem has no sector bound constraints")
    end

    for con ∈ cons
        f, μ, L = arguments(con)
        opt = sector_bounded_interpolation(opt, f, μ, L)
    end

    return opt
end

function sector_bounded_interpolation(opt::Node{<:Optimization}, f::Node, μ::Node, L::Node)

    points = find_evaluation_points(f, opt) ∪ find_evaluation_points(f', opt)

    pts = join(tostring.(points), ", ")

    @info "Applying [$μ,$L] sector bounded interpolation to function $f with evaluation points $pts"

    if isempty(points)
        @info "No points found!"
        return opt
    end

    interp = satisfied()

    for x ∈ points
        interp = interp ∧ ( (f'(x) - μ*x)'(f'(x) - L*x) ≤ zero(R) )
    end

    old = sector_bounded(f, μ, L)

    opt = replace_constraint(opt, old, interp)
    opt = propagate_transitions(opt, [f, f'])
    opt = flatten_evaluations(opt, [f, f'])

    return opt
end
