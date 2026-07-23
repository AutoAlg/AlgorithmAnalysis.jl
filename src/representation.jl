export R, Rⁿ, Sⁿ, F, VectorSpace, MatrixSpace, field
export zero, one, ∧, maximize, minimize, objective, constraint
export is_function, function_category, Convex
export @var, @alg, @def
export Gradient, LinearFunctional, DifferentiableFunctional, ∇, Gram
export PositiveSemidefinite
export has_id, id, set_id, ID
export satisfied, unsatisfied
export ⪯, ⪰, to_symbolic, tr
export convex, smooth_convex

leaf(sym::Symbol, T) = Sym{T}(sym)

to_symbolic(x::Any) = convert(BasicSymbolic, x)

abstract type ID end

has_id(::Any) = false
has_id(t::BasicSymbolic) = hasmetadata(t, ID) || hasproperty(t, :name)
id(t::BasicSymbolic) = hasmetadata(t, ID) ? getmetadata(t, ID) : (hasproperty(t, :name) ? t.name : nothing)
set_id(node::BasicSymbolic, sym::Symbol) = setmetadata(node, ID, sym)
set_id(::Any, ::Symbol) = nothing

abstract type Field end
abstract type VectorSpace{F} end
abstract type MatrixSpace{F} end
abstract type R <: Field end

abstract type Rⁿ <: VectorSpace{R} end
abstract type Sⁿ <: MatrixSpace{R} end

Base.convert(::Type{<:BasicSymbolic}, val::Number) = R(val)
Base.convert(::Type{BasicSymbolic{R}}, val::Number) = R(val)
Base.promote_rule(::Type{BasicSymbolic{R}}, ::Type{<:Number}) = BasicSymbolic{R}

for op in (:+, :-, :*, :/, :^, :≤, :≥, :(==))
    @eval begin
        Base.$op(x::Number, y::BasicSymbolic{R}) = $op(promote(x, y)...)
        Base.$op(x::BasicSymbolic{R}, y::Number) = $op(promote(x, y)...)
    end
end

field(::Type{<:VectorSpace{F}}) where F = F
field(::BasicSymbolic{V}) where {F,V<:VectorSpace{F}} = F

function satisfied end

abstract type Category end
abstract type LinearFunctional <: Category end
abstract type DifferentiableFunctional <: Category end
abstract type Gradient <: Category end
abstract type GramMatrix <: Category end

abstract type Constraint end
abstract type Satisfied <: Constraint end
abstract type Unsatisfied <: Constraint end
abstract type Equality{T} <: Constraint end
abstract type LessThanOrEqualTo{T} <: Constraint end
abstract type Convex <: Constraint end
abstract type PositiveSemidefinite <: Constraint end

abstract type Optimization end
abstract type Minimization <: Optimization end
abstract type Maximization <: Optimization end
abstract type Feasibility <: Optimization end

function constant end

const ∇ = Sym{FnType{Tuple{FnType{Tuple{Rⁿ},R,DifferentiableFunctional}},FnType{Tuple{Rⁿ},Rⁿ,Gradient},Nothing}}(:∇)

const Gram = Sym{FnType{Tuple{Vararg{Rⁿ}}, MatrixSpace{R}, Nothing}}(:Gram)

zero(::Type{Rⁿ}) = Term{Rⁿ}(zero, [])
zero(::Type{R}) = Term{R}(zero, [])
one(::Type{R}) = Term{R}(one, [])
R(val::Real) = Term{R}(constant, [val])
satisfied() = Sym{Satisfied}()
unsatisfied() = Sym{Unsatisfied}()

iszero(x::BasicSymbolic) = iscall(x) && isequal(operation(x), zero)
isone(x::BasicSymbolic) = iscall(x) && isequal(operation(x), one)

function Sⁿ(A::Matrix{BasicSymbolic{R}})
    size(A,1) ≠ size(A,2) && error("Matrix $A is not square")
    n = size(A,1)
    # for i in 1:n
    #     for j in 1:i
    #         if !isequal(A[i,j], A[j,i])
    #             error("Matrix $A is not symmetric")
    #         end
    #     end
    # end
    return Term{Sⁿ}(Matrix, vec(A))
end

function Base.convert(::Type{<:BasicSymbolic}, A::Matrix)
    Sⁿ(Base.convert.(BasicSymbolic, A))
