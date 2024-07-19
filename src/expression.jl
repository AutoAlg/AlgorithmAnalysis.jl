
############################################################################################
# The zero expression

zero(::V) where {V<:AbstractVectorSpace} = V(Zero())

# +(x::VectorExpression, ::Zero) = x
# +(::Zero, x::VectorExpression) = x
# -(x::VectorExpression, ::Zero) = x
# -(::Zero, x::VectorExpression) = -x
# *(::Any, ::Zero) = Zero()
# *(::Zero, ::Any) = Zero()
# *(::VectorExpression, ::Zero) = Zero()
# *(::Zero, ::VectorExpression) = Zero()
# *(::Zero, ::LinearDecomposition) = Zero()
# /(::Any, ::Zero) = NaN
# /(::Zero, ::Any) = Zero()
# /(::VectorExpression, ::Zero) = NaN
# /(::Zero, ::VectorExpression) = Zero()

############################################################################################
# Macro definitions of concrete expression types



"Define a field."
macro field(s::Symbol)
    quote
        mutable struct $(esc(s)) <: Field
            label::String
            value::Union{Number,Missing}
            constraints::Constraints
            oracles::Oracles
            next::State{$(esc(s))}
            previous::State{$(esc(s))}
        end
    end
end

"Define a vector space over a field."
macro vectorspace(ex::Expr)
    if !(ex.head == :tuple && length(ex.args) == 2 && ex.args[1] isa Symbol && ex.args[2] isa Symbol)
        throw(ArgumentError("@vectorspace: `$(ex)` must be of the form: `V, F` where `V` is a vector space over a field `F`."))
    end
    quote
        mutable struct $(esc(ex.args[1])) <: VectorSpace{$(esc(ex.args[2]))}
            label::String
            value::Union{Vector,Missing,Zero}
            constraints::Constraints
            oracles::Oracles
            next::State{$(esc(ex.args[1]))}
            previous::State{$(esc(ex.args[1]))}
        end
    end
end

"Define a normed vector space over a field."
macro normedvectorspace(ex::Expr)
    if !(ex.head == :tuple && length(ex.args) == 2 && ex.args[1] isa Symbol && ex.args[2] isa Symbol)
        throw(ArgumentError("@normedvectorspace: `$(ex)` must be of the form: `V, F` where `V` is a normed vector space over a field `F`."))
    end
    quote
        mutable struct $(esc(ex.args[1])) <: NormedVectorSpace{$(esc(ex.args[2]))}
            label::String
            value::Union{Vector,Missing,Zero}
            constraints::Constraints
            oracles::Oracles
            next::State{$(esc(ex.args[1]))}
            previous::State{$(esc(ex.args[1]))}
        end
    end
end

"Define an inner product space over a field."
macro innerproductspace(ex::Expr)
    if !(ex.head == :tuple && length(ex.args) == 2 && ex.args[1] isa Symbol && ex.args[2] isa Symbol)
        throw(ArgumentError("@innerproductspace: `$(ex)` must be of the form: `V, F` where `V` is an inner product space over a field `F`."))
    end
    quote
        mutable struct $(esc(ex.args[1])) <: InnerProductSpace{$(esc(ex.args[2]))}
            label::String
            value::Union{Vector,Missing,Zero}
            constraints::Constraints
            oracles::Oracles
            next::State{$(esc(ex.args[1]))}
            previous::State{$(esc(ex.args[1]))}
            associations::Associations

            function $(esc(ex.args[1]))(label::String, value::Union{Vector,Missing,Zero}, constraints::Constraints, oracles::Oracles, next::State{$(esc(ex.args[1]))}, previous::State{$(esc(ex.args[1]))})
                associations = Dict(Dual => LinearFunctional{$(esc(ex.args[1]))}())
                new(label, value, constraints, oracles, next, previous, associations)
            end
        end
    end
end


############################################################################################
# Methods

