export Universe, Space, Object, space, spaces, subsets, get, elements, traits
export @universe, @set, @var, @def, @trait
export label, label!, getlabel, haslabel, value, value!, hasvalue
export previous, previous!, next, next!, update, update!
export next, expression, set, get, hastrait
export as_space, scale, source, AbstractSpace, implementable, implementable!
export Evaluation, evaluate, sample
export get_universe, in_universe, clone, default_universe, register!
export trait_objects

export _CACHE


#########################################################
# STRUCTS
#########################################################

struct Universe
    label::Symbol
    spaces::Dict{Symbol, AbstractSpace}

    function Universe(label::Symbol = gensym(); spaces::Dict{Symbol, AbstractSpace} = Dict{Symbol, AbstractSpace}())
        get!(_CACHE, label) do
            new(label, spaces)
        end
    end
end

const _CACHE = IdDict{Symbol, Any}()
const default_universe = Universe(:default_universe)
const UNIVERSE = ScopedValue{Universe}(default_universe)

function clone(U::Universe, sym::Symbol)
    if sym ∈ keys(_CACHE)
        error("Cannot create universe $sym because it already exists.")
    end
    Universe(sym, spaces = deepcopy(U.spaces))
end

get_universe()::Universe = UNIVERSE[]

in_universe(code::Function, universe::Universe) = with(code, UNIVERSE => universe)

label(U::Universe) = U.label

show(io::IO, U::Universe) = print(io, label(U))

function show(io::IO, ::MIME"text/plain", U::Universe)
    print(io, "Universe")
    print(io, "\n  Label  : ", label(U))
    print(io, "\n  Spaces : ", join(spaces(U), ", "))
end

struct ID
    id::UInt32
    space::Symbol
end

mutable struct Space <: AbstractSpace
    label::Symbol
    elements::Dict{ID, AbstractObject}
    subsets::Dict{Symbol, AbstractSpace}
    traits::Traits
    next_valid_id::UInt32

    function Space(label::Symbol; universe::Universe = get_universe(), traits=Traits(), trait=nothing)
        get!(universe.spaces, label) do
            ts = traits
            if !isnothing(trait)
                push!(ts, trait)
            end
            new(
                label,
                Dict{ID, AbstractObject}(),
                Dict{Symbol, AbstractSpace}(),
                ts,
                UInt32(0)
            )
        end
    end
end

function allocate_id(space::Space)::ID
    id = space.next_valid_id
    space.next_valid_id += 1
    return ID(id, space.label)
end

"""
    Object(space; label, value, next, labeler, trait)
"""
mutable struct Object <: AbstractObject
    id::ID
    label::Label
    value::Any
    next::Union{Object, Missing}
    labeler::Union{Function, Missing}
    trait::Union{Trait, Missing}

    function Object(space::Space; id::ID=allocate_id(space), label::Label=missing, value=missing, next=missing, labeler=missing, trait=missing)
        get!(space.elements, id) do
            new(
                id,
                label,
                value,
                next,
                labeler,
                trait
            )
        end
    end
end

struct Evaluation
    f::Object
    x::Object
end


#########################################################
# CONSTANTS
#########################################################

const Spaces = Set{Space}
const Objects = Set{Object}


#########################################################
# MACROS
#########################################################

"""
    @universe A, B, ...

Define one or more universes.
"""
macro universe(ex)
    function _recurse(x)
        if x isa Symbol
            universe = esc(x)
            label = QuoteNode(x)
            quote
                $universe = Universe($label)
            end
        elseif x isa Expr && (x.head == :block || x.head == :tuple)
            Expr(:block, map(_recurse, x.args)...)
        elseif x isa LineNumberNode
            x
        else
            error("Invalid expression for @universe macro: $x")
        end
    end
    quote
        $(_recurse(ex)); nothing
    end
end

"""
    @set A, B, ...

Define one or more sets of objects.
"""
macro set(ex)
    function _recurse(x)
        if x isa Symbol
            space = esc(x)
            label = QuoteNode(x)
            quote
                $space = Space($label)
                # $Prop ∈ PredicateLogic($space)
            end
        elseif x isa Expr && (x.head == :block || x.head == :tuple)
            Expr(:block, map(_recurse, x.args)...)
        elseif x isa LineNumberNode
            x
        else
            error("Invalid expression for @set macro: $x")
        end
    end
    quote
        $(_recurse(ex)); nothing
    end
end

"""
    @var a ∈ A, b ∈ B, ...

Define one or more objects in given sets.
"""
macro var(ex)
    function _recurse(x)
        if x isa Expr && x.head == :call && (x.args[1] == :(∈) || x.args[1] == :in)
            a = esc(x.args[2])
            A = esc(x.args[3])
            sym = QuoteNode(x.args[2])
            quote
                $a = sample($A, $sym)
                nothing
            end
        elseif x isa Expr && (x.head == :block || x.head == :tuple)
            Expr(:block, map(_recurse, x.args)...)
        elseif x isa LineNumberNode
            x
        else
            error("Invalid expression for @var macro: $x")
        end
    end
    quote
        $(_recurse(ex)); nothing
    end
