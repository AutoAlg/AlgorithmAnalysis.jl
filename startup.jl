using Pkg
Pkg.activate(".")
using Revise
using AlgorithmAnalysis

m = 1
L = 10
α = 2/(L+m)

@algorithm begin
    f = SmoothStronglyConvexFunction{Rⁿ}(m, L)
    xs = first_order_stationary_point(f)
    fs = f(xs)
    
    x0 = Rⁿ()
    x1 = x0 - α * f'(x0)
    x0 => x1

    performance = (x0 - xs)^2
end

objs = connected_components(performance)


function smoothstronglyconvexinterpolation(objs::Objects)
    
    objs = deepcopy(objs)

    fs = filter(x -> x isa SmoothStronglyConvexFunction, objs)

    for f ∈ fs
        m = f.strong_convexity
        L = f.smoothness

        union!(objs, Constraints( fᵢ-fⱼ ≥ gⱼ'*(xᵢ-xⱼ) + 1/2L*(gᵢ-gⱼ)^2 + m/(2*(1-m/L))*(xᵢ-xⱼ-1/L*(gᵢ-gⱼ))^2 for (xᵢ,fᵢ,gᵢ) ∈ triplets(f), (xⱼ,fⱼ,gⱼ) ∈ triplets(f) ))

        setdiff!(objs, Set([f, f']))
    end
    
    objs
end

function gramtransformation(objs::Objects)
    
    objs = deepcopy(objs)

    Xs = Set(filter(T -> T <: InnerProductSpace, typeof.(objs)))

    for X ∈ Xs

        xs = filter(x -> x isa X, objs)

        union!(objs, Gram(xs...))

        setdiff!(objs, Set(xs))
    end
    
    objs
end

struct Transformation
    name::String
    func::Function
end

transformations = Set{Transformation}([
    Transformation(
        "Smooth strongly convex interpolation",
        smoothstronglyconvexinterpolation
    ),
    Transformation(
        "Gram transformation",
        gramtransformation
    ),
])

function interpolation_search(xs::Objects)
    visited = Set()
    queue = Objects[xs]  # use a deque from DataStructures.jl for better performance
    came_from = Dict()
    while !isempty(queue)
        node = popfirst!(queue)
        if verbose
            @info "Visiting $node"
        end

        if isimplementable(node)
            path = [node]
            while node != xs
                node = came_from[node]
                pushfirst!(path, node)
            end
            return path
        end
        if node ∉ visited
            push!(visited, node)
            for neighbor ∈ neighbors(node)
                if neighbor ∉ visited
                    if verbose
                        @info " ⋅ Queueing $neighbor"
                    end
                    push!(queue, neighbor)
                    came_from[neighbor] = node
                end
            end
        end
    end
    error("Path not found")
end

@algorithm x1 = Rⁿ()
x2 = deepcopy(x1)

# this breaks!
# deepcopy(x0)