end

tr(A::BasicSymbolic{Sⁿ}) = Term{R}(tr, [A])
tr(A::Matrix) = la.tr(A)

+(x::T, y::T) where {T<:BasicSymbolic{Sⁿ}} = Term{Sⁿ}(+, [x, y])
*(x::T, y::T) where {T<:BasicSymbolic{Sⁿ}} = Term{Sⁿ}(*, [x, y])
-(x::T, y::T) where {T<:BasicSymbolic{Sⁿ}} = Term{Sⁿ}(-, [x, y])
/(x::T, y::T) where {T<:BasicSymbolic{Sⁿ}} = Term{Sⁿ}(/, [x, y])
⋅(x::T, y::T) where {T<:BasicSymbolic{Sⁿ}} = Term{Sⁿ}(⋅, [x, y])

+(x::T...) where {F<:Field, T<:BasicSymbolic{F}} = Term{F}(+, x)
*(x::T...) where {F<:Field, T<:BasicSymbolic{F}} = Term{F}(*, x)
-(x::T, y::T) where {F<:Field, T<:BasicSymbolic{F}} = Term{F}(-, [x, y])
/(x::T, y::T) where {F<:Field, T<:BasicSymbolic{F}} = Term{F}(/, [x, y])

function F(V::Type{<:VectorSpace})
    return FnType{Tuple{V},field(V),DifferentiableFunctional}
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

function *(scalar::BasicSymbolic{F}, v::BasicSymbolic{V}) where {F,V<:VectorSpace{F}}
    return Term{V}(*, [scalar, v])
end

# function *(scalar::F, v::BasicSymbolic{V}) where {F,V<:VectorSpace{F}}
#     return Term{F}(*, [scalar, v])
# end

function ⋅(u::BasicSymbolic{V}, v::BasicSymbolic{V}) where {F,V<:VectorSpace{F}}
    return Term{F}(⋅, [u, v])
end

function adjoint(x::BasicSymbolic{V}) where {F,V<:VectorSpace{F}}
    iszero(x) && return Term{FnType{Tuple{V},F,LinearFunctional}}(zero, [])
    return Term{FnType{Tuple{V},F,LinearFunctional}}(adjoint, [x])
end

function adjoint(f::BasicSymbolic{FnType{Tuple{V},F,LinearFunctional}}) where {F,V<:VectorSpace{F}}
    # If it's already an adjoint term tree, peel it off to prevent double nesting
    if iscall(f) && isequal(operation(f), adjoint)
        return arguments(f)[1]
    end
    return Term{V}(adjoint, [f])
    # return Sym{V}( Symbol(f, "'") )
end

function adjoint(f::BasicSymbolic{FnType{Tuple{V},F,DifferentiableFunctional}}) where {F,V<:VectorSpace{F}}
    #   return Term{FnType{Tuple{V}, V, Gradient}}(∇, [f])
    return ∇(f)
end

is_gradient(x) = is_function(x) && isequal(operator(x), ∇)


Base.literal_pow(::typeof(^), x::BasicSymbolic{<:VectorSpace}, ::Val{2}) = x'(x)

# function ∈(f::BasicSymbolic{FnType{Tuple{V},F,DifferentiableFunctional}}, ::Type{Convex}) where {F,V<:VectorSpace{F}}
#     return Term{Convex}(∈, [f])
# end

function convex(f::BasicSymbolic{FnType{Tuple{V},F,DifferentiableFunctional}}) where {F,V<:VectorSpace{F}}
    return Term{Convex}(∈, [f])
end

function smooth_convex(f::BasicSymbolic{FnType{Tuple{V},F,DifferentiableFunctional}}, L::BasicSymbolic{F}) where {F,V<:VectorSpace{F}}
    return Term{Constraint}(smooth_convex, [f, L])
end

# function ∈(G::BasicSymbolic{<:MatrixSpace}, ::Type{PositiveSemidefinite})
#     return Term{PositiveSemidefinite}(∈, [G])
# end

function ⪯(a::Number, A::BasicSymbolic{<:MatrixSpace})
    if iszero(a)
        return Term{PositiveSemidefinite}(∈, [A])
    else
        error("Positive semidefinite constraint not implemented")
    end
end

⪰(A::BasicSymbolic{<:MatrixSpace}, a::Number) = ⪯(a,A)