end

"""
    @def a = expr

Define an object with a given expression.
"""
macro def(ex)
    function _recurse(x)
        if x.head == :(=)
            lhs = esc(x.args[1])
            rhs = esc(x.args[2])
            sym = QuoteNode(x.args[1])
            quote
                $lhs = $rhs; label!($lhs, $sym); nothing
            end
        else
            error("Invalid expression for @def macro: $x")
        end
    end
    quote
        $(_recurse(ex)); nothing
    end
end

"""
    @trait A, t1, t2, ...

Assign a list of traits to a set.
"""
macro trait(args...)
    inputs = args
    if length(args) == 1 && args[1] isa Expr && args[1].head == :tuple
        inputs = args[1].args
    end

    # validation
    if length(inputs) < 2
        error("Usage: @trait Set, Trait1, Trait2, ...")
    end

    S = inputs[1]
    traits = inputs[2:end]

    # build expressions
    output_block = Expr(:block)
    
    for prop in traits
        new_call = nothing
        
        if prop isa Expr && prop.head == :call
            # Case: Trait(Args...) -> Trait(S, Args...)
            func = prop.args[1]
            func_args = prop.args[2:end]
            new_call = Expr(:call, func, S, func_args...)
            
        elseif prop isa Symbol
            # Case: Trait -> Trait(S)
            new_call = Expr(:call, prop, S)
            
        else
            error("Invalid trait expression: $prop")
        end
        
        # Add "S in Trait(...)" to the block
        push!(output_block.args, :($S ∈ $new_call; nothing))
    end
    
    esc(output_block)
end


#########################################################
# METHODS
#########################################################

function implementable(s::Space)
    hastrait(s, Numeric) ||
        (!isnothing(get(s, Product)) && all(implementable.(spaces(s)))) ||
        !isnothing(get(s, Graph)) ||
        (!isnothing(get(s, Subset)) && implementable(parent(s)))
end
implementable(x::Object) = implementable(space(x))
implementable(::Trait) = true
implementable(ss::Spaces) = all(implementable.(ss))

label(s::Space) = s.label
elements(s::Space) = Objects(values(s.elements)) ∪ mapreduce(elements, ∪, subsets(s); init=Objects())
subsets(s::Space) = Spaces(values(s.subsets))
traits(s::Space) = s.traits

∈(s::Space, t::Trait) = push!(traits(s), t)
∈(s::Space, ts::Traits) = map(t -> s ∈ t, ts)
∈(x::Object, s::Space) = x.id ∈ keys(s.elements)

function get(s::Space, T::Type{<:Trait})
    ts = filter(p -> p isa T, traits(s))
    if isempty(ts)
        nothing
    elseif length(ts) > 1
        error("Space $s has multiple traits of type $T: $ts")
    else
        first(ts)
    end
end

get(x::Object, T::Type{<:Trait}) = get(space(x), T)

show(io::IO, x::Space) = print(io, label(x))

function show(io::IO, ::MIME"text/plain", x::Space)
    print(io, "Set")
    !ismissing(label(x))  && print(io, "\n  Label    : ", label(x))
    !isempty(elements(x)) && print(io, "\n  Elements : ", join(elements(x), ", "))
    !isempty(subsets(x))  && print(io, "\n  Subsets  : ", join(subsets(x), ", "))
    !isempty(traits(x))   && print(io, "\n  Traits   : ", join(traits(x), ", "))
end

iterate(s::Space) = iterate(elements(s))
length(s::Space) = length(elements(s))
isempty(s::Space) = isempty(elements(s))

space(id::ID, universe::Universe = get_universe()) = universe.spaces[id.space]
space(x::Object) = space(x.id)
spaces(universe::Universe = get_universe()) = Spaces(values(universe.spaces))
objects(x::Object) = Set{Object}([x])
haslabel(x::Object) = !ismissing(label(x))
hasnext(x::Object) = !ismissing(next(x))
hasvalue(x::Object) = !ismissing(value(x))
next!(x::Object, y::Union{Object, Missing}) = (x.next = y; nothing)
next(xs::AbstractArray{<:Object}) = [ next(x) for x ∈ xs ]
# update!(p::Pair{T, T}) where T = next!( first(p), last(p) )

push!(space::Space, object::Object) = space.elements[allocate_id(space)] = object

function source(x::Object)
    T = space(x)
    for trait ∈ traits(T)
        for sym ∈ fieldnames(typeof(trait))
            op = getfield(trait, sym)
            if op isa Object{<:Map}
                if x ∈ outputs(op)
                    return op, inverse(op, x)
                end
            end
        end
    end
    return nothing
end

label(x::Object) = x.label
value(x::Object) = x.value
next(x::Object) = x.next
value!(x::Object, val = missing) = (x.value = val; nothing)
label!(x::Object, l::Label = missing) = (x.label = l; nothing)

