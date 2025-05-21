export ℝ, →, @symbolic, @assume, sample, has_assumption, assumptions,
       FunctionArrow, ConvexFunctions, SymbolicPoint, UnknownFunction,
       BinaryFunction, ScaledFunction, ComposedFunction,
       ElementSet, FunctionType, Point, @set, @sample, elements, parents, SetUnion, SetINtersection, CartesianProduct, AbstractElementSet


############################################################################################
"""
    AbstractElementSet{T} <: Set{T}

An `AbstractElementSet` is a set that keeps track of its elements.
"""
abstract type AbstractElementSet{T} <: AbstractSet{T} end

∈(x::T, S::AbstractElementSet{T}) where T = x ∈ elements(S)
iterate(S::AbstractElementSet) = iterate(elements(S))
iterate(S::AbstractElementSet, state) = iterate(elements(S), state)
push!(S::AbstractElementSet{T}, x::T) where T = push!(S.elements, x)
length(S::AbstractElementSet) = length(elements(S))

struct ElementSet{T} <: AbstractElementSet{T}
    label::Symbol
    elements::Set{T}

    ElementSet{T}(label::Symbol) where T = new{T}(label, Set{T}())
end

label(S::ElementSet) = S.label
elements(S::ElementSet) = S.elements


############################################################################################
struct SetUnion{T} <: AbstractElementSet{T}
    elements::Set{T}
    parents::Set{AbstractElementSet{T}}

    SetUnion{T}(parents::AbstractElementSet{T}...) where T = new{T}(Set{T}(), Set(parents))
end

parents(S::SetUnion) = S.parents

function elements(S::SetUnion{T}) where T
    S.elements ∪ mapreduce(elements, ∪, parents(S); init=Set{T}())
end

∪(S1::AbstractElementSet{T}, S2::AbstractElementSet{T}) where T = SetUnion{T}(S1, S2)
∪(S1::AbstractElementSet{T}, S2::SetUnion{T}) where T = SetUnion{T}(S1, parents(S2)...)
∪(S1::SetUnion{T}, S2::AbstractElementSet{T}) where T = SetUnion{T}(parents(S1)..., S2)
∪(S1::SetUnion{T}, S2::SetUnion{T}) where T = SetUnion{T}(parents(S1)..., parents(S2)...)


############################################################################################
struct SetIntersection{T} <: AbstractElementSet{T}
    elements::Set{T}
    parents::Set{AbstractElementSet{T}}

    SetIntersection{T}(parents::AbstractElementSet{T}...) where T = new{T}(Set{T}(), Set(parents))
end

parents(S::SetIntersection) = S.parents

function elements(S::SetIntersection{T}) where T
    S.elements ∪ mapreduce(elements, ∩, parents(S); init=Set{T}())
end

∩(S1::AbstractElementSet{T}, S2::AbstractElementSet{T}) where T = SetIntersection{T}(S1, S2)
∩(S1::AbstractElementSet{T}, S2::SetIntersection{T}) where T = SetIntersection{T}(S1, parents(S2)...)
∩(S1::SetIntersection{T}, S2::AbstractElementSet{T}) where T = SetIntersection{T}(parents(S1)..., S2)
∩(S1::SetIntersection{T}, S2::SetIntersection{T}) where T = SetIntersection{T}(parents(S1)..., parents(S2)...)


############################################################################################
struct CartesianProduct{T} <: AbstractElementSet{T}
    elements::Set{T}
    parents::Vector{AbstractElementSet{T}}

    CartesianProduct{T}(parents::AbstractElementSet{T}...) where T = new{T}(Set{T}(), [parents...])
end

parents(S::CartesianProduct) = S.parents

function elements(S::CartesianProduct{T}) where T
    S.elements ∪ mapreduce(elements, tuple, parents(S); init=Set{T}())
end

