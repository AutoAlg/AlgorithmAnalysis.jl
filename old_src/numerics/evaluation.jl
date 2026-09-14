export evaluate

"""
    evaluate(expr)

Evaluate an expression. Uses the following evaluation techniques (in order):
- If the expression is a parameter, return its parameter value.
- If the expression is in an active JuMP model, then its value in the model (either numeric if the model is solved, or as a JuMP expression) is returned.
- If the expression is a leaf and has an instantation as a JuMP variable, then instantiate it in the model.
- If the expression is a top-level node (e.g., a Lyapunov certificate or bisection), then evaluate the expression from the top down.
- If the expression is a basic arithmetic operation (e.g., +, -, *, /), evaluate the expression from the bottom up (starting with leaf nodes).
- If the expression has an instantation as a JuMP variable (and is not a leaf), then instantiate it in the model.

Otherwise, when none of these evaluation techniques are applicable, the original expression is returned.
"""
evaluate(node::Any) = node

function evaluate(node::Node)

    # -------------------------------------------
    # LEAF NODES
    # -------------------------------------------
    if isequal(symtype(node), R)
        iszero(node) && return 0.0
        isone(node) && return 1.0
    end

    if is_parameter(node)
        verbose() && @info "Node $node is a parameter"
        return get_parameter(node)
    end
    
    if in_model(node)
        verbose() && @info "Node $node exists in the JuMP model"
        return get_from_model(node)
    end

    # Handle initialization of raw variables (leaves) in JuMP
    if active_model() && !iscall(node)
        val = instantiate_in_model(node)
        if !isnothing(val)
            if verbose()
                @info "Instantiating node $node in the JuMP model"
            end
            return val
        end
    end

    # -------------------------------------------
    # PREWALK (starting with top-level nodes)
    # -------------------------------------------
    if symtype(node) <: Bisection
        val = evaluate(arguments(node)[1])
        feas = arguments(node)[2]
        minval, maxval, tol = evaluate.(arguments(node)[3:5])
        f(x) = with_numerics(parameters = Dict(val => x)) do
            evaluate(feas)
        end
        @info "Bisecting over $val in [$minval, $maxval] with tolerance $tol"
        return bsmin(f, minval, maxval, tol=tol)
    end

    if symtype(node) <: LyapunovCertificate
        return instantiate_in_model(node)
    end

    # -------------------------------------------
    # POSTWALK (starting with leaves)
    # -------------------------------------------
    if iscall(node)
        op   = operation(node)
        args = map(evaluate, arguments(node))
        T    = symtype(node)

        if isequal(op, constant)
            return args[1]
        elseif op ∈ [+, -, *, /]
            return op(args...)
        elseif isequal(op, tr)
            return tr(args[1])
        elseif isequal(T, Sⁿ)
            return evaluate.(mat(node))
        end
    end

    # ---------------------------------------------------------
    # CONSTRAINTS & METAFUNCTIONS
    # ---------------------------------------------------------
    if active_model()
        val = instantiate_in_model(node)
        if !isnothing(val)
            if verbose()
                @info "Instantiating node $node in the JuMP model"
            end
            return val
        end
    end

    return node
end
