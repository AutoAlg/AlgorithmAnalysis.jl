export R, Rⁿ, Sⁿ, F, VectorSpace, field, additive_identity, multiplicative_identity
export zero, one, ∧, maximize, objective, constraint
export is_function, function_category, Convex
export @var, @alg, @def
export Gradient, LinearFunctional, DifferentiableFunctional, ∇, Gram

abstract type VectorSpace{F} end
abstract type MatrixSpace{F} <: VectorSpace{F} end
abstract type R <: Real end

struct Rⁿ <: VectorSpace{R} end
struct Sⁿ <: MatrixSpace{R} end

field(::Type{<:VectorSpace{R}}) = R
field(::BasicSymbolic{V}) where {F, V<:VectorSpace{F}} = F

function additive_identity end
function multiplicative_identity end
function satisfied end
function gradient end
function Gram end

abstract type Category end
abstract type LinearFunctional <: Category end
abstract type DifferentiableFunctional <: Category end
abstract type Gradient <: Category end

abstract type Constraint end
abstract type Satisfied <: Constraint end
abstract type Unsatisfied <: Constraint end
abstract type Equality{T} <: Constraint end
abstract type LessThanOrEqualTo{T} <: Constraint end
abstract type Convex <: Constraint end

abstract type Optimization end
abstract type Minimization <: Optimization end
abstract type Maximization <: Optimization end
abstract type Feasibility <: Optimization end

function constant end

const ∇ = Sym{FnType{Tuple{FnType{Tuple{Rⁿ}, R, AlgorithmAnalysis.DifferentiableFunctional}}, FnType{Tuple{Rⁿ}, Rⁿ, Gradient}, Nothing}}(:∇)

zero(::Type{Rⁿ}) = Sym{Rⁿ}(:additive_identity)
zero(::Type{R}) = Sym{R}(:additive_identity)
one(::Type{R}) = Sym{R}(:multiplicative_identity)
R(val::Real) = Term{R}(constant, [val])

function F(V::Type{<:VectorSpace})
  return FnType{Tuple{V}, field(V), DifferentiableFunctional}
end

function +(u::BasicSymbolic{V}, v::BasicSymbolic{V}) where {V<:VectorSpace}
  return Term{V}(+, [u, v])
end

+(u::BasicSymbolic{<:VectorSpace}) = u

function -(u::BasicSymbolic{V}, v::BasicSymbolic{V}) where {V<:VectorSpace}
  return Term{V}(-, [u, v])
end

function -(v::BasicSymbolic{V}) where {V<:VectorSpace}
  return Term{V}(-, [v])
end

function *(scalar::BasicSymbolic{F}, v::BasicSymbolic{V}) where {F, V<:VectorSpace{F}}
  return Term{V}(*, [scalar, v])
end

function *(scalar::F, v::BasicSymbolic{V}) where {F, V<:VectorSpace{F}}
  return Term{F}(*, [scalar, v])
end

function ⋅(u::BasicSymbolic{V}, v::BasicSymbolic{V}) where {F, V<:VectorSpace{F}}
  return Term{F}(⋅, [u, v])
end

function adjoint(x::BasicSymbolic{V}) where {F, V<:VectorSpace{F}}
  return Term{FnType{Tuple{V}, F, LinearFunctional}}(adjoint, [x])
end

function adjoint(f::BasicSymbolic{FnType{Tuple{V}, F, LinearFunctional}}) where {F, V<:VectorSpace{F}}
  # If it's already an adjoint term tree, peel it off to prevent double nesting
  if istree(f) && operation(f) === adjoint
    return arguments(f)[1]
  end
  return Term{V}(adjoint, [f])
    # return Sym{V}( Symbol(f, "'") )
end

function adjoint(f::BasicSymbolic{FnType{Tuple{V}, F, DifferentiableFunctional}}) where {F, V<:VectorSpace{F}}
#   return Term{FnType{Tuple{V}, V, Gradient}}(∇, [f])
    return ∇(f)
end

is_gradient(x) = is_function(x) && operator(x) === ∇


function ∈(f::BasicSymbolic{FnType{Tuple{V}, F, DifferentiableFunctional}}, ::Type{Convex}) where {F, V<:VectorSpace{F}}
  return Term{Convex}(∈, [f])
end

function (f::BasicSymbolic{FnType{Tuple{V}, F, Nothing}})(x::V) where {F, V<:VectorSpace{F}}
  return Term{F}(f, [x])
end

function ==(x::BasicSymbolic{T}, y::BasicSymbolic{T}) where {T}
  return Term{Equality{T}}(==, [x,y])
