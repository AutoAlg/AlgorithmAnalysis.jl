using Pkg
Pkg.activate(".")
using Revise
using AlgorithmAnalysis

m = 1
L = 10
α = 2/(L+m)
ρ = 1-2α*m*L/(L+m)
@algorithm begin
    f = SmoothStronglyConvexFunction{Rⁿ}(m, L)
    xs = first_order_stationary_point(f)
    
    x0 = Rⁿ()
    x1 = x0 - α * f'(x0)
    x0 => x1

    performance = (x0 - xs)^2
end

objs = connected_components(performance)

types = Set( typeof(x) for x in objs )

# interpolate(objs, f, SmoothStronglyConvex(m,L))

@algorithm begin
  x1 = Rⁿ()
  x2 = Rⁿ()
  G = Gram(x1, x2)
end



struct ObjectNode
    typ::Union{DataType, UnionAll}
    props::Set{DataType}
end
ObjectNode(t::Union{DataType, UnionAll}) = ObjectNode(t, Set{DataType}())
ObjectNode(t::Union{DataType, UnionAll}, p::DataType...) = ObjectNode(t, Set{DataType}(p))

# --- Global Registry and Rule Struct ---
struct Transformation
    name::String
    requires::Function
    produces::Set{ObjectNode}
end

# Global registry of Rule Generators
const GLOBAL_RULE_GENERATORS = Function[]

function register_rule!(generator::Function)
    push!(GLOBAL_RULE_GENERATORS, generator)
end

# Clear the registry for interactive development
empty!(GLOBAL_RULE_GENERATORS)

# Define a rule template for ANY inner product space T
# register_rule!() do T
#     InterpolationRule{T}(
#         "Interpolate Convex Functional on $T",
#         ObjectNode(DifferentiableFunctional{T}, Convex), # Consumes
#         Set([ObjectNode(T)]),                            # Requires EXACTLY T
#         Set([ObjectNode(Constraint{T})])                 # Produces Constraint{T}
#     )
# end

# Helper to check if requirements are met (unchanged)
function satisfies(requirement::ObjectNode, candidate::ObjectNode)
    return candidate.typ <: requirement.typ && issubset(requirement.props, candidate.props)
end

function has_requirements(state::Set{ObjectNode}, requires::Set{ObjectNode})
    for req in requires
        if !any(candidate -> satisfies(req, candidate), state)
            return false
        end
    end
    return true
end

# Updated Search Algorithm
function search_implementable_path(initial_state::Set{ObjectNode}, implementable::Function)
    queue = [(initial_state, String[])]
    visited = Set{Set{ObjectNode}}([initial_state])

    while !isempty(queue)
        current_state, path = popfirst!(queue)

        if all(implementable, current_state)
            return current_state, path
        end

        # --- NEW: Dynamic Rule Generation ---
        # Find all specific spaces (like Rn, Rm) present in the current state
        active_spaces = [node.typ for node in current_state if node.typ <: InnerProductSpace]
        
        # Generate the strict rules for these specific spaces
        concrete_rules = InterpolationRule[]
        for T in active_spaces
            for gen in GLOBAL_RULE_GENERATORS
                push!(concrete_rules, gen(T))
            end
        end
        # ------------------------------------

        # Proceed with normal BFS using the concrete, strictly-typed rules
        for rule in concrete_rules
            for candidate in current_state
                if satisfies(rule.consumes, candidate) && has_requirements(current_state, rule.requires)
                    
                    new_state = copy(current_state)
                    delete!(new_state, candidate) 
                    union!(new_state, rule.produces)

                    if !(new_state in visited)
                        push!(visited, new_state)
                        new_path = copy(path)
                        push!(new_path, rule.name)
                        push!(queue, (new_state, new_path))
                    end
                end
            end
        end
    end
    return nothing, String[]
end


# # A node is implementable if it's a Constraint{T} or an InnerProductSpace
# implementable(node::ObjectNode) = (node.typ <: Constraint) || (node.typ <: InnerProductSpace)

# # Initial state has functions and spaces for BOTH Rn and Rm
# initial_objects = Set([
#     ObjectNode(DifferentiableFunctional{Rⁿ}, SmoothStronglyConvex), 
#     ObjectNode(Rⁿ),
#     ObjectNode(Rᵐ) 
# ])

# final_state, steps = search_implementable_path(initial_objects, implementable)

# println("Steps taken:")
# foreach(println, steps)
# println("\nFinal Objects: ")
# foreach(println, final_state)
