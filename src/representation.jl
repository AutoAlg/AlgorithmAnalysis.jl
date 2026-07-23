export R, Rⁿ, Sⁿ, F, VectorSpace, MatrixSpace, field, Prop
export zero, one, ∧, maximize, minimize, objective, constraint
export is_function, function_category, Convex
export @var, @alg, @def
export Gradient, LinearFunctional, DifferentiableFunctional, ∇, Gram
export PositiveSemidefinite
export has_id, id, set_id, ID
export satisfied, unsatisfied
export ⪯, ⪰, to_symbolic, tr
export convex, smooth_convex, sector_bounded
export leaf, branch, Transition
export LyapunovCertificate, certify, rate
export Optimization, Minimization, Maximization, Feasibility

leaf(T, sym::Symbol) = Sym{T}(sym)
branch(T, sym::Symbol, op, args) = (t=Term{T}(op, args); set_id(t, sym); t)

to_symbolic(x::Any) = convert(Node, x)

abstract type ID end

has_id(::Any) = false
has_id(t::Node) = hasmetadata(t, ID) || hasproperty(t, :name)
id(t::Node) = hasmetadata(t, ID) ? getmetadata(t, ID) : (hasproperty(t, :name) ? t.name : nothing)
set_id(t::Node, sym::Symbol) = setmetadata(t, ID, sym)
set_id(::Any, ::Symbol) = nothing

abstract type Field end
abstract type VectorSpace{F} end
abstract type MatrixSpace{F} end
abstract type SymmetricMatrix{F} <: MatrixSpace{F} end
abstract type R <: Field end
abstract type Minimization <: R end
abstract type Maximization <: R end

abstract type Rⁿ <: VectorSpace{R} end
abstract type Sⁿ <: MatrixSpace{R} end

abstract type Category end
abstract type LinearFunctional <: Category end
abstract type DifferentiableFunctional <: Category end
abstract type Gradient <: Category end
abstract type GramMatrix <: Category end

abstract type Prop end
abstract type Satisfied <: Prop end
abstract type Unsatisfied <: Prop end
abstract type Equality{T} <: Prop end
abstract type LessThanOrEqualTo{T} <: Prop end
abstract type Convex <: Prop end
abstract type PositiveSemidefinite <: Prop end
abstract type Transition{T} <: Prop end
abstract type Feasibility <: Prop end
abstract type LyapunovCertificate <: Feasibility end

const Optimization = Union{<:Minimization, <:Maximization, <:Feasibility}

Base.convert(::Type{<:Node}, val::Number) = R(val)
Base.convert(::Type{Node{R}}, val::Number) = R(val)
Base.promote_rule(::Type{Node{R}}, ::Type{<:Number}) = Node{R}

for op in (:+, :-, :*, :/, :^, :≤, :≥, :(==))
    @eval begin
        Base.$op(x::Number, y::Node{R}) = $op(promote(x, y)...)
        Base.$op(x::Node{R}, y::Number) = $op(promote(x, y)...)
    end
end

field(::Type{<:VectorSpace{F}}) where F = F
field(::Node{V}) where {F,V<:VectorSpace{F}} = F

function constant end

const ∇ = Sym{FnType{Tuple{FnType{Tuple{Rⁿ},R,DifferentiableFunctional}},FnType{Tuple{Rⁿ},Rⁿ,Gradient},Nothing}}(:∇)

const Gram = Sym{FnType{Tuple{Vararg{Rⁿ}}, MatrixSpace{R}, Nothing}}(:Gram)

zero(::Type{Rⁿ}) = Term{Rⁿ}(zero, [])
zero(::Type{R}) = Term{R}(zero, [])
one(::Type{R}) = Term{R}(one, [])
R(val::Real) = Term{R}(constant, [val])
satisfied() = Sym{Satisfied}()
unsatisfied() = Sym{Unsatisfied}()

iszero(x::Node) = iscall(x) && isequal(operation(x), zero)
isone(x::Node) = iscall(x) && isequal(operation(x), one)

function Sⁿ(A::Matrix{Node{R}})
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

function Base.convert(::Type{<:Node}, A::Matrix)
    Sⁿ(Base.convert.(Node, A))
end

tr(A::Node{Sⁿ}) = Term{R}(tr, [A])
tr(A::Matrix) = la.tr(A)

+(x::T, y::T) where {T<:Node{Sⁿ}} = Term{Sⁿ}(+, [x, y])
*(x::T, y::T) where {T<:Node{Sⁿ}} = Term{Sⁿ}(*, [x, y])
-(x::T, y::T) where {T<:Node{Sⁿ}} = Term{Sⁿ}(-, [x, y])
/(x::T, y::T) where {T<:Node{Sⁿ}} = Term{Sⁿ}(/, [x, y])
⋅(x::T, y::T) where {T<:Node{Sⁿ}} = Term{Sⁿ}(⋅, [x, y])

