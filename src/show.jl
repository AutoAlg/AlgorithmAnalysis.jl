export expand

Base.show(io::IO, mime::MIME"text/plain", t::BasicSymbolic) = show(io, mime, semantic_ast(t))
expand(t::BasicSymbolic) = show(IOContext(stdout, :use_id => false), MIME"text/plain"(), t)

# ------------------------------------------------------
#  DISPLAY WRAPPERS & LAYOUT TYPES
# ------------------------------------------------------

abstract type SemanticNode end

struct Constant <: SemanticNode
    value::Any
    id::Union{Symbol, Nothing}
end

struct Postfixed <: SemanticNode
    expr::SemanticNode
    op::Symbol
    id::Union{Symbol, Nothing}
end

struct Leaf <: SemanticNode
    id::Symbol
end

struct NormSquared <: SemanticNode
    expr::SemanticNode
    id::Union{Symbol, Nothing}
end

struct ConstraintSet <: SemanticNode
    obj::SemanticNode
    set::SemanticNode
    id::Union{Symbol, Nothing}
end

struct OptimizationProblem <: SemanticNode
    sense::Symbol  # :maximize or :minimize or :feasible
    objective::SemanticNode
    constraints::Vector{SemanticNode}
    id::Union{Symbol, Nothing}
end

struct InfixOp <: SemanticNode
    op::SemanticNode
    args::Vector{SemanticNode}
    id::Union{Symbol, Nothing}
end

struct GradientOp <: SemanticNode
    func::SemanticNode
    id::Union{Symbol, Nothing}
end

struct FuncEval <: SemanticNode
    func::SemanticNode
    args::Vector{<:SemanticNode}
    id::Union{Symbol, Nothing}
end

struct Mat <: SemanticNode
    args::Matrix
    id::Union{Symbol, Nothing}
end

# ------------------------------------------------------
#  SEMANTIC AST TRANSFORMATION
# ------------------------------------------------------

function semantic_ast(t::Any)
    id = check_and_translate_identity(t)
    return id ≠ nothing ? id : error("Unknown semantics for $t")
end

function semantic_ast(t::BasicSymbolic{<:MatrixSpace})
    op = operation(t)
    args = semantic_ast.(arguments(t))
    if op ∈ [+, -, *, /]
        return InfixOp(Leaf(Symbol(op)), args, id(t))
    end
    n = Int(sqrt(length(args)))
    return Mat(reshape(args, n, n), id(t))
end

function semantic_ast(t::BasicSymbolic{Optimization})
    obj = is_feasibility(t) ? Leaf(Symbol("")) : semantic_ast(objective(t))
    con = semantic_ast.(flatten_constraints(constraint(t)))
    return OptimizationProblem(sense(t), obj, con, id(t))
end

function semantic_ast(t::BasicSymbolic{T}) where {T<:Constraint}
    isequal(T, Satisfied) && return Leaf(Symbol(true))
    isequal(T, Unsatisfied) && return Leaf(Symbol(false))
    op = operation(t)
    args = arguments(t)
    pretty_args = map(arg -> semantic_ast(arg), args)

    if isequal(op, ==)
        return InfixOp(Leaf(:(==)), pretty_args, id(t))
    elseif isequal(op, ≤)
        return InfixOp(Leaf(:≤), pretty_args, id(t))
    elseif isequal(op, ∧)
        return InfixOp(Leaf(:∧), pretty_args, id(t))
    elseif isequal(op, smooth_convex)
        f = semantic_ast(args[1])
        L = semantic_ast(args[2])
        return ConstraintSet(f, Leaf(Symbol("SmoothConvex($L)")), id(t))
    else
        f = semantic_ast(args[1])
        return ConstraintSet(f, Leaf(Symbol(T)), id(t))
    end
end

function semantic_ast(t::BasicSymbolic{Bool})
    if iscall(t)
        op = operation(t)
        args = arguments(t)
        pretty_args = map(arg -> semantic_ast(arg), args)

        if isequal(op, ==)
            return InfixOp(Leaf(:(==)), pretty_args, id(t))
        elseif isequal(op, ≤)
            return InfixOp(Leaf(:≤), pretty_args, id(t))
        elseif isequal(op, ≥)
            return InfixOp(Leaf(:≥), pretty_args, id(t))
        end
    else
        return Leaf(id(t))
    end
end

function semantic_ast(t::BasicSymbolic{FnType{Tuple{T}, T, Gradient}}) where T
    f = iscall(t) ? semantic_ast(arguments(t)[1]) : f = Leaf(id(t))
    return GradientOp(f, id(t))
end

function semantic_ast(t::BasicSymbolic{FnType{Tuple{X}, Y, LinearFunctional}}) where {X,Y}
    iszero(t) && return Leaf(Symbol(0))
    f = iscall(t) ? semantic_ast(arguments(t)[1]) : Leaf(id(t))
    return Postfixed(f, Symbol("'"), id(t))
end

