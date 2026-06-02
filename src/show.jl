# export pretty_ast

# show(io::IO, ::MIME"text/plain", t::BasicSymbolic) = print(io, pretty_ast(t))
# # show(io::IO, t::BasicSymbolic) = print(io, render(t))

# needs_parentheses(x::BasicSymbolic) = istree(x) || starting_with_brackets(expr_str)

# starting_with_brackets(s::String) = startswith(s, "(") && endswith(s, ")")

# struct Postfixed
#     expr
#     op::Symbol
# end

# function show(io::IO, p::Postfixed)
#     expr_str = string(p.expr)
#     if any(c -> c in ['+', '-', '*'], expr_str) && !starting_with_brackets(expr_str)
#         print(io, "(", expr_str, ")", p.op)
#     else
#         print(io, expr_str, p.op)
#     end
# end

# struct CleanOp
#     name::String
# end

# CleanOp(s::Symbol...) = CleanOp(String(s...))

# Base.show(io::IO, op::CleanOp) = print(io, op.name)

# struct NormSquared
#     expr
# end

# show(io::IO, n::NormSquared) = print(io, "‖", n.expr, "‖²")

# struct OptimizationProblem
#     type::Symbol  # :maximize or :minimize
#     objective
#     constraints
# end

# function show(io::IO, opt::OptimizationProblem)
#     println(io, opt.type, " "^5, opt.objective)
    
#     flat_cons = []
#     flatten_constraints!(flat_cons, opt.constraints)
    
#     for (i, con) in enumerate(flat_cons)
#         if i == 1
#             println(io, "subject to   ", con)
#         else
#             println(io, " "^13, con)
#         end
#     end
# end

# struct ConstraintSet
#     obj
#     type::Symbol
# end

# show(io::IO, con::ConstraintSet) = print(io, con.obj, " ∈ ", con.type)

# # Helper to recursively unwrap \wedge, ∧, and, or & blocks
# function flatten_constraints!(list, node)
#     if istree(node)
#         op = operation(node)
#         op_str = string(op)
#         if op_str in ["\\wedge", "∧", "and", "&"]
#             for arg in arguments(node)
#                 flatten_constraints!(list, arg)
#             end
#             return
#         end
#     end
#     # Also handle standard Julia Expr trees if they were already processed
#     if node isa Expr && node.head === :call && string(node.args[1]) in ["\\wedge", "∧", "and", "&"]
#         for arg in node.args[2:end]
#             flatten_constraints!(list, arg)
#         end
#         return
#     end
    
#     push!(list, node)
# end

# function check_and_translate_identity(node)
#     try
#         if nameof(node) === :additive_identity
#             return 0
#         elseif nameof(node) === :multiplicative_identity
#             return 1
#         end
#     catch
#     end
#     # If it's a Term, check its operation head
#     if istree(node)
#         op = operation(node)
#         if op === additive_identity
#             return 0
#         elseif op === multiplicative_identity
#             return 1
#         end
#     end

#     # Fallback for raw function symbols or direct matches
#     if node === additive_identity #|| string(node) == "additive_identity"
#         return 0
#     elseif node === multiplicative_identity #|| string(node) == "multiplicative_identity"
#         return 1
#     end
    
#     return nothing
# end

# # Top level fallback safely bypasses translation unless it's an explicit match
# pretty_ast(t::Any) = (id = check_and_translate_identity(t); id !== nothing ? id : t)

# function extract_base_name(op)
#     # 1. Tree Case: If it's a compound expression tree, recursively drill down to the operation head
#     if istree(op)
#         inner_op = operation(op)
#         if inner_op !== op
#             return extract_base_name(inner_op)
#         end
        
#         # Look at the first argument if dealing with an unapplied functional head structure
#         inner_args = arguments(op)
#         if !isempty(inner_args)
#             return extract_base_name(inner_args[1])
#         end
#     end
    
