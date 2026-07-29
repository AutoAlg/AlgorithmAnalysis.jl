export smooth_strongly_convex_interpolation, smooth_strongly_convex_interpolation_is_applicable

smooth_strongly_convex_interpolation_is_applicable(::Any) = false

function smooth_strongly_convex_interpolation_is_applicable(opt::BasicSymbolic{Optimization})::Bool
    predicate = c -> iscall(c) && isequal(symtype(c), Constraint) && isequal(operation(c), smooth_strongly_convex)

    return !isempty(find_nodes(predicate, opt))
end


function smooth_strongly_convex_interpolation(opt::BasicSymbolic{Optimization})::BasicSymbolic{Optimization}
    constraints::Vector{BasicSymbolic{<:Constraint}} = filter(c -> isequal(operation(c), smooth_strongly_convex), get_all_constraints_of_optimization(opt))

    if isempty(constraints)
        error("Optimization problem has no smooth strongly convex constraints")
    end

    for constraint_node::BasicSymbolic{<:Constraint} ∈ constraints
        # as established in representation.jl
        f = arguments(constraint_node)[1]
        μ = arguments(constraint_node)[2]
        L = arguments(constraint_node)[3]
        opt = smooth_strongly_convex_interpolation(opt, f, μ, L)
    end

    return opt
end

function smooth_strongly_convex_interpolation(
    opt::BasicSymbolic{Optimization},
    f::BasicSymbolic{FnType{Tuple{V},F,DifferentiableFunctional}},
    μ::BasicSymbolic{F},
    L::BasicSymbolic{F}
)::BasicSymbolic{Optimization} where {F<:Field,V<:VectorSpace{F}}

    function_points::Set{BasicSymbolic{V}} = Set(find_evaluation_points(f, opt))
    gradient_points::Set{BasicSymbolic{V}} = Set(find_evaluation_points(f', opt))
    evaluation_points::Set{BasicSymbolic{V}} = function_points ∪ gradient_points # x, x_s, etc...
    @info "Applying smooth strongly convex interpolation to $evaluation_points"

    if isempty(evaluation_points)
        return opt
    end

    all_constraints::BasicSymbolic{<:Constraint} = satisfied()

    for x::BasicSymbolic{V} ∈ evaluation_points
        for y::BasicSymbolic{V} ∈ evaluation_points
            if !isequal(x, y)
                ∇fx::BasicSymbolic{V} = f'(x)
                ∇fy::BasicSymbolic{V} = f'(y)

                # f(x) >= f(y) + ∇f(y)ᵀ(x-y) + 1/(2(L-μ))‖∇f(x)-∇f(y)‖² + μL/(2(L-μ))‖x-y‖² - μ/(L-μ)⟨∇f(x)-∇f(y), x-y⟩
                c::BasicSymbolic{<:Constraint} = f(x) ≥ f(y) + ∇fy'(x - y) +
                                                        (one(F) / (R(2.0) * (L - μ))) * (∇fx - ∇fy)'(∇fx - ∇fy) +
                                                        ((μ * L) / (R(2.0) * (L - μ))) * (x - y)'(x - y) -
                                                        (μ / (L - μ)) * (∇fx - ∇fy)'(x - y)

                all_constraints = all_constraints ∧ c
            end
        end
    end

    return flatten_evaluations(
        replace_node(
            opt,
            smooth_strongly_convex(f, μ, L),
            all_constraints
        ),
        [f, f']
    )
end