function evaluate(x::Object; dict::Dict = Dict(), model::Union{JuMP.GenericModel, Missing} = missing)
    if x ∈ keys(dict)
        return dict[x]
    end
    if hasvalue(x)
        val = value(x)
        if val isa Evaluation
            f = evaluate(val.f, dict=dict, model=model)
            y = evaluate(val.x, dict=dict, model=model)

            if codomain(val.f) === Space(:Prop)
                t = get(domain(val.f)[1], Order)
                if ~isnothing(t) && val.f ∈ trait_objects(t)
                    if val.f === t.ordering
                        return JuMP.@constraint(model, 0 ≤ evaluate(val.x[2]-val.x[1], dict=dict, model=model))
                    end
                end
            end
            # if con isa Equality
            #     return JuMP.@constraint(model, 0 == ex )
            # elseif con isa Positive
            #     return JuMP.@constraint(model, 0 ≤ ex )
            # elseif con isa Semidefinite
            #     JuMP.@constraint(model, ex .== ex' )
            #     return JuMP.@constraint(model, 0 ≤ ex, JuMP.PSDCone() )
            # else
            #     error("Optimization with constraint $con not implemented")
            # end

            return f(y...)
        else
            return val
        end
    end
    if hastrait(x, Product)
        return evaluate.(as_tuple(x), dict=dict, model=model)
    end
    for S ∈ numeric()
        if x ∈ trait_objects(S)
            return eval(label(x))
        end
    end

    error("Cannot evaluate $x.")
end

trait_objects(::Trait) = Objects()
trait_objects(S::Space) = mapreduce(trait_objects, ∪, traits(S))

function clear(x::Object)
    value!(x, missing)
    next!(x, missing)
end

function show(io::IO, val::Evaluation)
    f = val.f
    x = val.x
    t = get(x, Product)
    if !isnothing(t) && length(x) == 2
        if hastrait(f, Binder)
            print(io, f, " ", x[1], " ∈ ", space(x[1]), ", ", x[2])
        else
            print(io, x[1], " ", f, " ", x[2])
        end
    elseif label(f) === :adjoint
        print(io, "(", x, ")'")
    else
        print(io, f, "(", x, ")")
    end
end

function show(io::IO, x::Object)
    if haslabel(x)
        print(io, label(x))
    elseif hasvalue(x)
        print(io, value(x))
    elseif !isnothing(get(x, Product))
        print(io, "(", join(as_tuple(x), ", "), ")")
    elseif !isnothing(get(x, Graph))
        print(io, "(", input(x), ", ", output(x), ")")
    else
        print(io, "Object in $(space(x))")
    end
end

function show(io::IO, ::MIME"text/plain", x::Object)
    print(io, "Object in ", space(x))
    haslabel(x) && print(io, "\n  Label : ", label(x))
    hasvalue(x) && print(io, "\n  Value : ", value(x))
    hasnext(x)  && print(io, "\n  Next  : ", next(x))
end

function show(io::IO, ::MIME"text/plain", elements::Objects)
    if isempty(elements)
        print(io, "Empty set of objects")
    else
        print(io, "Set with $(length(elements)) " * (isone(length(elements)) ? "objects:" : "objects:"))
        foreach( v -> print(io, "\n  ", v), elements )
    end
end


#########################################################
# FREE AND BOUND VARIABLES
#########################################################

export variables, free, bound

function variables(x::Object)
    val = value(x)
    if val isa Evaluation
        variables(val.f) ∪ variables(val.x)
    elseif hastrait(space(x), Product)
        mapreduce(variables, ∪, as_tuple(x))
    elseif ismissing(val)
        Objects([x])
    else
        Objects()
    end
end

function free(x::Object)

    function _free!(x::Object, vars::Objects)
        val = value(x)
        if val isa Evaluation
            if hastrait(val.f, Binder)
                delete!(vars, val.x[1])
                _free!(val.x[2], vars)
            else
                _free!(val.f, vars)
                _free!(val.x, vars)
            end
        elseif hastrait(x, Product)
            map(v -> _free!(v, vars), as_tuple(x))
        end
    end

    vars = copy(variables(x))
    _free!(x, vars)
    vars
end

bound(x::Object) = setdiff(variables(x), free(x))


#########################################################
# REGISTER PROPERTIES
#########################################################
"""
    register!

Registers a term. For traits, recursively registers each field. For objects, if the object is labeled, this calls the dispatcher when the object label is called on any components.
"""
function register! end

register!(::Any...) = nothing

function register!(t::Trait)
    for field in fieldnames(typeof(t))
        x = getfield(t, field)
        register!(x, t)
    end
    t
end

function register!(x::Object, t::Trait)
    if ismissing(label(x))
        nothing
    else
        @eval $x.trait = $t
        register!(label(x))
    end
end

function register!(sym::Symbol)
    @eval begin
        export $sym
        $sym(x::Term, y::Term, args::Any...) = dispatch($(QuoteNode(sym)), promote(x, y, args...)...)
        $sym(x::Term, args::Any...) = dispatch($(QuoteNode(sym)), promote(x, args...)...)
        $sym(x::Any, y::Term, args::Any...) = dispatch($(QuoteNode(sym)), promote(x, y, args...)...)
    end
end