+(x::T...) where {F<:Field, T<:Node{F}} = Term{F}(+, x)
*(x::T...) where {F<:Field, T<:Node{F}} = Term{F}(*, x)
-(x::T, y::T) where {F<:Field, T<:Node{F}} = Term{F}(-, [x, y])
/(x::T, y::T) where {F<:Field, T<:Node{F}} = Term{F}(/, [x, y])

function F(V::Type{<:VectorSpace})
    return FnType{Tuple{V},field(V),DifferentiableFunctional}
end

function +(u::Node{V}, v::Node{V}) where {V<:VectorSpace}
    return Term{V}(+, [u, v])
end

+(u::Node{<:VectorSpace}) = u

function -(u::Node{V}, v::Node{V}) where {V<:VectorSpace}
    return Term{V}(-, [u, v])
end

function -(v::Node{V}) where {V<:VectorSpace}
    return Term{V}(-, [v])
end

function *(scalar::Node{F}, v::Node{V}) where {F,V<:VectorSpace{F}}
    return Term{V}(*, [scalar, v])
end

# function *(scalar::F, v::Node{V}) where {F,V<:VectorSpace{F}}
#     return Term{F}(*, [scalar, v])
# end

function ⋅(u::Node{V}, v::Node{V}) where {F,V<:VectorSpace{F}}
    return Term{F}(⋅, [u, v])
end

function adjoint(x::Node{V}) where {F,V<:VectorSpace{F}}
    iszero(x) && return Term{FnType{Tuple{V},F,LinearFunctional}}(zero, [])
    return Term{FnType{Tuple{V},F,LinearFunctional}}(adjoint, [x])
end

function adjoint(f::Node{FnType{Tuple{V},F,LinearFunctional}}) where {F,V<:VectorSpace{F}}
    # If it's already an adjoint term tree, peel it off to prevent double nesting
    if iscall(f) && isequal(operation(f), adjoint)
        return arguments(f)[1]
    end
    return Term{V}(adjoint, [f])
    # return Sym{V}( Symbol(f, "'") )
end

function adjoint(f::Node{FnType{Tuple{V},F,DifferentiableFunctional}}) where {F,V<:VectorSpace{F}}
    #   return Term{FnType{Tuple{V}, V, Gradient}}(∇, [f])
    return ∇(f)
end

is_gradient(x) = is_function(x) && isequal(operator(x), ∇)


Base.literal_pow(::typeof(^), x::Node{<:VectorSpace}, ::Val{2}) = x'(x)

# function ∈(f::Node{FnType{Tuple{V},F,DifferentiableFunctional}}, ::Type{Convex}) where {F,V<:VectorSpace{F}}
#     return Term{Convex}(∈, [f])
# end

function convex(f::Node{FnType{Tuple{V},F,DifferentiableFunctional}}) where {F,V<:VectorSpace{F}}
    return Term{Convex}(∈, [f])
end

function smooth_convex(f::Node{FnType{Tuple{V},F,DifferentiableFunctional}}, L::Node{F}) where {F,V<:VectorSpace{F}}
    return Term{Prop}(smooth_convex, [f, L])
end

function sector_bounded(f::Node{FnType{Tuple{V},F,DifferentiableFunctional}}, μ::Node{F}, L::Node{F}) where {F,V<:VectorSpace{F}}
    return Term{Prop}(sector_bounded, [f, μ, L])
end

# function ∈(G::Node{<:MatrixSpace}, ::Type{PositiveSemidefinite})
#     return Term{PositiveSemidefinite}(∈, [G])
# end

function ⪯(a::Number, A::Node{<:MatrixSpace})
    if iszero(a)
        return Term{PositiveSemidefinite}(∈, [A])
    else
        error("Positive semidefinite constraint not implemented")
    end
end

⪰(A::Node{<:MatrixSpace}, a::Number) = ⪯(a,A)

function (f::Node{FnType{Tuple{V},F,Nothing}})(x::V) where {F,V<:VectorSpace{F}}
    return Term{F}(f, [x])
end

function ==(x::Node{T}, y::Node{T}) where {T}
    return Term{Equality{T}}(==, [x, y])
end

function ≤(x::Node{T}, y::Node{T}) where {T}
    return Term{LessThanOrEqualTo{T}}(≤, [x, y])
end

function ≥(x::Node{T}, y::Node{T}) where {T}
    return Term{LessThanOrEqualTo{T}}(≤, [y, x])
end

function ∧(args::Node{<:Prop}...)
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
    return Term{Prop}(∧, flat_args)
end

∧(x::Node{<:Prop}, y::Bool) = y ? x : unsatisfied()
∧(x::Bool, y::Node{<:Prop}) = x ? y : unsatisfied()

# function Gram(vecs::Node{T}...) where {F,T<:VectorSpace{F}}
#     return Term{MatrixSpace{F}}(Gram, vecs)
# end

function maximize(obj::Node, con::Node{<:Prop})
    return Term{Maximization}(maximize, [obj, con])
end

function minimize(obj::Node, con::Node{<:Prop})
    return Term{Minimization}(minimize, [obj, con])
end