#     # 2. Base Case: If it's a leaf node, safely extract its symbol by parsing its string
#     op_str = string(op)
#     # Remove wrappers, spaces, and adjoint syntaxes to isolate the pure symbol name
#     op_clean = replace(op_str, "adjoint" => "", "(" => "", ")" => "", " " => "", "⋆" => "")
#     return Symbol(op_clean)
# end

# # function pretty_ast(t::BasicSymbolic{FnType{Tuple{X}, X, Gradient}}) where X
# #     if istree(t)
# #         CleanOp("∇" * string(arguments(t)[1]))
# #     else
# #         CleanOp("∇" * string(nameof(t)))
# #     end
# # end

# function pretty_ast(t::BasicSymbolic)

#     identity_check = check_and_translate_identity(t)
#     if identity_check ≠ nothing
#         return identity_check
#     end

#     if t isa NormSquared
#         return Symbol("‖", pretty_ast(t.expr), "‖²")
#     end

#     if symtype(t) === Convex
#       return ConstraintSet(arguments(t)[1], :Convex)
#     end

#     if istree(t)
#         orig_op = operation(t)
#         orig_args = arguments(t)

#         if orig_op === constant
#           return orig_args[1]
#         end

#         try
#             if length(orig_args) == 1 && orig_op === orig_args[1]'
#                 return NormSquared(orig_args[1])
#             end
#         catch
#         end

#         op_identity = check_and_translate_identity(orig_op)
#         if op_identity !== nothing
#             orig_op = op_identity
#         end

#         # optimization problems
#         op_name = Symbol(orig_op)
#         if (op_name === :maximize || op_name === :minimize) && length(orig_args) == 2
#             pretty_obj = pretty_ast(orig_args[1])
#             pretty_con = pretty_ast(orig_args[2])
#             return OptimizationProblem(op_name, pretty_obj, pretty_con)
#         end

#         # 2. ALWAYS EVALUATE CHILD ARGUMENTS FIRST
#         pretty_args = map(pretty_ast, orig_args)

#         # 3. NESTED OPERATOR WRAPPERS (e.g., complex expressions like (x - xs)')
#         if orig_op === adjoint && !isempty(pretty_args)
#             first_arg = orig_args[1]
#             if SymbolicUtils.istree(first_arg)
#                 return Postfixed(pretty_args[1], Symbol("'"))
#             end
#         end

#         # 4. UNAPPLIED FUNCTION CHECKS (e.g., standalone f' or v')
#         if is_function(t)
#             category = function_category(t)
#             if !isempty(orig_args) && (!istree(orig_args[1]) || !is_function(orig_args[1]))
#                 if category === Gradient && orig_op === adjoint
#                     return Symbol("∇", extract_base_name(orig_args[1]))
#                 elseif category === LinearFunctional && orig_op === adjoint
#                     return Postfixed(orig_args[1], Symbol("'"))
#                 end
#             end
#         end

#         # =====================================================================
#         # 5. APPLIED FUNCTION & NORM SQUARED INTERCEPTOR
#         # =====================================================================
#         if orig_op isa BasicSymbolic && is_function(orig_op)
#             category = function_category(orig_op)
            
#             if category === Gradient
#                 grad_args = arguments(orig_op)
#                 if !isempty(grad_args)
#                     fn_name = extract_base_name(grad_args[1])
#                 else
#                     fn_name = extract_base_name(orig_op)
#                 end
                
#                 grad_op = Symbol("∇", fn_name)
#                 return Expr(:call, grad_op, pretty_args...)
                
#             elseif category === LinearFunctional
#                 if istree(orig_op)
                  
#                     pretty_head = pretty_ast(orig_op)
                    
#                     if length(pretty_args) == 1 && pretty_head isa Postfixed
#                         if string(pretty_head.expr) == string(pretty_args[1])
#                             return NormSquared(pretty_args[1])
#                         end
#                     end

