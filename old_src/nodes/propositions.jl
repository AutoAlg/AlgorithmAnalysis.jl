export Prop, ∧, ⪯, ⪰

"""
    Prop

The set of propositions, which are statements that are either true or false.
"""
abstract type Prop <: NodeType end
abstract type Satisfied <: Prop end
abstract type Unsatisfied <: Prop end
abstract type Conjunction <: Prop end
abstract type Equality{T} <: Prop end
abstract type LessThanOrEqualTo{T} <: Prop end
abstract type Convex <: Prop end
abstract type PositiveSemidefinite <: Prop end
abstract type Transition{T} <: Prop end
abstract type Feasibility <: Prop end
abstract type LyapunovCertificate <: Feasibility end

satisfied() = SymbolicUtils.Sym{Satisfied}()
unsatisfied() = SymbolicUtils.Sym{Unsatisfied}()

function Base.:(==)(x::Node{T}, y::Node{T}) where {T}
    return Term{Equality{T}}(==, [x, y])
end

function Base.:≤(x::Node{T}, y::Node{T}) where {T}
    return Term{LessThanOrEqualTo{T}}(≤, [x, y])
end

function Base.:≥(x::Node{T}, y::Node{T}) where {T}
    return Term{LessThanOrEqualTo{T}}(≤, [y, x])
end

"""
    0 ⪯ A

Proposition that a symmetric matrix is positive semidefinite.
"""
function ⪯(a::Number, A::Node{<:MatrixSpace})
    if iszero(a)
        return Term{PositiveSemidefinite}(∈, [A])
    else
        error("Positive semidefinite constraint not implemented")
    end
end

"""
    A ⪰ 0

Proposition that a symmetric matrix is positive semidefinite.
"""
⪰(A::Node{<:MatrixSpace}, a::Number) = ⪯(a,A)

function expression(x::Node{<:Equality})
    args = arguments(x)
    if iszero(args[1])
        return args[2]
    elseif iszero(args[2])
        return args[1]
    else
        return args[2] - args[1]
    end
end
expression(x::Node{<:LessThanOrEqualTo}) = arguments(x)[2] - arguments(x)[1]
expression(x::Node{<:PositiveSemidefinite}) = arguments(x)[1]

function flatten(props::Node{<:Prop}...)
    flat_args = Node{<:Prop}[]
    for arg in props
        if iscall(arg) && operation(arg) === ∧
            append!(flat_args, arguments(arg))
        elseif isequal(arg, unsatisfied())
            return unsatisfied()
        elseif !isequal(arg, satisfied())
            push!(flat_args, arg)
        end
    end
    return flat_args
end

"""
    ∧(props...)
    p ∧ q

Conjunction of two or more propositions.
"""
function ∧(args::Node{<:Prop}...)
    flat_args = flatten(args...)
    if isempty(flat_args)
        return satisfied()
    else
        return Term{Conjunction}(∧, flatten(args...))
    end
end

∧(x::Node{Conjunction}, y::Node{Conjunction}) = Term{Conjunction}(∧, [arguments(x)..., arguments(y)...])

∧(x::Node{<:Prop}, y::Bool) = y ? x : unsatisfied()
∧(x::Bool, y::Node{<:Prop}) = x ? y : unsatisfied()

# iterate over conjunctions
Base.iterate(prop::Node{Conjunction}) = iterate(prop, 1)
function Base.iterate(prop::Node{Conjunction}, i::Int)
    args = arguments(prop)
    if i < 0 || i > length(args)
        return nothing
    else
        return args[i], i+1
    end
end
Base.length(prop::Node{Conjunction}) = length(arguments(prop))