function feasible(con::Node{<:Prop})
    return Term{Feasibility}(feasible, [con])
end

sense(opt::Node{<:Optimization}) = Symbol(operation(opt))
is_minimization(opt::Node{<:Optimization}) = isequal(sense(opt), :minimize)
is_maximization(opt::Node{<:Optimization}) = isequal(sense(opt), :maximize)
is_feasibility(opt::Node{<:Optimization}) = isequal(sense(opt), :feasible)

objective(opt::Node{Minimization}) = arguments(opt)[1]
objective(opt::Node{Maximization}) = arguments(opt)[1]

constraint(opt::Node{Minimization}) = arguments(opt)[2]
constraint(opt::Node{Maximization}) = arguments(opt)[2]
constraint(opt::Node{Feasibility}) = arguments(opt)[1]

"""
    certify(trans, oracle_con, performance, rate)

Construct a Lyapunov certification problem. Use `simplify` to transform it into a
fixed-rate feasibility problem that searches for a parameterized Lyapunov certificate.
The argument `rate` is required and should satisfy `0 < rate < 1` for geometric decay.

The simplified problem searches for scalar certificate variables (Lyapunov template
coefficients and nonnegative multipliers) that prove both:
1. `V(x) ≥ performance(x)`
2. `V(x⁺) ≤ rate * V(x)`

subject to the transformed interpolation and Gram constraints.
"""
function certify(con::Node{<:Prop}, perf::Node{R}, rate::Node{R})
    return Term{LyapunovCertificate}(certify, Any[con, perf, rate])
end

function rate(con::Node{<:Prop}, perf::Node{R})
    return Term{LyapunovAnalysis}(rate, Any[con, perf])
end

constraint(t::Node{LyapunovCertificate}) = arguments(t)[1]

is_function(t) = t isa Node && typeof(t).parameters[1] <: FnType

function function_category(t::Node)
    fn_type = typeof(t).parameters[1]
    if !is_function(t)
        error("$t is not a function")
    end
    return fn_type.parameters[3]
end

function getindex(A::Node{MatrixSpace{F}}, i::Int, j::Int) where F
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

mat(A::Node{<:MatrixSpace}) = mat(arguments(A))
size(A::Node{<:MatrixSpace}) = size(mat(A), 1)


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

"""
    @alg let
        x, y in R
        z = 42
    end

Runs the algorithm inside a local scope using a `let` block. 
Can also be used normally as `@alg begin ... end` for global/current scope.
"""
macro alg(ex)

    function _make_var(_var, _T)
        var = esc(_var)
        T = esc(_T)
        sym = QuoteNode(_var)
        return quote
            $var = AlgorithmAnalysis.leaf($T, $sym); nothing
        end
    end

    function _recurse(x)
        if x isa LineNumberNode
            return x
        
        elseif x isa Expr && x.head == :block
            return Expr(:block, map(_recurse, x.args)...)
            
        elseif x isa Expr && x.head == :let
            bindings = x.args[1]
            body = x.args[2]
            
            return Expr(:let, _recurse(bindings), _recurse(body))

        # Handle the operator precedence: x, y ∈ R
        elseif x isa Expr && x.head == :tuple
            expanded_exprs = []
            current_set = nothing
            
            for item in reverse(x.args)
                if item isa Expr && item.head == :call && (item.args[1] == :(∈) || item.args[1] == :in)
                    var = item.args[2]
                    current_set = item.args[3]
                    push!(expanded_exprs, _make_var(var, current_set))
                elseif (item isa Symbol || (item isa Expr && item.head == :escape)) && current_set !== nothing
                    push!(expanded_exprs, _make_var(item, current_set))
                else
                    current_set = nothing
                    push!(expanded_exprs, _recurse(item))
                end
            end
            return Expr(:block, reverse(expanded_exprs)...)
        end

        # Standard explicit single variable declaration: x ∈ R
        if x isa Expr && x.head == :call && (x.args[1] == :(∈) || x.args[1] == :in)
            lhs = x.args[2]
            set = x.args[3]
            if lhs isa Expr && lhs.head == :tuple
                return Expr(:block, [_make_var(v, set) for v in lhs.args]...)
            else
                return _make_var(lhs, set)
            end

        # Match definitions: b = expr
        elseif x isa Expr && x.head == :(=)
            lhs = esc(x.args[1])
            rhs = esc(x.args[2])
            sym = QuoteNode(x.args[1])

            raw_rhs = x.args[2]

            if raw_rhs isa Expr && raw_rhs.head == :call &&
                length(raw_rhs.args) == 3 && raw_rhs.args[1] == :(→)

                src = esc(raw_rhs.args[2])
                dst = esc(raw_rhs.args[3])
                
                return quote
                    $lhs = set_id(Term{Transition}(transition, [$src, $dst]), $sym); nothing
                end
            end

            return quote
                $lhs = set_id(to_symbolic($rhs), $sym); nothing
            end

        # Fallback
        else
            return esc(x)
        end
    end

    quote
        $(_recurse(ex)); nothing
    end
end