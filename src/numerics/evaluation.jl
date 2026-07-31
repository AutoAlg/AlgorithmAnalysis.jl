export evaluate

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
        val, feas, minval, maxval, tol = evaluate.(arguments(node))
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
