############################################################################################
# CACHE
############################################################################################
const _CACHE = IdDict{DataType, Union{Space, Property}}()
clear_cache(::DataType) = delete!(_CACHE, N)


############################################################################################

# iterate over Tuples of spaces
iterate(T::Type{<:Tuple{Vararg{Space}}}) = iterate(T,1)
function iterate(T::Type{<:Tuple{Vararg{Space}}}, state::Int)
    state > length(T) ? nothing : ( T.parameters[state], state+1 )
end
length(T::Type{<:Tuple{Vararg{Space}}}) = length(T.parameters)


############################################################################################

# iterating over a space iterates over the elements of the space
iterate(T::Union{Space, Type{<:Space}}) = iterate(elements(T))
iterate(T::Union{Space, Type{<:Space}}, state::Int) = iterate(elements(T), state)
isempty(s::Union{Space, Type{<:Space}}) = isempty(elements(s))
length(s::Union{Space, Type{<:Space}}) = length(elements(s))


############################################################################################
# SET
############################################################################################

"""
    @set A, B, ...

Define one or more sets of objects. Each symbol is used to define a set type and singleton constructor.
"""
macro set(ex)
    _set(ex)
end

function _set(s::Symbol)
    T = esc(s)
    sym = QuoteNode(s)
    quote
        struct $T <: Space
            label::Label
            elements::Objects{$T}
            properties::Properties

            function $T()
                get!( _CACHE, $T ) do
                    new( $sym, Objects{$T}(), Properties{$T}() )
                end
            end
        end
    end
end

function _set(expr::Expr)
    if expr.head == :block
        Expr(:block, [ _set(arg) for arg ∈ expr.args ]...)
    elseif expr.head == :tuple
        Expr(:block, [ _set(arg) for arg ∈ expr.args ]...)
    else
        error("Invalid expression for @set macro")
    end
end

instance(T::Type{<:Space}) = T()

elements(s::Space) = s.elements
elements(T::Type{<:Space}) = elements(T())

properties(s::Space) = s.properties
properties(T::Type{<:Space}) = properties(T())

sample(T::Type{<:Space}, label::Label) = Atom{T}(label)
push!(T::Type{<:Space}, x::Object) = push!(elements(T), x)


############################################################################################
# VAR
############################################################################################
"""
    @var a ∈ A, b ∈ B, ...

Define one or more objects in given sets.
"""
macro var(ex)
    _var(ex)
end

function _var(expr::Expr)
    if expr.head == :tuple
        Expr(:block, [ _var(arg) for arg ∈ expr.args ]...)
    elseif expr.head == :call && (expr.args[1] == :(∈) || expr.args[1] == :in)
        # Notation: a ∈ A
        a = esc(expr.args[2])
        A = esc(expr.args[3])
        sym = QuoteNode(expr.args[2])
        quote
            $a = sample($A, $sym); nothing
        end
    elseif expr.head == :call && expr.args[1] == :→ && expr.args[2] isa Expr && expr.args[2].head == :call && expr.args[2].args[1] == :(:)
        # Notation: f : X → Y
        f = esc(expr.args[2].args[2])
        X = esc(expr.args[2].args[3])
        Y = esc(expr.args[3])
        sym = QuoteNode(expr.args[2].args[2])
        quote
            $f = sample($X → $Y, $sym); nothing
        end
    elseif expr.head == :call && expr.args[1] == :⇒ && expr.args[2] isa Expr && expr.args[2].head == :call && expr.args[2].args[1] == :(:)
        # Notation: F : X ⇒ Y
        F = esc(expr.args[2].args[2])
        X = esc(expr.args[2].args[3])
        Y = esc(expr.args[3])
        sym = QuoteNode(expr.args[2].args[2])
        quote
            $F = sample($X ⇒ $Y, $sym); nothing
        end
    elseif expr.head == :call && expr.args[1] == :⊂ && expr.args[2] isa Symbol && expr.args[3] isa Symbol
        # Notation: A ⊂ B
        A = esc(expr.args[2])
        B = esc(expr.args[3])
        sym = QuoteNode(expr.args[2])
        quote
            $A = Subset{$B}($sym); nothing
        end
    elseif expr.head == :(=)
        # Notation: x = expr
        lhs = esc(expr.args[1])
        rhs = esc(expr.args[2])
        sym = string(expr.args[1])
        quote
            $lhs = $rhs; label!($lhs, $sym); nothing
        end
    else
        error("""@var expects one of the following notations:
          a ∈ A
          A ⊂ B
          f : X → Y
          F : X ⇒ Y
          x = expr
        """)
    end
end

############################################################################################
# INTERSECTION
############################################################################################

struct SetIntersection{T<:Tuple{Vararg{Space}}} <: Space
    elements::Objects{SetIntersection{T}}

    SetIntersection{T}() where {T<:Tuple{Vararg{Space}}} = get!(_CACHE, SetIntersection{T}) do
        new{T}( Objects{SetIntersection{T}}() )
    end
end

spaces(::Type{SetIntersection{T}}) where T = T

function ∩(T1::Type{<:Space}, T2::Type{<:Space})
    t1 = T1 <: SetIntersection ? spaces(T1) : Tuple{T1}
    t2 = T2 <: SetIntersection ? spaces(T2) : Tuple{T2}
    T = sort(unique(collect(t1 ∪ t2)), by = x -> string(x))
    SetIntersection{Tuple{T...}}
end

elements(::Type{SetIntersection{T}}) where T = mapreduce(elements, ∩, T) 


############################################################################################
# UNION
############################################################################################

struct SetUnion{T<:Tuple{Vararg{Space}}} <: Space
    elements::Objects{SetUnion{T}}

    SetUnion{T}() where {T<:Tuple{Vararg{Space}}} = get!(_CACHE, SetUnion{T}) do
        new{T}( Objects{SetUnion{T}}() )
    end
end

spaces(::Type{SetUnion{T}}) where T = T

function ∪(T1::Type{<:Space}, T2::Type{<:Space})
    t1 = T1 <: SetUnion ? spaces(T1) : Tuple{T1}
    t2 = T2 <: SetUnion ? spaces(T2) : Tuple{T2}
    T = sort(unique(collect(t1 ∪ t2)), by = x -> string(x))
    SetUnion{Tuple{T...}}
end
