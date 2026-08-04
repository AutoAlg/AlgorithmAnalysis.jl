function Base.show(io::IO, t::Node{<:NodeType})
    show_node(io, t, get(io, :compact, false), nothing)
end

function Base.show(io::IO, ::MIME"text/plain", t::Node{<:NodeType})
    show_node(io, t, get(io, :compact, false), nothing)
end

function Base.show(io::IO, t::Node{FnType{Tuple{X}, Y, Z}}) where {X, Y, Z<:Category}
    show_node(io, t, get(io, :compact, false), nothing)
end

function Base.show(io::IO, ::MIME"text/plain", t::Node{FnType{Tuple{X}, Y, Z}}) where {X, Y, Z<:Category}
    show_node(io, t, get(io, :compact, false), nothing)
end

function show_node(io::IO, t::Node, use_id::Bool, parent_op::Union{Nothing,Symbol}=nothing)
    if parent_op !== nothing && should_wrap(parent_op, t)
        print(io, "(")
        show_node_core(io, t, use_id)
        print(io, ")")
    else
        show_node_core(io, t, use_id)
    end
end

function show_node_core(io::IO, t::Node, use_id::Bool)
    use_id && has_id(t) && return print(io, id(t))

    stype = symtype(t)
    if stype <: Optimization
        return show_optimization(io, t, use_id)
    elseif stype <: LyapunovCertificate
        return show_lyapunov(io, t, use_id)
    elseif stype <: Transition
        return show_transition(io, t, use_id)
    elseif stype <: MatrixSpace
        return show_matrixspace(io, t, use_id)
    elseif stype <: Prop
        return show_prop(io, t, use_id)
    elseif stype <: Bool
        return show_bool(io, t, use_id)
    elseif iscall(t)
        return show_call(io, t, use_id)
    else
        return show_atom(io, t, use_id)
    end
end

show_value(io::IO, value::Any, ::Bool, ::Union{Nothing,Symbol}=nothing) = print(io, value)
show_value(io::IO, value::Node, use_id::Bool, parent_op::Union{Nothing,Symbol}=nothing) = show_node(io, value, use_id, parent_op)

function show_atom(io::IO, t::Node, ::Bool)
    if has_id(t)
        print(io, id(t))
    else
        print(io, nameof(symtype(t)))
    end
end

function show_optimization(io::IO, t::Node, use_id::Bool)
    use_id && has_id(t) && return print(io, id(t))

    print(io, sense(t), " "^5)
    if !is_feasibility(t)
        show_value(io, objective(t), use_id)
    end

    for (i, con) in enumerate(constraint(t))
        println(io)
        prefix = (i == 1) ? "subject to   " : " "^13
        print(io, prefix)
        show_value(io, con, use_id)
    end
end

function show_lyapunov(io::IO, t::Node, use_id::Bool)
    use_id && has_id(t) && return print(io, id(t))

    print(io, "Lyapunov-based stability certification")
    print(io, "\n  Rate:        ")
    if isnothing(rate(t))
        print(io, :ρₒₚₜ)
    else
        show_value(io, rate(t), use_id)
    end
    print(io, "\n  Performance: ")
    show_value(io, performance(t), use_id)
    print(io, "\n  Constraints: ")
    for (i, con) in enumerate(flatten(constraint(t)))
        i > 1 && print(io, "\n", " "^15)
        show_value(io, con, use_id)
    end
end

function show_transition(io::IO, t::Node, use_id::Bool)
    use_id && has_id(t) && return print(io, id(t))
    args = arguments(t)
    show_value(io, args[1], use_id, :→)
    print(io, " → ")
    show_value(io, args[2], use_id, :→)
end

function show_matrixspace(io::IO, t::Node, use_id::Bool)
    use_id && has_id(t) && return print(io, id(t))

    !iscall(t) && return print(io, id(t))
    op = operation(t)
    op_sym = op_symbol(op)
    args = arguments(t)
    if op_sym in (:+, :-, :*, :/)
        return show_infix(io, op, args, use_id)
    end

    A = mat(args)
    print(io, '[', join((join(repr.(r), " ") for r in eachrow(A)), "; "), ']')
end

