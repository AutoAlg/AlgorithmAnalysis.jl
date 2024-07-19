
############################################################################################
# The zero expression

zero(::T) where {T<:Expression} = T(Zero())

convert(::Type{T}, ::Zero) where {T<:Expression} = T(Zero())

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
# Variable

# mutable struct Variable{T} <: Expression
#     e::T

#     function Variable(e)
#         if e isa Expression && isempty(decomposition(e))
#             new{typeof(e)}(e)
#         else
#             error("A variable must be an expression with an empty decomposition")
#         end
#     end
# end

# const Variables = Set{Variable}

# convert(::Type{Variable}, e::Expression) = Variable(e)
# convert(::Type{Expression}, v::Variable) = Expression(v)

# expression(v::Variable) = v.e


############################################################################################
# Macro definitions of concrete expression types

"Define a field."
macro field(s::Symbol)
    quote
        mutable struct $(esc(s)) <: Field
            label::String
            value::ScalarValue{$(esc(s))}
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
            value::VectorValue{$(esc(ex.args[1]))}
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
            value::VectorValue{$(esc(ex.args[1]))}
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
            value::VectorValue{$(esc(ex.args[1]))}
            constraints::Constraints
            oracles::Oracles
            next::State{$(esc(ex.args[1]))}
            previous::State{$(esc(ex.args[1]))}
            associations::Associations

            function $(esc(ex.args[1]))(label::String, value::VectorValue, constraints::Constraints, oracles::Oracles, next::State, previous::State)
                associations = Dict(Dual => LinearFunctional{$(esc(ex.args[1]))}())
                new(label, value, constraints, oracles, next, previous, associations)
            end
        end
    end
end


############################################################################################
# Methods

constraints(e::Expression) = e.constraints
oracles(e::Expression) = e.oracles
associations(::Expression) = Associations()
associations(e::InnerProductSpace) = e.associations

# types of expressions
isvariable(e::Expression) = e.value isa Missing
iszero(e::Expression) = e.value isa Zero
hasdecomposition(e::Expression) = e.value isa Decomposition
hasvalue(e::Expression) = !isvariable(e) && !hasdecomposition(e)
hasvalue(a::ArrayOrSet{Expression}) = all(hasvalue(e) for e ∈ a)

function decomposition(e::Expression)
    hasdecomposition(e) ? e.value : error("Expression $e does not have a decomposition")
end

function value(e::Expression)
    hasvalue(e) ? e.value : error("Expression $e does not have a value")
end
value(a::AbstractArray{<:Expression}) = [ value(e) for e ∈ a ]
value!(e::Expression, val) = (e.value = val)
function value!(a::AbstractArray{<:Expression}, val::AbstractArray)
    if size(a) ≠ size(val)
        error("Sizes incompatible for assignment")
    else
        foreach( (e,v) -> value!(e, v), zip(a,val) )
    end
end

function variables(e::Expression)
    if hasdecomposition(e)
        variables(decomposition(e))
    elseif isvariable(e)
        Expressions([e])
    else
        Expressions()
    end
end

function selfdecomp(e::T) where {T<:Expression}
    if hasdecomposition(e) && !isempty(decomposition(e))
        decomposition(e)
    else
        LinearDecomposition(e)
    end
end

# update
next!(x::T, y::State{T}) where {T<:Expression} = x.next = y
next(x::Expression) = x.next
next(a::AbstractArray{<:Expression}) = [ next(x) for x ∈ a ]
previous!(x::T, y::State{T}) where {T<:Expression} = x.previous = y
previous(x::Expression) = x.previous
previous(a::AbstractArray{<:Expression}) = [ previous(x) for x ∈ a ]

function update!(p::Pair{T, <:State{T}}) where {T}
    next!(first(p), last(p))
    # previous!(last(p), first(p))
    nothing
end

weights(e::Expression) = weights(decomposition(e))


############################################################################################
# Constructors

# label
function (::Type{T})(label::String = "Variable{$T}") where {T<:AbstractVectorSpace}
    T(label, missing, Constraints(), Oracles(), missing, missing)
end

# value
function (::Type{T})(value::ScalarValue{T}) where {T<:Field}
    if isempty(value)
        label = "Variable{$T}"
    elseif iszero(value)
        label = "0"
    else
        label = ""
    end
    T(label, value, Constraints(), Oracles(), missing, missing)
end
function (::Type{T})(value::VectorValue{T}) where {T<:VectorSpace}
    if isempty(value)
        label = "Variable{$T}"
    elseif iszero(value)
        label = "0"
    else
        label = ""
    end
    T(label, value, Constraints(), Oracles(), missing, missing)
end


# value and decomposition (at least one of which must be empty)
# function (::Type{T})(value, decomposition::Decomposition{T}) where {T<:AbstractVectorSpace}
#     if isempty(decomposition)
#         T(value)
#     elseif ismissing(value)
#         T(decomposition)
#     else
#         error("In an expression, the value must be missing or the decomposition empty; the value is $value and the decomposition is $decomposition")
#     end
# end

# zero
# function (::Type{T})(::Zero) where {T<:AbstractVectorSpace}
#     T("0", Zero(), Constraints(), Oracles(), missing, missing)
# end


############################################################################################
# Evaluate

evaluate(e::Expression) = (hasvalue(e) ? value(e) : missing)
# evaluate(v::Variable) = evaluate(expression(v))
evaluate(x::LinearDecomposition) = mapreduce(p -> last(p)*evaluate(first(p)), +, weights(x))
evaluate(a::AbstractArray{<:Expression}) = [ evaluate(e) for e ∈ a ]
