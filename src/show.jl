export expand

Base.show(io::IO, ::MIME"text/plain", t::BasicSymbolic) = print(io, render(t))
expand(t::BasicSymbolic) = println(render(t, use_id = false))

# ------------------------------------------------------
#  DISPLAY WRAPPERS & LAYOUT TYPES
# ------------------------------------------------------

struct Postfixed
    expr
    op::Symbol
    id::Union{Symbol, Nothing}
end

struct CleanOp
    name::Symbol
    id::Union{Symbol, Nothing}
end

struct NormSquared
    expr
    id::Union{Symbol, Nothing}
end

struct ConstraintSet
    obj
    type::Symbol
    id::Union{Symbol, Nothing}
end

struct OptimizationProblem
    sense::Symbol  # :maximize or :minimize or :feasible
    objective
    constraints
    id::Union{Symbol, Nothing}
end

# ------------------------------------------------------
#  SEMANTIC AST TRANSFORMATION
# ------------------------------------------------------

function pretty_ast(t::Any; use_id)
    id = check_and_translate_identity(t)
    return id ≠ nothing ? id : t
end

function pretty_ast(t::BasicSymbolic{Maximization}; use_id = true)
    sense = Symbol(operation(t))
    objective = pretty_ast(arguments(t)[1], use_id=use_id)
    constraints = pretty_ast(arguments(t)[2], use_id=use_id)
    return OptimizationProblem(sense, objective, constraints, id(t))
end

function pretty_ast(t::BasicSymbolic{Convex}; use_id = true)
    f = pretty_ast(arguments(t)[1], use_id=use_id)
    return ConstraintSet(f, :Convex, id(t))
end

function pretty_ast(t::BasicSymbolic{FnType{Tuple{T}, T, Gradient}}; use_id = true) where T
    if istree(t)
        f = pretty_ast(arguments(t)[1], use_id=use_id)
    else
        f = t.name
    end
    return CleanOp(Symbol(:∇, f), id(t))
end

function pretty_ast(t::BasicSymbolic{FnType{Tuple{X}, Y, LinearFunctional}}; use_id = true) where {X,Y}
    f = istree(t) ? pretty_ast(arguments(t)[1], use_id=use_id) : id(t)
    return Postfixed(f, Symbol("'"), id(t))
end

function pretty_ast(t::BasicSymbolic; use_id::Bool = true)

    use_id && has_id(t) && return CleanOp(id(t), id(t))

    x = check_and_translate_identity(t)
    x ≠ nothing && return x

    if istree(t)
        op = operation(t)
        args = arguments(t)
        pretty_args = map(arg -> pretty_ast(arg; use_id=use_id), args)

        if op === constant
            return pretty_args[1]
        elseif op ∈ [+, -, *, /, ∧, ==]
            return Expr(:call, Symbol(op), pretty_args...)
        elseif op === ≤
            return Expr(:call, :≤, pretty_args...)
        elseif op === ≥
            return Expr(:call, :≥, pretty_args...)
        end

        if !isempty(args)
            if applicable(adjoint, args[1]) && op === args[1]'
                return NormSquared(pretty_args[1], id(t))
            elseif op === adjoint
                return Postfixed(pretty_args[1], Symbol("'"), id(t))
            end
        end

        pretty_op = pretty_ast(op, use_id=use_id)

        return Expr(:call, pretty_op, pretty_args...)
    end
    
    return id(t)
end

# ------------------------------------------------------
#  STRING RENDERING ENGINE (`render`)
# ------------------------------------------------------

# Entry orchestrator: converts the sanitized math AST to a structural string
render(x; use_id::Bool = true) = string(pretty_ast(x; use_id=use_id))
render(x::String) = x

# Display layouts for custom math categories
function Base.show(io::IO, op::CleanOp)
    get(io, :use_id, true) && op.id ≠ nothing && return print(io, op.id)
    
    print(io, string(op.name))
end
Base.show(io::IO, n::NormSquared) = print(io, "‖", render(n.expr), "‖²")
Base.show(io::IO, con::ConstraintSet) = print(io, render(con.obj), " ∈ ", con.type)

function Base.show(io::IO, p::Postfixed)
    get(io, :use_id, true) && p.id ≠ nothing && return print(io, p.id)

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
render_expr_node(head, args) = string(Expr(head, args...))

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

# ------------------------------------------------------
#  UTILITIES
# ------------------------------------------------------

function flatten_constraints!(list, node)
    if istree(node) && operation(node) === ∧
        map(arg -> flatten_constraints!(list, arg), arguments(node))
        return
    elseif node isa Expr && node.head === :call
        op = node.args[1]
        if (op === ∧) || (op === :∧)
            map(arg -> flatten_constraints!(list, arg), node.args[2:end])
            return
        end
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
