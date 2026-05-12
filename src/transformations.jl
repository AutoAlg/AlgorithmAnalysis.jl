export Transformation, Transformations, _TRANSFORMATIONS, transformations
export search_path, reconstruct_path, convexify, convexify!, apply!

struct Transformation
    label::String
    input::Spaces
    output::Spaces
    transformation::Function

    function Transformation(label, input, output, transformation)
        t = new(label, input, output, transformation)
        push!(_TRANSFORMATIONS, t)
        t
    end
end

show(io::IO, t::Transformation) = print(io, t.label)

const Transformations = Set{Transformation}
const _TRANSFORMATIONS = Transformations()

transformations() = _TRANSFORMATIONS


########################################################
# SEARCH OVER TRANSFORMATIONS
########################################################

function search_path(start_node, neighbors::Function, goal::Function)
    history = Dict{Any, Any}()  # child -> (parent, action)
    history[start_node] = nothing
    
    queue = [start_node]
    visited = Set([start_node])

    while !isempty(queue)
        current = popfirst!(queue)

        if goal(current)
            return current, reconstruct_path(current, history)
        end

        # neighbors(node) must return pairs: (action, next_state)
        for (action, neighbor) in neighbors(current)
            if neighbor ∉ visited
                push!(visited, neighbor)
                push!(queue, neighbor)
                history[neighbor] = (current, action)
            end
        end
    end
    nothing
end

function reconstruct_path(end_node, history)
    path = []
    current = end_node
    while !isnothing(history[current])
        parent, action = history[current]
        pushfirst!(path, action)
        current = parent
    end
    path
end

# 1. Define the Neighbor Generator
# Input: A Set of Spaces
# Output: Vector of (Transformation, New_Set_of_Spaces)
function get_neighbor_states(current_spaces::Spaces)
    results = []
    
    problem_spaces = filter(!implementable, current_spaces)
    
    if isempty(problem_spaces)
        return [] # No neighbors; already solved!
    end

    for problem_space ∈ problem_spaces
      # Look up possible transformations for this specific space
      # Assumes you have a dict: transformations[Space] -> Vector{Transformation}
      possible_moves = filter(t -> problem_space ∈ t.input, _TRANSFORMATIONS)

      for move in possible_moves
          # Apply the move: Remove old space, add new targets
          new_set = copy(current_spaces)
          delete!(new_set, problem_space)
          union!(new_set, move.output)
          push!(results, (move, new_set))
      end
    end
    results
end

convexify(t::Term) = search_path(Spaces(space.(variables(t))), get_neighbor_states, implementable)

convexify!(t::Term) = ( (_,ts) = convexify(t); apply!(ts) )


apply!(ts::Vector) = (apply!.(ts); nothing)

function apply!(transformation::Transformation, universe::Universe, new_universe::Symbol)

    # if the universe does not contain the input spaces of the transformation, do nothing
    # if !(transformation.input ⊆ spaces(universe))
    #     error("Universe $universe does not contain the input spaces of the transformation $transformation")
    #     return universe
    # end

    # clone the universe
    U = clone(universe, new_universe)

    # apply the transformation in the cloned universe
    in_universe(U) do
        transformation.transformation()
    end

    # return the transformed universe
    return U
end
