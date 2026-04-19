# using Pkg
# Pkg.activate(".")
# using Revise
using AlgorithmAnalysis
import Base.:+, Base.:*, Base.:-

# m = 1
# L = 10
# α = 2/(L+m)

# @algorithm begin
#     f = SmoothStronglyConvexFunction{Rⁿ}(m, L)
#     xs = first_order_stationary_point(f)
#     fs = f(xs)
    
#     x0 = Rⁿ()
#     g0 = f'(x0)
#     x1 = x0 - α * g0
#     x0 => x1

#     performance = (x0 - xs)^2
# end

# objs = connected_components(performance)

# function smoothstronglyconvexinterpolation(objs::Objects)
    
#     objs = deepcopy(objs)

#     fs = filter(x -> x isa SmoothStronglyConvexFunction, objs)

#     for f ∈ fs
#         m = f.strong_convexity
#         L = f.smoothness

#         for (xᵢ,fᵢ,gᵢ) ∈ triplets(f), (xⱼ,fⱼ,gⱼ) ∈ triplets(f)
#             fᵢ-fⱼ ≥ gⱼ'*(xᵢ-xⱼ) + 1/2L*(gᵢ-gⱼ)^2 + m/(2*(1-m/L))*(xᵢ-xⱼ-1/L*(gᵢ-gⱼ))^2
#         end
#     end
    
#     objs = connected_components(objs)

#     for f ∈ fs
#         setdiff!(objs, Set([f, f']))
#     end

#     # need to remove all connections to f and f', not just remove them from the set
#     for obj ∈ objs
#         setdiff!(oracles(obj), Set([f, f']))
#     end

#     objs
# end

# new_objs = smoothstronglyconvexinterpolation(objs)

# function gramtransformation(objs::Objects)
    
#     objs = deepcopy(objs)

#     Xs = Set(filter(T -> T <: InnerProductSpace, typeof.(objs)))

#     for X ∈ Xs

#         xs = filter(x -> x isa X, objs)

#         union!(objs, Gram(xs...))

#         setdiff!(objs, Set(xs))
#     end
    
#     objs
# end

# struct Transformation
#     name::String
#     func::Function
# end

# transformations = Set{Transformation}([
#     Transformation(
#         "Smooth strongly convex interpolation",
#         smoothstronglyconvexinterpolation
#     ),
#     Transformation(
#         "Gram transformation",
#         gramtransformation
#     ),
# ])

# function interpolation_search(xs::Objects)
#     visited = Set()
#     queue = Objects[xs]  # use a deque from DataStructures.jl for better performance
#     came_from = Dict()
#     while !isempty(queue)
#         node = popfirst!(queue)
#         if verbose
#             @info "Visiting $node"
#         end

#         if isimplementable(node)
#             path = [node]
#             while node != xs
#                 node = came_from[node]
#                 pushfirst!(path, node)
#             end
#             return path
#         end
#         if node ∉ visited
#             push!(visited, node)
#             for neighbor ∈ neighbors(node)
#                 if neighbor ∉ visited
#                     if verbose
#                         @info " ⋅ Queueing $neighbor"
#                     end
#                     push!(queue, neighbor)
#                     came_from[neighbor] = node
#                 end
#             end
#         end
#     end
#     error("Path not found")
# end

using Base.ScopedValues

abstract type NewExpression end
abstract type NewVariable   <: NewExpression end
abstract type NewConstraint <: NewExpression end
abstract type NewOracle     <: NewExpression end

abstract type DecomposableVariable <: NewVariable end
abstract type ConcretelyValuedVariable <: DecomposableVariable end

const get_monotonic_id = let id = Threads.Atomic{Int64}(0)
    () -> Threads.atomic_add!(id, 1)
end

struct AlgorithmExpressionId
    id::Int64
end

mutable struct AlgorithmState
    _expressions::Dict{AlgorithmExpressionId, NewExpression}
    AlgorithmState() = new(Dict{AlgorithmExpressionId, NewExpression}())
end

const ALGORITHM_CONTEXT = ScopedValue{AlgorithmState}()
get_algorithm_context()::AlgorithmState = ALGORITHM_CONTEXT[]

# Centralized registration to remove boilerplate from struct constructors
function register!(expr::NewExpression, ctx::AlgorithmState = get_algorithm_context())
    if haskey(ctx._expressions, expr.id)
        error("Cannot doubly insert $(expr.id)")
    end
    ctx._expressions[expr.id] = expr
    return expr