function (f::BasicSymbolic{FnType{Tuple{V},F,Nothing}})(x::V) where {F,V<:VectorSpace{F}}
    return Term{F}(f, [x])
end

function ==(x::BasicSymbolic{T}, y::BasicSymbolic{T}) where {T}
    return Term{Equality{T}}(==, [x, y])
end

function ≤(x::BasicSymbolic{T}, y::BasicSymbolic{T}) where {T}
    return Term{LessThanOrEqualTo{T}}(≤, [x, y])
end

function ≥(x::BasicSymbolic{T}, y::BasicSymbolic{T}) where {T}
    return Term{LessThanOrEqualTo{T}}(≤, [y, x])
end

function ∧(args::BasicSymbolic{<:Constraint}...)
    flat_args = Any[]
    for arg in args
        if iscall(arg) && operation(arg) === ∧
            append!(flat_args, arguments(arg))
        elseif isequal(arg, unsatisfied())
            return unsatisfied()
        elseif !isequal(arg, satisfied())
            push!(flat_args, arg)
        end
    end
    return Term{Constraint}(∧, flat_args)
end

∧(x::BasicSymbolic{<:Constraint}, y::Bool) = y ? x : unsatisfied()
∧(x::Bool, y::BasicSymbolic{<:Constraint}) = x ? y : unsatisfied()

# function Gram(vecs::BasicSymbolic{T}...) where {F,T<:VectorSpace{F}}
#     return Term{MatrixSpace{F}}(Gram, vecs)
# end

function maximize(obj::BasicSymbolic, con::BasicSymbolic{<:Constraint})
    return Term{Optimization}(maximize, [obj, con])
end

function minimize(obj::BasicSymbolic, con::BasicSymbolic{<:Constraint})
    return Term{Optimization}(minimize, [obj, con])
end

function feasible(con::BasicSymbolic{<:Constraint})
    return Term{Optimization}(feasible, [con])
end

sense(opt::BasicSymbolic{Optimization}) = Symbol(operation(opt))
is_minimization(opt::BasicSymbolic{Optimization}) = isequal(sense(opt), :minimize)
is_maximization(opt::BasicSymbolic{Optimization}) = isequal(sense(opt), :maximize)
is_feasibility(opt::BasicSymbolic{Optimization}) = isequal(sense(opt), :feasible)

function objective(opt::BasicSymbolic{Optimization})
    is_feasibility(opt) ? nothing : arguments(opt)[1]
end

function constraint(opt::BasicSymbolic{Optimization})
    is_feasibility(opt) ? arguments(opt)[1] : arguments(opt)[2]
end

is_function(t) = t isa BasicSymbolic && typeof(t).parameters[1] <: FnType

function function_category(t::BasicSymbolic)
    fn_type = typeof(t).parameters[1]
    if !is_function(t)
        error("$t is not a function")
    end
    return fn_type.parameters[3]
end

function getindex(A::BasicSymbolic{MatrixSpace{F}}, i::Int, j::Int) where F
    if isequal(operation(A), Gram)
        args = arguments(A)
        return args[i]'(args[j])
    else
        error("Indexing of general matrices not implemented")
    end
end

function mat(v::AbstractVector)
    n = sqrt(length(v))
    if n == round(n)
        n = Int(n)
        return reshape(v, (n, n))
    end
    error("Vector $v cannot be reshaped into a square matrix")
end

export mat, size

mat(A::BasicSymbolic{<:MatrixSpace}) = mat(arguments(A))
size(A::BasicSymbolic{<:MatrixSpace}) = size(mat(A), 1)

# ------------------------------------------------------
# MACROS
# ------------------------------------------------------

macro var(ex)

    _var(x) = error("Invalid expression for @var macro: $x")
    _var(x::LineNumberNode) = x

    function _var(x::Expr)
        if x.head == :call && length(x.args) == 3 && (x.args[1] == :(∈) || x.args[1] == :in)
            lhs = x.args[2]
            rhs = x.args[3]
            sym = QuoteNode(x.args[2])
            quote
                $lhs = SymbolicUtils.Sym{$rhs}($sym)
                $lhs = setmetadata($lhs, ID, $sym)
                nothing
            end
        elseif x.head == :block || x.head == :tuple
            Expr(:block, map(_var, x.args)...)
        else
            error("Invalid expression for @var macro: $x")
        end
    end
    
    return esc(quote
        $(_var(ex)); nothing
    end)
