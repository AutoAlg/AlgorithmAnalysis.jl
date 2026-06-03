# ====================================================================
#  DISPLAY WRAPPERS & LAYOUT TYPES
# ====================================================================

struct Postfixed
    expr
    op::Symbol
end

struct CleanOp
    name::Symbol
end

struct NormSquared
    expr
end

struct ConstraintSet
    obj
    type::Symbol
end

struct OptimizationProblem
    sense::Symbol  # :maximize or :minimize or :feasible
    objective
    constraints
end

Base.show(io::IO, ::MIME"text/plain", t::BasicSymbolic) = print(io, render(t))

# ====================================================================
#  SEMANTIC AST TRANSFORMATION
# ====================================================================

function pretty_ast(t::Any)
    id = check_and_translate_identity(t)
    return id ≠ nothing ? id : t
end

function pretty_ast(t::BasicSymbolic{Maximization})
    sense = Symbol(operation(t))
    objective = pretty_ast(arguments(t)[1])
    constraints = pretty_ast(arguments(t)[2])
    return OptimizationProblem(sense, objective, constraints)
end

function pretty_ast(t::BasicSymbolic{Convex})
    f = pretty_ast(arguments(t)[1])
    return ConstraintSet(f, :Convex)
end

function pretty_ast(t::BasicSymbolic{FnType{Tuple{T}, T, Gradient}}) where T
    if istree(t)
        f = pretty_ast(arguments(t)[1])
    else
        f = t.name
        return f
    end
    return CleanOp(Symbol(:∇, f))
end

function pretty_ast(t::BasicSymbolic{FnType{Tuple{X}, Y, LinearFunctional}}) where {X,Y}
    return Postfixed(t.name, Symbol("'"))
end

function pretty_ast(t::BasicSymbolic)

    has_id(t) && return CleanOp(get_id(t))

    id = check_and_translate_identity(t)
    id ≠ nothing && return id

    if istree(t)
        op = operation(t)
        args = arguments(t)
        pretty_args = map(pretty_ast, args)

        if op === constant
            return pretty_args[1]
        elseif op === +
            return Expr(:call, :+, pretty_args...)
        elseif op === -
            return Expr(:call, :-, pretty_args...)
        elseif op === *
            return Expr(:call, :*, pretty_args...)
        elseif op === /
            return Expr(:call, :/, pretty_args...)
        elseif op === ≤
            return Expr(:call, :≤, pretty_args...)
        elseif op === ≥
            return Expr(:call, :≥, pretty_args...)
        end

        if !isempty(args)
            if applicable(adjoint, args[1]) && op === args[1]'
                return NormSquared(pretty_args[1])
            elseif op === adjoint
                return Postfixed(pretty_args[1], Symbol("'"))
            end
        end

        return Expr(:call, op, pretty_args...)
    end
    
    return t.name
end

# ====================================================================
#  STRING RENDERING ENGINE (`render`)
# ====================================================================

# Entry orchestrator: converts the sanitized math AST to a structural string
render(x) = string(pretty_ast(x))
render(x::String) = x

# Display layouts for custom math categories
Base.show(io::IO, op::CleanOp) = print(io, string(op.name))
Base.show(io::IO, n::NormSquared) = print(io, "‖", render(n.expr), "‖²")
Base.show(io::IO, con::ConstraintSet) = print(io, render(con.obj), " ∈ ", con.type)

function Base.show(io::IO, p::Postfixed)
    # Check if children need protection parentheses
    inner_str = render(p.expr)
    if any(c -> c in ['+', '-', '*'], inner_str) && !(startswith(inner_str, "(") && endswith(inner_str, ")"))
        print(io, "(", inner_str, ")", p.op)
    else
        print(io, inner_str, p.op)
    end
end

function Base.show(io::IO, opt::OptimizationProblem)
    println(io, opt.sense, " "^5, render(opt.objective))
    flat_cons = []
    flatten_constraints!(flat_cons, opt.constraints)
    
    for (i, con) in enumerate(flat_cons)
        prefix = (i == 1) ? "subject to   " : " "^13
        println(io, prefix, render(con))
    end
end

# Infix math rendering overrides
render(e::Expr) = render_expr_node(e.head, e.args)
render_expr_node(head, args) = string(Expr(head, args...)) # Fallback

function render_expr_node(head::Symbol, args)
    head ≠ :call && return string(Expr(head, args...))
    op = Symbol(args[1])
    
    if op in (:+, :-, :*, :≤, :≥, :(==))
        rendered_children = [render_child(op, arg) for arg in args[2:end]]
        return join(rendered_children, " $op ")
    end
    
    # Standard prefix functions: f(x, y)
    return string(op) * "(" * join(map(render, args[2:end]), ", ") * ")"
end

# Precedence layout helper to manage natural parenthesis groupings
function render_child(parent_op::Symbol, child)
    child_str = render(child)
    !istree(child) && !(child isa Expr) && return child_str
    
    # Grab the active operator head safely
    child_op = child isa Expr ? child.args[1] : operation(child)
    child_op = Symbol(child_op)
    
    # Wrap additions/subtractions inside multiplications or postfix operators
    if parent_op in (:*, Symbol("'")) && child_op in (:+, :-, :≤, :≥, :(==))
        return "($child_str)"
    end
    return child_str
end

# ====================================================================
#  UTILITIES
# ====================================================================

function flatten_constraints!(list, node)
    if istree(node) && operation(node) === ∧
        map(arg -> flatten_constraints!(list, arg), arguments(node))
        return
    elseif node isa Expr && node.head === :call && node.args[1] === ∧
        map(arg -> flatten_constraints!(list, arg), node.args[2:end])
        return
    end
    push!(list, node)
end

function check_and_translate_identity(node)
    if hasproperty(node, :name)
        node.name === :additive_identity && return 0
        node.name === :multiplicative_identity && return 1
    end
    return nothing
end