function show_prop(io::IO, t::Node, use_id::Bool)
    use_id && has_id(t) && return print(io, id(t))

    stype = symtype(t)
    if isequal(stype, Satisfied)
        return print(io, true)
    elseif isequal(stype, Unsatisfied)
        return print(io, false)
    elseif !iscall(t)
        return show_value(io, id(t), use_id)
    end

    op = operation(t)
    op_sym = op_symbol(op)
    args = arguments(t)
    if op_sym in (:≤, :∧)
        return show_infix(io, op, args, use_id)
    elseif op_sym == :(==)
        return show_infix(io, :(=), args, use_id)
    elseif op_sym == :<=
        return show_infix(io, :≤, args, use_id)
    elseif op_sym == :>=
        return show_infix(io, :≥, args, use_id)
    elseif stype == PositiveSemidefinite
        show_value(io, args[1], use_id)
        print(io, " ⪰ 0")
        return
    elseif op_sym == :smooth_convex
        show_value(io, args[1], use_id)
        print(io, " ∈ SmoothConvex(")
        show_value(io, args[2], use_id)
        print(io, ")")
        return
    elseif op_sym == :sector_bounded
        show_value(io, args[1], use_id)
        print(io, " ∈ SectorBounded(")
        show_value(io, args[2], use_id)
        print(io, ", ")
        show_value(io, args[3], use_id)
        print(io, ")")
        return
    end

    show_value(io, args[1], use_id)
    print(io, " ∈ ", nameof(stype))
end

function show_bool(io::IO, t::Node, use_id::Bool)
    use_id && has_id(t) && return print(io, id(t))

    if iscall(t)
        op = operation(t)
        op_sym = op_symbol(op)
        args = arguments(t)
        if op_sym in (Symbol("=="), :≤, :≥)
            return show_infix(io, op, args, use_id)
        end
    end

    show_atom(io, t, use_id)
end

function show_call(io::IO, t::Node, use_id::Bool)
    op = operation(t)
    op_sym = op_symbol(op)
    args = arguments(t)

    if op_sym == :constant
        return show_value(io, args[1], use_id)
    elseif op_sym == :one
        return show_value(io, 1, use_id)
    elseif op_sym == :zero
        return show_value(io, 0, use_id)
    elseif op_sym == :tr
        print(io, "tr(")
        show_value(io, args[1], use_id)
        print(io, ")")
        return
    end

    if !isempty(args)
        # u'(u) → ‖u‖²
        if symtype(t) <: R &&
            length(args) == 1 &&
            op isa Node &&
            iscall(op) &&
            operation(op) === adjoint &&
            length(arguments(op)) == 1 &&
            isequal(arguments(op)[1], args[1])
            
            print(io, "‖")
            show_value(io, args[1], use_id)
            print(io, "‖²")
            return
        end

        if op isa Node
            if !iscall(op) && op_symbol(op) == :∇ && length(args) == 1
                print(io, "∇")
                show_value(io, args[1], use_id)
                return
            end

            show_value(io, op, use_id)
            print(io, "(")
            for (i, arg) in enumerate(args)
                show_value(io, arg, use_id)
                i < length(args) && print(io, ", ")
            end
            print(io, ")")
            return

        elseif op === adjoint
            if args[1] isa Node && !iscall(args[1])
                show_value(io, args[1], use_id)
            else
                print(io, "(")
                show_value(io, args[1], use_id)
                print(io, ")")
            end
            print(io, "'")
            return
        end
    end

    if op_sym == :- && length(args) == 1
        print(io, "-")
        show_value(io, args[1], use_id, :-)
        return
    elseif op_sym in (:+, :-, :*, :/, :∧, :(==), :<=, :>=)
        return show_infix(io, op, args, use_id)
    end

    show_value(io, op, use_id)
    print(io, "(")
    for (i, arg) in enumerate(args)
        show_value(io, arg, use_id)
        i < length(args) && print(io, ", ")
    end
    print(io, ")")
end

function show_infix(io::IO, op, args, use_id::Bool)
    parent_op = op_symbol(op)
    rendered_children = map(args) do child
        render_child(child, io, use_id, parent_op)
    end

    print(io, join(rendered_children, " $parent_op "))
end

function render_child(child, io::IO, use_id::Bool, parent_op::Union{Nothing,Symbol}=nothing)
    buf = IOBuffer()
    child_io = IOContext(buf, :compact => get(io, :compact, false), :use_id => use_id)
    if child isa Node
        show_node(child_io, child, use_id, parent_op)
    else
        show(child_io, child)
    end
    return String(take!(buf))
end

function should_wrap(parent_op::Symbol, t::Node)
    iscall(t) || return false
    child_op = op_symbol(operation(t))

    if parent_op in (:*, :/, :∧, Symbol("'"))
        return child_op in (:+, :-, :≤, :>=, :≥, :(==), :<=)
    elseif parent_op == :-
        return child_op in (:+, :-, :≤, :>=, :≥, :(==), :<=)
    elseif parent_op == :adjoint
        return true
    elseif parent_op == :→
        return child_op in (:+, :-)
    end

    return false
end

function op_symbol(op)
    if op isa Symbol
        return op
    elseif op isa Node
        if iscall(op)
            return op_symbol(operation(op))
        elseif has_id(op)
            return id(op)
        else
            return nameof(symtype(op))
        end
    elseif op isa Function
        return Symbol(op)
    else
        return Symbol(string(op))
    end
end
