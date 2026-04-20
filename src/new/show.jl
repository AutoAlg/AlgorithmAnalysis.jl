
function show(io::IO, expr::NewExpression)
    ctx = ALGORITHM_CONTEXT[]
    if ctx !== nothing
        name = try_get_name(expr.id, ctx)
        if name !== nothing
            print(io, name)
            return
        end
    end
    _show_structural(io, expr)
end

_show_structural(io::IO, v::Variable{RealSpace}) = print(io, "R_$(v.id._node_id)")
_show_structural(io::IO, v::Variable{RealVectorSpace}) = print(io, "Rⁿ_$(v.id._node_id)")
_show_structural(io::IO, f::SSCFunction) = print(io, "SSC_$(f.id._node_id)(m=$(f.m), L=$(f.L))")

function _show_structural(io::IO, g::GradientOf)
    ctx = ALGORITHM_CONTEXT[]
    if ctx === nothing
        print(io, "∇f_$(g.f_id._node_id)(x_$(g.x_id._node_id))")
        return
    end
    
    f = ctx._expressions[g.f_id]
    x = ctx._expressions[g.x_id]
    
    print(io, "∇")
    show(io, f)
    print(io, "(")
    show(io, x)
    print(io, ")")
end

function _show_structural(io::IO, d::LinearDecomposition)
    if isempty(d.terms)
        print(io, "0")
        return
    end

    sorted_terms = sort(collect(d.terms), by = p -> p.first.id._node_id)
    
    first_term = true
    for (v, coeff) in sorted_terms
        if coeff == 0.0
            continue
        end

        if first_term
            if coeff == 1.0
                show(io, v)
            elseif coeff == -1.0
                print(io, "-")
                show(io, v)
            else
                print(io, coeff, " * ")
                show(io, v)
            end
            first_term = false
        else
            if coeff == 1.0
                print(io, " + ")
                show(io, v)
            elseif coeff == -1.0
                print(io, " - ")
                show(io, v)
            elseif coeff > 0.0
                print(io, " + ", coeff, " * ")
                show(io, v)
            else
                print(io, " - ", -coeff, " * ")
                show(io, v)
            end
        end
    end
    
    if first_term
        print(io, "0")
    end
end

function _show_structural(io::IO, t::StateTransition)
    ctx = ALGORITHM_CONTEXT[]
    if ctx === nothing
        print(io, "StateTransition($(t.current_id._node_id) => $(t.next_id._node_id))")
        return
    end
    
    current_var = ctx._expressions[t.current_id]
    next_var = ctx._expressions[t.next_id]
    
    show(io, current_var)
    print(io, " => ")
    show(io, next_var)
end

function print_algorithm(ctx::AlgorithmContext)
    sorted_exprs = sort(collect(ctx._expressions), by = pair -> pair.first._node_id)
    
    for (id, expr) in sorted_exprs
        var_name = get(ctx._expression_names, id, "<unnamed>")
        var_type = typeof(expr)
        structure = sprint((io, e) -> _show_structural(io, e), expr)
        
        println("ID: #$(id._node_id) | Variable: $(var_name): $(var_type) | Structure: $(structure)")
    end
end
