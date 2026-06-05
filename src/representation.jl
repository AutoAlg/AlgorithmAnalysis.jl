export R, Rⁿ, Sⁿ, F, VectorSpace, MatrixSpace
export field, additive_identity, multiplicative_identity
export zero, one, ∧, maximize, objective, constraint
export is_function, function_category, Convex
export @var, @alg, @def
export Gradient, LinearFunctional, DifferentiableFunctional, ∇, Gram
export PositiveSemidefinite
export has_id, id, ID
export satisfied, unsatisfied

abstract type ID end

has_id(t::BasicSymbolic) = hasmetadata(t, ID)
id(t::BasicSymbolic) = has_id(t) ? getmetadata(t, ID) : (hasproperty(t, :name) ? t.name : nothing)

abstract type Field end
abstract type VectorSpace{F} end
abstract type MatrixSpace{F} <: VectorSpace{F} end
abstract type R <: Field end

struct Rⁿ <: VectorSpace{R} end
struct Sⁿ <: MatrixSpace{R} end

field(::Type{<:VectorSpace{R}}) = R
field(::BasicSymbolic{V}) where {F,V<:VectorSpace{F}} = F

function additive_identity end
function multiplicative_identity end
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

zero(::Type{Rⁿ}) = Sym{Rⁿ}(:additive_identity)
zero(::Type{R}) = Sym{R}(:additive_identity)
one(::Type{R}) = Sym{R}(:multiplicative_identity)
R(val::Real) = Term{R}(constant, [val])
satisfied() = Sym{Satisfied}()
unsatisfied() = Sym{Unsatisfied}()

+(x::T...) where {F<:Field, T<:BasicSymbolic{F}} = Term{F}(+, x)

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

function *(scalar::F, v::BasicSymbolic{V}) where {F,V<:VectorSpace{F}}
    return Term{F}(*, [scalar, v])
end

function ⋅(u::BasicSymbolic{V}, v::BasicSymbolic{V}) where {F,V<:VectorSpace{F}}
    return Term{F}(⋅, [u, v])
end

function adjoint(x::BasicSymbolic{V}) where {F,V<:VectorSpace{F}}
    return Term{FnType{Tuple{V},F,LinearFunctional}}(adjoint, [x])
end

function adjoint(f::BasicSymbolic{FnType{Tuple{V},F,LinearFunctional}}) where {F,V<:VectorSpace{F}}
    # If it's already an adjoint term tree, peel it off to prevent double nesting
    if istree(f) && isequal(operation(f), adjoint)
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


function ∈(f::BasicSymbolic{FnType{Tuple{V},F,DifferentiableFunctional}}, ::Type{Convex}) where {F,V<:VectorSpace{F}}
    return Term{Convex}(∈, [f])
end

function ∈(G::BasicSymbolic{<:MatrixSpace}, ::Type{PositiveSemidefinite})
    return Term{PositiveSemidefinite}(∈, [G])
end

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
        if istree(arg) && operation(arg) === ∧
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

function getindex(A::BasicSymbolic{MatrixSpace{F}}, i::Int, j::Int) where F
    if isequal(operation(A), Gram)
        args = arguments(A)
        return args[i]'(args[j])
    else
        error("Indexing of general matrices not implemented")
    end
end

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

macro alg(ex)
    
    _alg(x) = error("Invalid expression for @alg macro: $x")
    _alg(x::LineNumberNode) = x

    function _alg(x::Expr)
        if x.head == :block || x.head == :tuple
            return Expr(:block, map(_alg, x.args)...)

        elseif x.head == :call && length(x.args) == 3 && (x.args[1] == :(∈) || x.args[1] == :in)
            return Expr(:macrocall, 
                Expr(:., :AlgorithmAnalysis, QuoteNode(Symbol("@var"))),
                LineNumberNode(@__LINE__, @__FILE__),
                x
            )

        elseif x.head == :(=)
            return Expr(:macrocall,
                Expr(:., :AlgorithmAnalysis, QuoteNode(Symbol("@def"))),
                LineNumberNode(@__LINE__, @__FILE__),
                x
            )
            
        else
            error("Invalid expression for @alg macro: $x")
        end
    end
    
    return esc(quote
        $(_alg(ex)); nothing
    end)
end