end

macro def(ex)

    _def(x) = error("Invalid expression for @def macro: $x")
    _def(x::LineNumberNode) = x

    function _def(x::Expr)
        if x.head == :(=)
            lhs = x.args[1]
            rhs = x.args[2]
            sym = QuoteNode(x.args[1])
            quote
                $lhs = $rhs
                $lhs = setmetadata($lhs, ID, $sym)
                nothing
            end
        elseif x.head == :block || x.head == :tuple
            Expr(:block, map(_def, x.args)...)
        else
            error("Invalid expression for @def macro: $x")
        end
    end
    
    return esc(quote
        $(_def(ex)); nothing
    end)
end

# ======================================================
# LYAPUNOV ANALYSIS
# ======================================================

export Transition, certify, @transition
export lyap_transition, lyap_oracle, lyap_performance, lyap_rate

abstract type LyapunovAnalysis end

"""
    Transition

Encodes one-step algorithm state-update rules. Each pair `state_var => next_expr`
specifies how a state variable evolves in one iteration.

Construct with the [`@transition`](@ref) macro or directly:

```julia
trans = Transition([x => x - α*g, xs => xs])
```
"""
struct Transition
    pairs::Vector
end
Transition(ps::Pair...) = Transition(Any[ps...])

lyap_transition(prob::BasicSymbolic{LyapunovAnalysis})  = arguments(prob)[1]
lyap_oracle(prob::BasicSymbolic{LyapunovAnalysis})      = arguments(prob)[2]
lyap_performance(prob::BasicSymbolic{LyapunovAnalysis}) = arguments(prob)[3]
lyap_rate(prob::BasicSymbolic{LyapunovAnalysis})        = arguments(prob)[4]

"""
    certify(trans, oracle_con, performance, rate)

Construct a Lyapunov certification problem. Use `simplify` to transform it into a
1-step performance SDP. If the optimal value of that SDP is ≤ `rate`, there exists
a Lyapunov function certifying geometric convergence at the given rate.
"""
function certify(trans::Transition, oracle_con::BasicSymbolic{<:Constraint},
                 perf::BasicSymbolic{R}, rate)
    return Term{LyapunovAnalysis}(certify, Any[trans, oracle_con, perf, rate])
end

"""
    @transition begin
        x  => x - α*g
        xs => xs
    end

Build a [`Transition`](@ref) from per-component update rules. Each `var => expr` pair
specifies the one-step update for a state variable. Variables must already be declared
(e.g. via `@alg`).
"""
macro transition(ex)
    raw_pairs = if ex isa Expr && ex.head == :block
        filter(a -> !(a isa LineNumberNode), ex.args)
    elseif ex isa Expr && ex.head == :call && length(ex.args) == 3 && ex.args[1] == :(=>)
        [ex]
    else
        error("@transition expects a `begin...end` block of `var => expr` rules")
    end
    pair_exprs = map(raw_pairs) do p
        (p isa Expr && p.head == :call && length(p.args) == 3 && p.args[1] == :(=>)) ||
            error("@transition: expected `var => expr`, got: $p")
        :($(esc(p.args[2])) => $(esc(p.args[3])))
    end
    return :(Transition(Any[$(pair_exprs...)]))
end

