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

abstract type NewExpression end;

abstract type NewVariable   <: NewExpression end;
abstract type NewConstraint <: NewExpression end;
abstract type NewOracle     <: NewExpression end;

abstract type DecomposableVariable <: NewVariable end;
abstract type ConcretelyValuedVariable <: DecomposableVariable end;

const get_monotonic_id = let id = Threads.Atomic{Int64}(0)
    () -> Threads.atomic_add!(id, 1)
end

struct AlgorithmExpressionId
    id::Int64
end

mutable struct AlgorithmState
    _expressions::Dict{AlgorithmExpressionId, NewExpression};

    function AlgorithmState()::AlgorithmState
        return new(Dict{AlgorithmExpressionId, NewExpression}());
    end
end


const ALGORITHM_CONTEXT = ScopedValue{AlgorithmState}()
get_algorithm_context()::AlgorithmState = ALGORITHM_CONTEXT[];

allocateAlgorithmExpressionId(::AlgorithmState)::AlgorithmExpressionId = AlgorithmExpressionId(get_monotonic_id())
function updateStateWithNewExpression(self::AlgorithmState, id::AlgorithmExpressionId, e::NewExpression) 
    if haskey(self._expressions, id)
        error("Cannot doubly insert $id")
    end

    self._expressions[id] = e;
end
    



struct NewR <: ConcretelyValuedVariable
    id::AlgorithmExpressionId;

    function NewR()::NewR
        ctx = get_algorithm_context();

        id = allocateAlgorithmExpressionId(ctx);

        self = new(id);

        updateStateWithNewExpression(ctx, id, self);
        
        return self;
    end
end

struct AddTag end;
struct SingleTag end;
struct MultiTag end;

struct LinearDecomposition <: DecomposableVariable
    id::AlgorithmExpressionId
    decomposition::Set{Pair{Float64, ConcretelyValuedVariable}};

    function LinearDecomposition(::AddTag, l::ConcretelyValuedVariable, r::ConcretelyValuedVariable)
        ctx = get_algorithm_context();

        id = allocateAlgorithmExpressionId(ctx);

        self = new(id, Set{Pair}([Pair(1.0, l), Pair(1.0, r)]))

        updateStateWithNewExpression(ctx, id, self);

        return self;
    end

    function LinearDecomposition(::SingleTag, e::Pair{Float64, ConcretelyValuedVariable})
        ctx = get_algorithm_context();

        id = allocateAlgorithmExpressionId(ctx);

        self = new(id, Set{Pair{Float64, ConcretelyValuedVariable}}([e]));

        updateStateWithNewExpression(ctx, id, self);

        return self;
    end

    function LinearDecomposition(::MultiTag, terms::Set{Pair{Float64, ConcretelyValuedVariable}})
        ctx = get_algorithm_context()
        id = allocateAlgorithmExpressionId(ctx)
        self = new(id, terms)
        updateStateWithNewExpression(ctx, id, self)
        return self
    end
end

+(l::NewR, r::NewR) = LinearDecomposition(AddTag(), l, r);

struct SSCFunction <: NewOracle
    id::AlgorithmExpressionId
    m::Float64
    L::Float64

    function SSCFunction(m::Float64, L::Float64)
        ctx = get_algorithm_context()

        id = allocateAlgorithmExpressionId(ctx)

        self = new(id, m, L)

        updateStateWithNewExpression(ctx, id, self)

        return self
    end
end

struct GradientEvaluation <: ConcretelyValuedVariable
    id::AlgorithmExpressionId
    f::SSCFunction
    x::DecomposableVariable

    function GradientEvaluation(f::SSCFunction, x::DecomposableVariable)
        ctx = get_algorithm_context()
        id = allocateAlgorithmExpressionId(ctx)
        self = new(id, f, x)
        updateStateWithNewExpression(ctx, id, self)
        return self
    end
end

struct SSCGradient
    f::SSCFunction
end

(∇f::SSCGradient)(x::DecomposableVariable) = GradientEvaluation(∇f.f, x)

SSC(m::Real, L::Real) = (f = SSCFunction(Float64(m), Float64(L)); (f, SSCGradient(f)))

*(α::Real, v::ConcretelyValuedVariable) = LinearDecomposition(SingleTag(), Pair{Float64, ConcretelyValuedVariable}(Float64(α), v))


function +(l::ConcretelyValuedVariable, r::LinearDecomposition)
    terms = Set{Pair{Float64, ConcretelyValuedVariable}}([Pair(1.0, l)])
    for p in r.decomposition
        push!(terms, p)
    end
    
    return LinearDecomposition(MultiTag(), terms)
end

function -(l::ConcretelyValuedVariable, r::LinearDecomposition)
    terms = Set{Pair{Float64, ConcretelyValuedVariable}}([Pair(1.0, l)])
    for p in r.decomposition
        push!(terms, Pair(-p.first, p.second))
    end
    
    return LinearDecomposition(MultiTag(), terms)
end



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