#                     # Check B: Simple inner matching (e.g., x'(x))
#                     # Reach straight inside the adjoint operation to find the variable symbol
#                     adj_args = arguments(orig_op)
#                     if length(pretty_args) == 1 && !isempty(adj_args)
#                         if string(adj_args[1]) == string(pretty_args[1])
#                             # Success! Wrap it into a NormSquared tree
#                             return NormSquared(pretty_args[1])
#                         end
#                     end

#                     # return Expr(:call, pretty_head, pretty_args...)
#                     return Expr(:call, :*, pretty_head, pretty_args...)
#                 else
#                     fn_name = extract_base_name(orig_op)
                    
#                     if length(pretty_args) == 1 && string(fn_name) == string(pretty_args[1])
#                         return NormSquared(pretty_args[1])
#                     end
                    
#                     functional_op = Symbol(fn_name, "'")
#                     return Expr(:call, functional_op, pretty_args...)
#                 end
#             end
#         end

#         # 6. ALGEBRAIC MULTIPLICATION INTERCEPTOR
#         op_str = string(orig_op)
#         if (op_str == "*" || contains(op_str, "mul") || contains(lowercase(string(typeof(orig_op))), "mul")) && !isempty(pretty_args)
#             return Expr(:call, :*, pretty_args...)
#         end

#         # 7. EVALUATE THE OPERATOR HEAD FOR FALLBACKS
#         pretty_op = pretty_ast(orig_op)

#         if pretty_op isa Postfixed
#             return Expr(:call, :*, pretty_op, pretty_args...)
#         end

#         if pretty_op === 0 || pretty_op === 1
#             return pretty_op
#         end

#         # =====================================================================
#         # 8. FIXED: LATEX OPERATOR TRANSLATION LAYER
#         # =====================================================================
#         op_name_str = string(pretty_op)
#         if op_name_str == "<=" || op_name_str == "≤"
#             pretty_op = :≤
#         elseif op_name_str == ">=" || op_name_str == "≥"
#             pretty_op = :≥
#         elseif pretty_op isa Symbol
#             # CRITICAL GUARD: If the head is already an unapplied function 
#             # node (like ∇f or f'), DO NOT overwrite it with its base name!
#             if !is_function(orig_op)
#                 pretty_op = extract_base_name(orig_op)
#             end
#         end

#         if pretty_op isa Symbol || pretty_op isa Function
#             return Expr(:call, Symbol(pretty_op), pretty_args...)
#         else
#             return Expr(:call, pretty_op, pretty_args...)
#         end
#     end

#     # 9. BASE CASE: Pure Leaf Nodes
#     if t isa BasicSymbolic
#         sym_name = t.name
#         if typeof(t).parameters[1] <: FnType
#             category = function_category(t)
#             if category === Gradient
#                 return Symbol("∇", sym_name)
#             elseif category === LinearFunctional
#                 return Symbol(sym_name, "'")
#             end
#         end
#         return sym_name
#     end

#     return t
# end


# # export render

# # render(node) = node

# # function render(node::BasicSymbolic)
# #     if istree(node)
# #         return render_tree(operation(node), arguments(node))
# #     else
# #         render_leaf(node)
# #     end
# # end

# # render_tree(op, args) = Expr(:call, render(op), map(render, args)...)

# # function render_leaf(node)
# #     try
# #         return CleanOp(Symbol(Base.nameof(node)))
# #     catch
# #         return node
# #     end
# # end

# # function render_tree(::typeof(+), args)
# #     return join( map(render, args), " + ")
# # end

# # function render_tree(::typeof(-), args)
# #     rendered_args = map(render, args)
# #     if length(args) == 1
# #         return "-$(rendered_args[1])" # Handle unary minus like -x
# #     end
# #     return join(rendered_args, " - ")
# # end

# # function render_child(parent_op, child)
# #     if istree(child)
# #         child_op = operation(child)
        