end

function allocate_id()::AlgorithmExpressionId
    AlgorithmExpressionId(get_monotonic_id())
end

# --- Variables ---

struct NewR <: ConcretelyValuedVariable
    id::AlgorithmExpressionId
    NewR() = register!(new(allocate_id()))
end

struct LinearDecomposition <: DecomposableVariable
    id::AlgorithmExpressionId
    terms::Dict{ConcretelyValuedVariable, Float64}
    
    function LinearDecomposition(terms::Dict{ConcretelyValuedVariable, Float64})
        # Filter out near-zero terms immediately to keep the decomposition sparse
        clean_terms = filter(p -> abs(p.second) > 1e-12, terms)
        register!(new(allocate_id(), clean_terms))
    end
end

# --- Oracles ---

struct SSCFunction <: NewOracle
    id::AlgorithmExpressionId
    m::Float64
    L::Float64
    SSCFunction(m::Real, L::Real) = register!(new(allocate_id(), Float64(m), Float64(L)))
end

struct GradientEvaluation <: ConcretelyValuedVariable
    id::AlgorithmExpressionId
    f::SSCFunction
    x::DecomposableVariable
    GradientEvaluation(f::SSCFunction, x::DecomposableVariable) = register!(new(allocate_id(), f, x))
end

struct SSCGradient
    f::SSCFunction
end

(∇f::SSCGradient)(x::DecomposableVariable) = GradientEvaluation(∇f.f, x)
SSC(m::Real, L::Real) = (f = SSCFunction(m, L); (f, SSCGradient(f)))

# --- Algebra ---

import Base: +, -, *

# Helper to easily convert a concrete variable into a Dict for uniform math
_to_dict(v::ConcretelyValuedVariable, scale::Float64=1.0) = Dict{ConcretelyValuedVariable, Float64}(v => scale)
_to_dict(d::LinearDecomposition, scale::Float64=1.0) = Dict{ConcretelyValuedVariable, Float64}(k => v * scale for (k, v) in d.terms)

# Helper to merge dictionaries algebraically
function _merge_terms(a::Dict, b::Dict, b_scale::Float64=1.0)
    res = copy(a)
    for (k, v) in b
        res[k] = get(res, k, 0.0) + v * b_scale
    end
    return res
end

# Multiplications
*(α::Real, v::ConcretelyValuedVariable) = LinearDecomposition(_to_dict(v, Float64(α)))
*(α::Real, d::LinearDecomposition)      = LinearDecomposition(_to_dict(d, Float64(α)))
*(v::ConcretelyValuedVariable, α::Real) = α * v
*(d::LinearDecomposition, α::Real)      = α * d

# Additions
+(l::ConcretelyValuedVariable, r::ConcretelyValuedVariable) = LinearDecomposition(_merge_terms(_to_dict(l), _to_dict(r)))
+(l::ConcretelyValuedVariable, r::LinearDecomposition)      = LinearDecomposition(_merge_terms(_to_dict(l), r.terms))
+(l::LinearDecomposition,      r::ConcretelyValuedVariable) = r + l
+(l::LinearDecomposition,      r::LinearDecomposition)      = LinearDecomposition(_merge_terms(l.terms, r.terms))

# Subtractions
-(l::ConcretelyValuedVariable, r::ConcretelyValuedVariable) = LinearDecomposition(_merge_terms(_to_dict(l), _to_dict(r, -1.0)))
-(l::ConcretelyValuedVariable, r::LinearDecomposition)      = LinearDecomposition(_merge_terms(_to_dict(l), r.terms, -1.0))
-(l::LinearDecomposition,      r::ConcretelyValuedVariable) = LinearDecomposition(_merge_terms(l.terms, _to_dict(r, -1.0)))
-(l::LinearDecomposition,      r::LinearDecomposition)      = LinearDecomposition(_merge_terms(l.terms, r.terms, -1.0))

ctx = AlgorithmState();

α = 0.05
with(ALGORITHM_CONTEXT => ctx) do
    f, ∇f = SSC(3, 10);
    
    x0 = NewR();

    x1 = x0 + α * ∇f(x0);
end

for (k, v) in ctx._expressions
    println("$k -> $v")
end
