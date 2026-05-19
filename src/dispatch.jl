
export implementations, dispatch, related, leaves, search, neighbors, leaf


########################################################
# REGISTER TRAITS
########################################################
"""
    register!

Registers a term. For traits, recursively registers each field. For objects, if the object is labeled, this calls the dispatcher when the object label is called on any components.
"""
function register! end

register!(::Any...) = nothing

function register!(t::Trait)
    for field in fieldnames(typeof(t))
        x = getfield(t, field)
        register!(x)
    end
    t
end

register!(x::Object) = register!(label(x))

function register!(sym::Symbol)
    @eval begin
        export $sym
        $sym(x::Term, y::Term, args::Vararg{Any}) = dispatch($(QuoteNode(sym)), promote(x, y, args...)...)
        $sym(x::Term, args::Any...) = dispatch($(QuoteNode(sym)), promote(x, args...)...)
        $sym(x::Any, y::Term, args::Any...) = dispatch($(QuoteNode(sym)), promote(x, y, args...)...)
    end
end

"""
    implementations(op, args...)

Finds all valid implementations of the function `op` on the arguments `args`. Valid implementations of `op` include when it is:
  - the label of a leaf object of args, e.g., +(G)
  - the label of a leaf object of args, and args is in the domain of the object, e.g., -g
"""
function implementations end

function implementations(op::Symbol, s::Space)
    filter(c -> c isa Object && op === label(c), leaves(s))
end

function implementations(op::Symbol, x::Object)
    nodes = related(space(x))
    filter(c -> c isa Object && op === label(c) && hastrait(c, Map) && x ∈ domain(c), nodes)
end

implementations(op::Symbol, xs::Object...) = implementations(op, as_product(xs...))


########################################################
# DISPATCHER
########################################################

"""
    dispatch(op, args...)

Finds all valid implementations of the function `op` on the arguments `args`, and executes the single valid option, or errors if either none or more than one valid options are available. Dispatches if `op` is:
  - the label of a leaf object of args, e.g., +(G)
  - the label of a leaf object of args, and args is in the domain of the object, e.g., -g
"""
function dispatch end

function dispatch(op::Symbol, s::Space)
    valid = implementations(op, s)
    if isempty(valid)
        error("No valid implementations of $op for space $s.")
    elseif length(valid) > 1
        @warn "Multiple implementations of $op for space $s. Returning all valid implementations."
        return valid
    end
    first(valid)
end

function dispatch(op::Symbol, x::Object)
    valid = implementations(op, x)
    if isempty(valid)
        error("No valid implementations of $op for object $x in space $(space(x)).")
    elseif length(valid) > 1
        @warn "Multiple implementations of $op for object $x in space $(space(x)). Returning all valid implementations."
        return valid
    end
    first(valid)(x)
end

dispatch(op::Symbol, xs::Object...) = dispatch(op, as_product(xs...))

function search(init::Set, neighbors::Function)
    T = eltype(init)
    visited = Set{T}()
    queue = init
    while !isempty(queue)
        node = pop!(queue)
        if node ∉ visited
            push!(visited, node)
            for neighbor ∈ neighbors(node)
                if neighbor ∉ visited
                    push!(queue, neighbor)
                end
            end
        end
    end
    visited
end

related(args::Terms) = search(args, neighbors)
related(args::Term...) = related(Terms(args))
leaves(args::Terms) = search(args, leaf)
leaves(args::Term...) = leaves(Terms(args))

neighbors(::Term) = error("Not implemented")
neighbors(s::Space) = traits(s) ∪ elements(s)
neighbors(t::Trait) = [ getfield(t,f) for f ∈ fieldnames(typeof(t)) if getfield(t,f) isa Term ]
neighbors(t::Product) = Terms(t.spaces)

function neighbors(x::Object)
    objs = Terms([space(x)])
    if !isnothing(get(x, Map))
        push!(objs, graph(x))
    end
    objs
end

leaf(t::Term) = error("leaf not implemented for term of type $(typeof(t))")
leaf(s::Space) = traits(s)
leaf(t::Trait) = [ getfield(t,f) for f ∈ fieldnames(typeof(t)) if getfield(t,f) isa Object || getfield(t,f) isa Trait ]
leaf(t::Product) = Terms(t.spaces)
leaf(::Object) = Terms()

function execute(op::Function, valid::Terms)
    if length(valid) == 1
        return first(valid)
    elseif isempty(valid)
        error("No valid components that support $op.")
    else
        error("Multiple components that support $op.\nValid components: $valid")
    end
end