# #         # If a '+' or '-' is inside a '*', wrap it in parentheses!
# #         if parent_op in (*, /) && child_op in (+, -)
# #             return "($(render(child)))"
# #         end
# #     end
# #     return render(child)
# # end

# # # Update your multiplication dispatch to use the child helper
# # function render_tree(op::typeof(*), args)
# #     rendered_args = [render_child(op, arg) for arg in args]
# #     return join(rendered_args, " * ")
# # end

# # using LinearAlgebra

# # # Specialized dispatch for the adjoint operator
# # function render_tree(::typeof(adjoint), args)
# #     # The adjoint operator always has exactly one argument (the vector or matrix)
# #     vec = args[1]
    
# #     # If the vector itself is a compound tree expression (like x + y),
# #     # wrap it in parentheses before adding the tick: (x + y)'
# #     if SymbolicUtils.istree(vec) && SymbolicUtils.operation(vec) in (+, -, *)
# #         return "($(render(vec)))'"
# #     end
    
# #     # Otherwise, print it cleanly as x'
# #     return "$(render(vec))'"
# # end


using SymbolicUtils
import LinearAlgebra: adjoint

export pretty_ast

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
    type::Symbol  # :maximize or :minimize
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
    f = pretty_ast(arguments(t)[1])
    return CleanOp(Symbol(:∇, f))
end

function pretty_ast(t::BasicSymbolic{FnType{Tuple{X}, Y, LinearFunctional}}) where {X,Y}
    return Postfixed(t.name, Symbol("'"))
end

function pretty_ast(t::BasicSymbolic)
    identity_check = check_and_translate_identity(t)
    identity_check ≠ nothing && return identity_check

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
#  3. PASS 2: STRING RENDERING ENGINE (`render`)
# ====================================================================

# Entry orchestrator: converts the sanitized math AST to a structural string
render(x) = string(pretty_ast(x))
render(x::String) = x

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

# Infix math rendering overrides
render(e::Expr) = render_expr_node(e.head, e.args)
render_expr_node(head, args) = string(Expr(head, args...)) # Fallback

function render_expr_node(head::Symbol, args)
    head !== :call && return string(Expr(head, args...))
    op = Symbol(args[1])
    
    if op in (:+, :-, :*, :≤, :≥, :(==))
        rendered_children = [render_child(op, arg) for arg in args[2:end]]
        return join(rendered_children, " $op ")
    end
    
    # Standard prefix functions: f(x, y)
    return string(op) * "(" * join(map(render, args[2:end]), ", ") * ")"
end

# Optimization formatting pipeline
function Base.show(io::IO, opt::OptimizationProblem)
    println(io, opt.type, " "^5, render(opt.objective))
    flat_cons = []
    flatten_constraints!(flat_cons, opt.constraints)
    
    for (i, con) in enumerate(flat_cons)
        prefix = (i == 1) ? "subject to   " : " "^13
        println(io, prefix, render(con))
    end
end

# ====================================================================
#  4. SYSTEM UTILITIES & UTILS HELPERS
# ====================================================================

function flatten_constraints!(list, node)
    if istree(node)
        op_str = string(operation(node))
        if op_str in ["\\wedge", "∧", "and", "&"]
            for arg in arguments(node) flatten_constraints!(list, arg) end
            return
        end
    elseif node isa Expr && node.head === :call && string(node.args[1]) in ["\\wedge", "∧", "and", "&"]
        for arg in node.args[2:end] flatten_constraints!(list, arg) end
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

function extract_base_name(op)
    if op isa CleanOp
        return Symbol(op.name)
    end

    if istree(op)
        inner_op = operation(op)
        inner_op !== op && return extract_base_name(inner_op)
        inner_args = arguments(op)
        !isempty(inner_args) && return extract_base_name(inner_args[1])
    end
    op_clean = replace(string(op), "adjoint" => "", "(" => "", ")" => "", " " => "", "⋆" => "")
    return Symbol(op_clean)
end