×(S1::AbstractElementSet{T}, S2::AbstractElementSet{T}) where T = CartesianProduct{T}(S1, S2)
×(S1::AbstractElementSet{T}, S2::CartesianProduct{T}) where T = CartesianProduct{T}(S1, parents(S2)...)
×(S1::CartesianProduct{T}, S2::AbstractElementSet{T}) where T = CartesianProduct{T}(parents(S1)..., S2)
×(S1::CartesianProduct{T}, S2::CartesianProduct{T}) where T = CartesianProduct{T}(parents(S1)..., parents(S2)...)

############################################################################################


# function ∩(S1::AbstractLazySet{T}, S2::AbstractLazySet{T}) where T
#     DerivedSet{T}(() -> elements(S1) ∩ elements(S2))
# end

# function setdiff(S1::AbstractLazySet{T}, S2::AbstractLazySet{T}) where T
#     DerivedSet{T}(() -> setdiff(elements(S1), elements(S2)))
# end




# function all_elements(S::LazySet)
#     S.elements ∪ mapreduce(all_elements, ∪, S.parents; init=Set())
# end

# Base.iterate(S::LazySet{T}) where T = iterate(all_elements(S))
# Base.iterate(S::LazySet{T}, state) where T = iterate(all_elements(S), state)


############################################################################################
# Reals
############################################################################################
export R

struct R
    label::Symbol
    value::Union{Missing, Real}
end

R(label::Symbol) = R(label, missing)
R(value::Real) = R(Symbol(""), value)

convert(::Type{R}, x::Real) = R(x)


""" Represent function domains/codomains like ℝ → ℝ """
struct FunctionArrow{X, Y} end
const → = FunctionArrow
const ℝ = Float64

""" Symbolic function type declaration """
struct FunctionType{X, Y} end
struct Point{T} end

""" Basic symbolic point """
abstract type AbstractPoint{T} end

struct SymbolicPoint{T} <: AbstractPoint{T}
    name::Symbol
end

Base.:+(a::AbstractPoint, b::AbstractPoint) = SymbolicPoint{typeof(a)}(gensym(:sum_))
Base.:*(c::Number, a::AbstractPoint) = SymbolicPoint{typeof(a)}(gensym(:scaled_))


# """ Symbolic function space marker """
# struct ConvexFunctions{X, Y}
#     dom::LazySet{X}
#     codom::LazySet{Y}

#     ConvexFunctions(::LazySet{X}, ::LazySet{Y}) where {X, Y} = new{X, Y}(LazySet(:dom), LazySet(:codom))
# end

# """ Symbolic function expression types """
# abstract type AbstractSymbolicFunction{X, Y} end

# mutable struct UnknownFunction{X, Y} <: AbstractSymbolicFunction{X, Y}
#     name::Symbol
#     space::ConvexFunctions{X, Y}
#     cache::Dict{Any, Any}
#     UnknownFunction(name::Symbol, space) = new{X, Y}(name, space, Dict())
# end

# struct BinaryFunction{Op, X, Y} <: AbstractSymbolicFunction{X, Y}
#     f::AbstractSymbolicFunction{X, Y}
#     g::AbstractSymbolicFunction{X, Y}
# end

# struct ScaledFunction{X, Y, T} <: AbstractSymbolicFunction{X, Y}
#     α::T
#     f::AbstractSymbolicFunction{X, Y}
# end

# struct ComposedFunction{X, Y, Z} <: AbstractSymbolicFunction{X, Z}
#     f::AbstractSymbolicFunction{Y, Z}
#     g::AbstractSymbolicFunction{X, Y}
# end

# """ Function operations """
# Base.:+(f::AbstractSymbolicFunction{X, Y}, g::AbstractSymbolicFunction{X, Y}) where {X, Y} = BinaryFunction{:+, X, Y}(f, g)
# Base.:*(α::T, f::AbstractSymbolicFunction{X, Y}) where {T, X, Y} = ScaledFunction{X, Y, T}(α, f)
# Base.:∘(f::AbstractSymbolicFunction{Y, Z}, g::AbstractSymbolicFunction{X, Y}) where {X, Y, Z} = ComposedFunction{X, Y, Z}(f, g)