value(e::Variable) = e.value
value(a::AbstractArray{<:Expression}) = [ value(e) for e ∈ a ]
value!(e::Variable, val) = (e.value = val)
function value!(a::AbstractArray{<:Variable}, val::AbstractArray)
    if size(a) ≠ size(val)
        error("Sizes incompatible for assignment")
    else
        for (e,v) ∈ zip(a,val)
            value!(e, v)
        end
    end
end
constraints(e::Variable) = e.constraints
constraints(a::AbstractArray{<:Variable}) = constraints(e for e ∈ a)
oracles(e::Variable) = e.oracles
oracles(a::AbstractArray{<:Variable}) = oracles(e for e ∈ a)
variables(e::Variable) = hasvalue(e) ? Variables() : Variables([e])
variables(a::AbstractArray{<:Variable}) = variables(e for e ∈ a)
variables(::Missing) = Variables()

# types of expressions
iszero(e::Variable) = hasvalue(e) && iszero(value(e))
hasvalue(e::Variable) = !ismissing(value(e))
hasvalue(a::AbstractArray{<:Variable}) = all(hasvalue(e) for e ∈ a)
hasvalue(x::LinearDecomposition) = all(hasvalue(v) for v ∈ keys(weights(x)))

# update
next!(x::T, y::State{T}) where {T<:Variable} = x.next = y
next(x::Variable) = x.next
next(a::AbstractArray{<:Variable}) = [ next(x) for x ∈ a ]
previous!(x::T, y::State{T}) where {T<:Variable} = x.previous = y
previous(x::Variable) = x.previous
previous(a::AbstractArray{<:Variable}) = [ previous(x) for x ∈ a ]

function update!(p::Pair{T, <:State{T}}) where {T}
    next!(first(p), last(p))
    # previous!(last(p), first(p))
    nothing
end


############################################################################################
# Constructors

# variable
function (::Type{V})(label::String = "Variable{$V}") where {V<:AbstractVectorSpace}
    V(label, missing, Constraints(), Oracles(), missing, missing)
end

# constant
function (::Type{V})(value) where {V<:AbstractVectorSpace}
    V(string(value), value, Constraints(), Oracles(), missing, missing)
end

# zero
function (::Type{V})(::Zero) where {V<:AbstractVectorSpace}
    V("0", Zero(), Constraints(), Oracles(), missing, missing)
end


############################################################################################
# Evaluate

evaluate(e::Variable) = (hasvalue(e) ? value(e) : missing)
evaluate(x::LinearDecomposition) = mapreduce(p -> last(p)*evaluate(first(p)), +, weights(x))
evaluate(p::Tuple{X,X}) where {X<:InnerProductSpace} = evaluate(p[1])'*evaluate(p[2])
evaluate(a::AbstractArray{<:Variable}) = [ evaluate(e) for e ∈ a ]

############################################################################################
# IsEqual

isequal(x1::Expression, x2::Expression) = false

function isequal(x1::AbstractArray{<:Expression}, x2::Expression)
    if length(x1) == 1 && isequal(x1[1], x2)
        true
    else
        false
    end
end
isequal(x1::Expression, x2::AbstractArray{<:Expression}) = isequal(x2,x1)

function isequal(x1::LinearDecomposition{T}, x2::LinearDecomposition{T}) where {T}
    isequal(weights(x1), weights(x2))
end
function isequal(a1::AbstractArray{T}, a2::AbstractArray{T}) where {T<:Variable}
    isequal(size(a1), size(a2)) && all( isequal(a1[i],a2[i]) for i ∈ eachindex(a1) )
end

isequal(x1::T, x2::T) where {T<:Variable} = isequal(objectid(x1), objectid(x2))
isequal(x::T, y::Wrapper{T}) where {T} = isequal(x, unwrap(y))
isequal(x::Wrapper{T}, y::T) where {T} = isequal(unwrap(x), y)
