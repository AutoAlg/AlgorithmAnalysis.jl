export smooth_convex_interpolation_is_applicable, smooth_convex_interpolation

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
