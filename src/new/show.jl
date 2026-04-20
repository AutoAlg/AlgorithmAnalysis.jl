import Base: show

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
_show_structural(io::IO, ∇::SSCGradient) = print(io, "∇SSC_$(∇.function_of._node_id)")



function _show_structural(io::IO, g::SSCGradientOf)
    ctx = ALGORITHM_CONTEXT[]
    if ctx === nothing
        print(io, "Oracle_$(g.∇_id._node_id)(x_$(g.x_id._node_id))")
        return
    end
    
    nabla = ctx._expressions[g.∇_id]
    x = ctx._expressions[g.x_id]
    
    # We no longer hardcode "∇". We just print the operator!
    show(io, nabla)
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

# --- Full Context Printing ---

function _clean_type_name(expr)
    s = string(typeof(expr))
    s = replace(s, "{RealSpace}" => "")
    s = replace(s, "{RealVectorSpace}" => "")
    s = replace(s, r"Main\..*\." => "") 
    return s
end

# Central formatting function that writes to any IO stream
function print_algorithm(io::IO, ctx::AlgorithmContext)
    sorted_exprs = sort(collect(ctx._expressions), by = pair -> pair.first._node_id)
    
    # --- Mathematical Pseudocode View ---
    println(io, "Algorithm State")
    println(io, "────────────────────────────────────────────────────────────")
    
    oracles, vars, transitions = String[], String[], String[]
    
    for (id, expr) in sorted_exprs
        name = get(ctx._expression_names, id, nothing)
        display_name = name === nothing ? "v$(id._node_id)" : name
        structure = sprint((io_s, e) -> _show_structural(io_s, e), expr)
        
        if expr isa NewOracle
            push!(oracles, "  $(rpad(display_name, 6)) = $structure")
        elseif expr isa StateTransition
            push!(transitions, "  $(rpad(display_name, 6)) : $structure")
        elseif expr isa Variable
            space_symbol = expr isa Variable{RealVectorSpace} ? "Rⁿ" : "R"
            push!(vars, "  $(rpad(display_name, 6)) ∈ $space_symbol")
        else
            # Skip ALL unnamed intermediate evaluated expressions (GradientOf, LinearDecomposition, etc.)
            if name === nothing
                continue
            end
            push!(vars, "  $(rpad(display_name, 6)) = $structure")
        end
    end
    
    if !isempty(oracles)
        println(io, "Oracles:\n", join(oracles, "\n"))
        println(io)
    end
    if !isempty(vars)
        println(io, "Variables:\n", join(vars, "\n"))
        println(io)
    end
    if !isempty(transitions)
        println(io, "Transitions:\n", join(transitions, "\n"))
        println(io)
    end

    # --- Aligned Compiler Trace ---
    println(io, "Compiler Trace")
    println(io, "────────────────────────────────────────────────────────────")
    println(io, rpad("[ID]", 6), rpad("Name", 8), rpad("Type", 22), "Structure")
    println(io, "-"^60)
    
    for (id, expr) in sorted_exprs
        name = get(ctx._expression_names, id, "_")
        clean_type = _clean_type_name(expr)
        structure = sprint((io_s, e) -> _show_structural(io_s, e), expr)
        
        id_str = lpad(string(id._node_id), 2)
        
        print(io, "[", id_str, "]  ")
        print(io, rpad(name, 8))
        print(io, rpad(clean_type, 20), "| ")
        println(io, structure)
    end
end

# Default to stdout if no IO stream is provided
print_algorithm(ctx::AlgorithmContext) = print_algorithm(stdout, ctx)

# Overload for REPL display (e.g., when a cell evaluates to `ctx`)
show(io::IO, ::MIME"text/plain", ctx::AlgorithmContext) = print_algorithm(io, ctx)

# Overload for `print(ctx)`, `println(ctx)`, and string interpolation `"$ctx"`
show(io::IO, ctx::AlgorithmContext) = print_algorithm(io, ctx)