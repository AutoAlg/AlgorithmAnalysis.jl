import Base: show

# --- Base AST Printing ---

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

_show_structural(io::IO, v::NewR) = print(io, "R_$(v.id._node_id)")
_show_structural(io::IO, v::NewRⁿ) = print(io, "Rⁿ_$(v.id._node_id)")
_show_structural(io::IO, f::SSCFunction) = print(io, "SSC_$(f.id._node_id)(m=$(f.m), L=$(f.L))")
_show_structural(io::IO, nabla::SSCGradient) = print(io, "∇SSC_$(nabla.function_of._node_id)")

function _show_structural(io::IO, g::SSCGradientOf)
    ctx = ALGORITHM_CONTEXT[]
    if ctx === nothing
        print(io, "Oracle_$(g.∇_id._node_id)(x_$(g.x_id._node_id))")
        return
    end
    
    nabla = ctx._expressions[g.∇_id]
    x = ctx._expressions[g.x_id]
    
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

    ctx = ALGORITHM_CONTEXT[]
    sorted_terms = sort(collect(d.terms), by = p -> p.first._node_id)
    
    first_term = true
    for (id, coeff) in sorted_terms
        if coeff == 0.0
            continue
        end

        v = ctx === nothing ? "ID_$(id._node_id)" : ctx._expressions[id]

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

# Helper to cleanly print UInt32 arrays without the type tags
function _format_id_array(ids::Vector{UInt32})
    isempty(ids) && return "[]"
    return "[" * join(Int.(sort(ids)), ", ") * "]"
end

# Helper to dynamically build the "Used By" edges for the compiler trace
function _build_dependents_map(ctx::AlgorithmContext)
    dependents = Dict{ExpressionID, Vector{ExpressionID}}()
    
    for id in keys(ctx._expressions)
        dependents[id] = ExpressionID[]
    end
    
    for (id, expr) in ctx._expressions
        for dep_id in dependencies(expr)
            if haskey(dependents, dep_id)
                push!(dependents[dep_id], id)
            end
        end
    end
    return dependents
end

function print_algorithm(io::IO, ctx::AlgorithmContext)
    sorted_exprs = sort(collect(ctx._expressions), by = pair -> pair.first._node_id)
    dependents_map = _build_dependents_map(ctx)
    
    # --- Mathematical Pseudocode View ---
    println(io, "Algorithm State")
    println(io, "────────────────────────────────────────────────────────────────────────────")
    
    oracles, vars, transitions = String[], String[], String[]
    
    for (id, expr) in sorted_exprs
        name = get(ctx._expression_names, id, nothing)
        display_name = name === nothing ? "v$(id._node_id)" : name
        structure = sprint((io_s, e) -> _show_structural(io_s, e), expr)
        
        if expr isa NewOracle
            push!(oracles, "  $(rpad(display_name, 6)) = $structure")
        elseif expr isa StateTransition
            push!(transitions, "  $(rpad(display_name, 6)) : $structure")
        elseif expr isa NewR || expr isa NewRⁿ
            space_symbol = expr isa NewRⁿ ? "Rⁿ" : "R"
            push!(vars, "  $(rpad(display_name, 6)) ∈ $space_symbol")
        else
            # Skip ALL unnamed intermediate evaluated expressions in the pseudocode view
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
    println(io, "─────────────────────────────────────────────────────────────────────────────────────────")
    # Widened the columns to fit the arrays perfectly
    println(io, rpad("[ID]", 6), rpad("Name", 8), rpad("Type", 22), rpad("Depends On", 16), rpad("Used By", 16), "Structure")
    println(io, "-"^89)
    
    for (id, expr) in sorted_exprs
        name = get(ctx._expression_names, id, "_")
        clean_type = _clean_type_name(expr)
        structure = sprint((io_s, e) -> _show_structural(io_s, e), expr)
        
        # 1. Depends On (Backward Edges)
        dep_ids = UInt32[d._node_id for d in dependencies(expr)]
        depends_on_str = _format_id_array(dep_ids)
        
        # 2. Used By (Forward Edges)
        used_by_ids = UInt32[d._node_id for d in dependents_map[id]]
        used_by_str = _format_id_array(used_by_ids)
        
        id_str = lpad(string(id._node_id), 2)
        
        print(io, "[", id_str, "]  ")
        print(io, rpad(name, 8))
        print(io, rpad(clean_type, 20), "| ")
        print(io, rpad(depends_on_str, 14), "| ")
        print(io, rpad(used_by_str, 14), "| ")
        println(io, structure)
    end
    
end

print_algorithm(ctx::AlgorithmContext) = print_algorithm(stdout, ctx)
show(io::IO, ::MIME"text/plain", ctx::AlgorithmContext) = print_algorithm(io, ctx)
show(io::IO, ctx::AlgorithmContext) = print_algorithm(io, ctx)