end

function ≤(x::BasicSymbolic{T}, y::BasicSymbolic{T}) where {T}
  return Term{LessThanOrEqualTo{T}}(≤, [x,y])
end

function ≥(x::BasicSymbolic{T}, y::BasicSymbolic{T}) where {T}
  return Term{LessThanOrEqualTo{T}}(≤, [y,x])
end

function ∧(x::BasicSymbolic{<:Constraint}, y::BasicSymbolic{<:Constraint})
  return Term{Constraint}(∧, [x, y])
end

function Gram(vecs::BasicSymbolic{T}...) where {F, T<:VectorSpace{F}}
    return Term{MatrixSpace{F}}(Gram, vecs)
end

function maximize(obj::BasicSymbolic, con::BasicSymbolic{Constraint})
  return Term{Maximization}(maximize, [obj, con])
end

objective(opt::BasicSymbolic{Maximization}) = arguments(opt)[1]
constraint(opt::BasicSymbolic{Maximization}) = arguments(opt)[2]

is_function(t) = t isa BasicSymbolic && typeof(t).parameters[1] <: FnType

function function_category(t::BasicSymbolic)
  fn_type = typeof(t).parameters[1]
  if !is_function(t)
    error("$t is not a function")
  end
  return fn_type.parameters[3]
end

macro var(args...)
    syms_args = Any[]
    
    # Internal helper to safely process an individual 'x \in R' statement
    function process_statement!(out, expr)
        if expr isa Expr && expr.head === :call && (expr.args[1] === :in || expr.args[1] === :∈)
            var_name = expr.args[2] # e.g., :x
            var_type = expr.args[3] # e.g., :R
            
            # Convert to SymbolicUtils typed format: x::R
            push!(out, Expr(:(::), var_name, var_type))
        else
            error("Malformed @var statement. Expected format: x \\in R, got: $expr")
        end
    end

    # -----------------------------------------------------------------
    # ROUTING LOGIC: Determine the input syntax style
    # -----------------------------------------------------------------
    if length(args) == 1 && args[1] isa Expr && args[1].head === :block
        # STYLE A: User passed a begin...end block
        for line in args[1].args
            if line isa LineNumberNode
                continue # Skip compiler metadata lines
            end
            process_statement!(syms_args, line)
        end
    else
        # STYLE B: User passed a parenthesized list e.g., @var(x \in R, y \in Q)
        for arg in args
            process_statement!(syms_args, arg)
        end
    end
    
    # Forward the compiled type definitions straight into the @syms macro engine
    return esc(Expr(:macrocall, Symbol("@syms"), __source__, syms_args...))
end

macro def(assignment)
    # Ensure the input is a valid assignment expression: a = b
    if !(assignment isa Expr && assignment.head == :(=))
        error("Use syntax: @def x = expr")
    end
    
    var_name = assignment.args[1]  # The symbol on the left (e.g., :x)
    expr = assignment.args[2]      # The expression on the right
    
    # Generate the code to attach metadata at runtime
    return esc(quote
        # 1. Evaluate the expression
        local evaluated_expr = $expr
        
        # 2. Attach the variable name into the SymbolicUtils metadata dictionary
        evaluated_expr = setmetadata(evaluated_expr, Symbol, $(QuoteNode(var_name)))
        
        # 3. Bind it to the local variable name in the user's workspace
        $var_name = evaluated_expr
    end)
end

has_id(node::BasicSymbolic) = hasmetadata(node, Symbol)
get_id(node::BasicSymbolic) = has_id(node) ? getmetadata(node, Symbol) : nothing

macro alg(block_expr)
    # Ensure the input is a begin...end block
    if !(block_expr isa Expr && block_expr.head === :block)
        error("Expected a begin...end block for @alg.")
    end
    
    # We will build a new block containing the processed lines
    new_body = Any[]
    
    for line in block_expr.args
        # Preserve compiler line-number metadata for clean stack traces
        if line isa LineNumberNode
            push!(new_body, line)
            continue
        end
        
        # INTERCEPT STEP: Is this line an 'x \in S' statement?
        if line isa Expr && line.head === :call && (line.args[1] === :in || line.args[1] === :∈)
            # Reconstruct this specific line as a call to your @var macro
            var_macro_call = Expr(:macrocall, Symbol("@var"), __source__, line)
            push!(new_body, var_macro_call)
        else
            # PASS-THROUGH STEP: Leave all other standard Julia code completely alone
            push!(new_body, line)
        end
    end
    
    # Package the processed lines back into an executable block
    return esc(Expr(:block, new_body...))
end