function semantic_ast(t::BasicSymbolic)

    x = check_and_translate_identity(t)
    x ≠ nothing && return x

    if iscall(t)
        op = operation(t)

        isequal(op, constant) && return Constant(arguments(t)[1], id(t))

        args = arguments(t)
        pretty_args = map(arg -> semantic_ast(arg), args)

        if op ∈ [+, -, *, /, ∧, ==]
            return InfixOp(Leaf(Symbol(op)), pretty_args, id(t))
        elseif op === ≤
            return InfixOp(Leaf(:≤), pretty_args, id(t))
        elseif op === ≥
            return InfixOp(Leaf(:≥), pretty_args, id(t))
        elseif op === tr
            return FuncEval(Leaf(:tr), pretty_args, id(t))
        end

        if !isempty(args)
            if applicable(adjoint, args[1]) && isequal(op, args[1]')
                return NormSquared(pretty_args[1], id(t))
            elseif isequal(op, adjoint)
                return Postfixed(pretty_args[1], Symbol("'"), id(t))
            end
        end

        pretty_op = semantic_ast(op)

        if length(args) == 1
            return FuncEval(pretty_op, pretty_args, id(t))
        else
            return InfixOp(pretty_op, pretty_args, id(t))
        end
    end
    
    return Leaf(id(t))
end

# ------------------------------------------------------
#  SHOW
# ------------------------------------------------------

Base.show(io::IO, x::Constant) = show(io, MIME"text/plain"(), x)
Base.show(io::IO, n::NormSquared) = show(io, MIME"text/plain"(), n)
Base.show(io::IO, con::ConstraintSet) = show(io, MIME"text/plain"(), con)
Base.show(io::IO, p::Postfixed) = show(io, MIME"text/plain"(), p)
Base.show(io::IO, opt::OptimizationProblem) = show(io, MIME"text/plain"(), opt)
Base.show(io::IO, ∇f::GradientOp) = show(io, MIME"text/plain"(), ∇f)
Base.show(io::IO, f::FuncEval) = show(io, MIME"text/plain"(), f)
Base.show(io::IO, op_node::InfixOp) = show(io, MIME"text/plain"(), op_node)
Base.show(io::IO, x::Mat) = show(io, MIME"text/plain"(), x)

Base.show(io::IO, ::MIME"text/plain", op::Leaf) = print(io, string(op.id))
Base.show(io::IO, op::Leaf) = print(io, string(op.id))

function Base.show(io::IO, ::MIME"text/plain", x::Constant)
    get(io, :use_id, true) && x.id ≠ nothing && return print(io, x.id)
    print(io, x.value)
end

function Base.show(io::IO, mime::MIME"text/plain", n::NormSquared)
    get(io, :use_id, true) && n.id ≠ nothing && return print(io, n.id)
    print(io, "‖")
    show(io, mime, n.expr)
    print(io, "‖²")
end

function Base.show(io::IO, mime::MIME"text/plain", con::ConstraintSet)
    get(io, :use_id, true) && con.id ≠ nothing && return print(io, con.id)
    show(io, mime, con.obj)
    print(io, " ∈ ")
    show(io, mime, con.set)
end

function Base.show(io::IO, ::MIME"text/plain", p::Postfixed)
    get(io, :use_id, true) && p.id ≠ nothing && return print(io, p.id)

    if p.expr isa Leaf
        print(io, p.expr, p.op)
    else
        print("(")
        show(io, p.expr)
        print(io, ")", p.op)
    end
end

function Base.show(io::IO, mime::MIME"text/plain", opt::OptimizationProblem)
    get(io, :use_id, true) && opt.id ≠ nothing && return print(io, opt.id)

    print(io, opt.sense, " "^5, opt.objective)
    for (i, con) in enumerate(opt.constraints)
        println()
        prefix = (i == 1) ? "subject to   " : " "^13
        print(io, prefix)
        show(io, mime, con)
    end
end

function Base.show(io::IO, mime::MIME"text/plain", ∇f::GradientOp)
    get(io, :use_id, true) && ∇f.id ≠ nothing && return print(io, ∇f.id)

    print(io, "∇", ∇f.func)
end

function Base.show(io::IO, mime::MIME"text/plain", f::FuncEval)
    get(io, :use_id, true) && f.id ≠ nothing && return print(io, f.id)

    show(io, mime, f.func)
    print(io, "(")
    for (i,arg) in enumerate(f.args)
        show(io, mime, arg)
        i < length(f.args) && print(io, ", ")
    end
    print(io, ")")
end

function Base.show(io::IO, ::MIME"text/plain", op_node::InfixOp)

    get(io, :use_id, true) && op_node.id ≠ nothing && return print(io, op_node.id)

    parent_op = op_node.op

    # Render and format each child element individually
    rendered_children = map(op_node.args) do child

        if child isa Symbol
            return string(child)
        end

        # Capture the child's text string safely using the active stream context
        buf = IOBuffer()
        ctx = IOContext(buf, io)
        show(ctx, child)
        child_str = String(take!(buf))
        
        # Determine the child's operator if it is an algebraic structure
        child_op = nothing
        if child isa InfixOp
            child_op = child.op
        elseif child isa Expr && child.head === :call
            child_op = Symbol(child.args[1])
        elseif iscall(child) # Fallback if a raw symbolic tree leaks through
            child_op = Symbol(operation(child))
        end

        if child_op !== nothing && parent_op in (:*, :∧, Symbol("'")) && child_op in (:+, :-, :≤, :≥, :(==))
            return "($child_str)"
        end
        
        return child_str
    end
    
    # Join the children with natural mathematical padding (e.g., "x + y")
    print(io, join(rendered_children, " $parent_op "))
end

function Base.show(io::IO, mime::MIME"text/plain", t::Mat)
    get(io, :use_id, true) && t.id ≠ nothing && return print(io, t.id)
    show(io, mime, t.args)
end

# ------------------------------------------------------
#  UTILITIES
# ------------------------------------------------------

function check_and_translate_identity(node)
    node isa BasicSymbolic && iszero(node) && return Leaf(Symbol(0))
    node isa BasicSymbolic && isone(node) && return Leaf(Symbol(1))
    return nothing
end