"""
    @alg let
        x, y in R
        z = 42
        x → x - α*g     # transitions collected into __transition__
    end

Runs the algorithm inside a local scope using a `let` block. 
Can also be used normally as `@alg begin ... end` for global/current scope.

Transitions (lines with `var → expr`) are collected into a `__transition__` Transition object.
If no transitions are present, `__transition__` is not created.

# Examples

```julia
@alg begin
    α, L ∈ R
    x, xs ∈ Rⁿ
    f ∈ F(Rⁿ)
    x → x - α * f'(x)
    xs → xs
end
trans = __transition__  # Access the implicit transition
```
"""
macro alg(ex)

    function _make_var(_var, _T)
        sym = QuoteNode(_var)
        # Build the assignment expression directly as AST, not as a quote
        # This returns: _var = AlgorithmAnalysis.leaf(sym, _T); nothing
        assign_expr = Expr(:(=), _var, Expr(:call, :(AlgorithmAnalysis.leaf), sym, _T))
        return Expr(:block, assign_expr, :(nothing))
    end

    # _recurse now threads through a list of accumulated transitions
    function _recurse(x, transitions)
        if x isa LineNumberNode
            return (x, transitions)
        
        elseif x isa Expr && x.head == :block
            result_exprs = []
            result_transitions = transitions
            for item in x.args
                item_result, item_transitions = _recurse(item, result_transitions)
                push!(result_exprs, item_result)
                result_transitions = item_transitions
            end
            return (Expr(:block, result_exprs...), result_transitions)
            
        elseif x isa Expr && x.head == :let
            bindings = x.args[1]
            body = x.args[2]
            body_result, body_transitions = _recurse(body, transitions)
            bindings_result, _ = _recurse(bindings, [])
            
            return (Expr(:let, bindings_result, body_result), body_transitions)

        # Transition rule: var → expr (detects the Unicode arrow operator)
        elseif x isa Expr && x.head == :call && length(x.args) == 3 && 
               (x.args[1] == :(→) || x.args[1] == Symbol("→"))
            var = x.args[2]
            expr = x.args[3]
            # Collect as (var_expr, expr_expr) pair to be built into Pair later
            new_transition = (var, expr)
            return (:(nothing), vcat(transitions, Any[new_transition]))

        # Handle the operator precedence: x, y ∈ R (tuple form)
        elseif x isa Expr && x.head == :tuple
            expanded_exprs = []
            current_set = nothing
            
            for item in reverse(x.args)
                if item isa Expr && item.head == :call && 
                   (item.args[1] == :(∈) || item.args[1] == :in)
                    var = item.args[2]
                    current_set = item.args[3]
                    push!(expanded_exprs, _make_var(var, current_set))
                elseif (item isa Symbol || (item isa Expr && item.head == :escape)) && 
                       current_set !== nothing
                    push!(expanded_exprs, _make_var(item, current_set))
                else
                    current_set = nothing
                    item_result, transitions = _recurse(item, transitions)
                    push!(expanded_exprs, item_result)
                end
            end
            return (Expr(:block, reverse(expanded_exprs)...), transitions)
        end

        # Standard explicit single variable declaration: x ∈ R
        if x isa Expr && x.head == :call && 
           (x.args[1] == :(∈) || x.args[1] == :in)
            lhs = x.args[2]
            set = x.args[3]
            if lhs isa Expr && lhs.head == :tuple
                return (Expr(:block, [_make_var(v, set) for v in lhs.args]...), 
                        transitions)
            else
                return (_make_var(lhs, set), transitions)
            end

        # Match definitions: b = expr
        elseif x isa Expr && x.head == :(=)
            sym = QuoteNode(x.args[1])
            # Build the assignment as plain AST: x.args[1] = set_id(to_symbolic(x.args[2]), sym)
            rhs_expr = Expr(:call, :(AlgorithmAnalysis.set_id), 
                           Expr(:call, :(AlgorithmAnalysis.to_symbolic), x.args[2]), 
                           sym)
            assign_expr = Expr(:(=), x.args[1], rhs_expr)
            return (Expr(:block, assign_expr, :(nothing)), transitions)

        # Fallback for other expressions
        else
            return (x, transitions)
        end
    end

    code_expr, transitions = _recurse(ex, Any[])
    
    # If no transitions, just execute the code
    if isempty(transitions)
        # code_expr is already a properly formed AST, escape it for the calling scope
        return esc(code_expr)
    end
    
    # Build the pairs array
    pairs_construction = Expr(:vect)
    for (var_expr, expr_expr) in transitions
        pair_expr = Expr(:call, :(=>), var_expr, expr_expr)
        push!(pairs_construction.args, pair_expr)
    end
    
    # Build final block with proper AST construction
    final_block = Expr(:block)
    
    if code_expr isa Expr && code_expr.head == :block
        # If code_expr is already a block, copy its arguments
        append!(final_block.args, code_expr.args)
    else
        # Otherwise wrap it
        push!(final_block.args, code_expr)
    end
    
    # Add __transition__ creation statement
    transition_stmt = :(__transition__ = AlgorithmAnalysis.Transition($(pairs_construction)))
    push!(final_block.args, transition_stmt)
    push!(final_block.args, :(nothing))
    
    return esc(final_block)
end