# """ Sampling support """
# sample(f::AbstractSymbolicFunction{X, Y}, x::AbstractPoint{X}) where {X, Y} = _sample(f, x)

# function _sample(f::UnknownFunction{X, Y}, x::AbstractPoint{X}) where {X, Y}
#     haskey(f.cache, x) && return f.cache[x]
#     y = SymbolicPoint{Y}(gensym("$(f.name)_at_"))
#     f.cache[x] = y
#     return y
# end

# function _sample(f::BinaryFunction{Op, X, Y}, x::AbstractPoint{X}) where {Op, X, Y}
#     y1 = sample(f.f, x)
#     y2 = sample(f.g, x)
#     return SymbolicPoint{Y}(gensym("bin_"))
# end

# function _sample(f::ScaledFunction{X, Y, T}, x::AbstractPoint{X}) where {X, Y, T}
#     y = sample(f.f, x)
#     return SymbolicPoint{Y}(gensym("scale_"))
# end

# function _sample(f::ComposedFunction{X, Y, Z}, x::AbstractPoint{X}) where {X, Y, Z}
#     inner = sample(f.g, x)
#     outer = sample(f.f, inner)
#     return outer
# end

# """ Symbolic declaration macro """
# macro symbolic(args...)
#     esc_exprs = []
#     for arg in args
#         if !(arg isa Expr && arg.head == :(::))
#             error("@symbolic expects expressions like `x::Point{T}`")
#         end
#         name = arg.args[1]
#         typ = arg.args[2]
#         if typ.head == :curly
#             head = typ.args[1]
#             params = typ.args[2:end]
#             if head == :FunctionType
#                 X, Y = params
#                 push!(esc_exprs, :( $(esc(name)) = UnknownFunction{$(esc(X)), $(esc(Y))}($(QuoteNode(name)), ConvexFunctions(LazySet(:dom), LazySet(:codom))) ))
#             elseif head == :Point
#                 T = params[1]
#                 push!(esc_exprs, :( $(esc(name)) = SymbolicPoint{$(esc(T))}($(QuoteNode(name))) ))
#             elseif head == :ConvexFunction
#                 arrow = params[1]
#                 if arrow.head == :curly && arrow.args[1] == :FunctionArrow
#                     X, Y = arrow.args[2:end]
#                     push!(esc_exprs, :( $(esc(name)) = UnknownFunction{$(esc(X)), $(esc(Y))}($(QuoteNode(name)), ConvexFunctions(LazySet(:dom), LazySet(:codom))) ))
#                 else
#                     error("Expected FunctionArrow in ConvexFunction")
#                 end
#             else
#                 error("Unsupported symbolic type: $head")
#             end
#         else
#             error("Invalid symbolic declaration: $typ")
#         end
#     end
#     return esc(Expr(:block, esc_exprs...))
# end

# """ Assumptions registry """
# const ASSUMPTIONS = IdDict{Any, Set{Any}}()

# macro assume(expr)
#     if !(expr isa Expr && expr.head == :call && expr.args[1] == :∈)
#         error("@assume expects `symbol ∈ set`")
#     end
#     sym = esc(expr.args[2])
#     prop = esc(expr.args[3])
#     return quote
#         if !haskey(ASSUMPTIONS, $sym)
#             ASSUMPTIONS[$sym] = Set{Any}()
#         end
#         push!(ASSUMPTIONS[$sym], $prop)
#     end
# end

# function has_assumption(x, prop)
#     get(ASSUMPTIONS, x, Set()) |> props -> prop in props
# end

# function assumptions(x)
#     get(ASSUMPTIONS, x, Set())
# end

# """ DSL Macros for Sets and Sampling """
# macro set(var)
#     return :( $(esc(var)) = LazySet($(QuoteNode(var))) )
# end

# macro sample(expr)
#     if !(expr isa Expr && expr.head == :in)
#         error("@sample expects `x in S`")
#     end
#     x = esc(expr.args[1])
#     S = esc(expr.args[2])
#     return quote
#         push!($S.elements, $x)
#     end
# end