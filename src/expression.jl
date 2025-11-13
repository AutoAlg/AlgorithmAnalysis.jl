
############################################################################################
# The zero expression

zero(::T) where {T<:Expression} = T(Zero())
zero(::Type{T}) where {T<:Expression} = T(Zero())

convert(::Type{T}, ::Zero) where {T<:Expression} = T(Zero())


############################################################################################
# Macro definitions of concrete expression types

"""
    macro field(F)

Defines a field `F`.
"""
macro field(s::Symbol)
    quote
        mutable struct $(esc(s)) <: Field
            label::String
            value::ScalarValue{$(esc(s))}
            constraints::Constraints
            oracles::Oracles
            next::State{$(esc(s))}
        end
    end
end

"""
    macro randomfield(F)

Defines a random field `F`.
"""
macro randomfield(s::Symbol, t::Symbol)
    quote
        mutable struct $(esc(s)) <: RandomField{$(esc(t))}
            label::String
            value::ScalarValue{$(esc(s))}
            constraints::Constraints
            oracles::Oracles
            next::State{$(esc(s))}
            mean::$(esc(t))
        end
    end
end

"""
    macro vectorspace(V, F)

Defines a vector space `V` over a field `F`.
"""
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
        end
    end
end

"""
    macro normedvectorspace(V, F)

Defines a normed vector space `V` over a field `F`.
"""
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
        end
    end
end

"""
    macro innerproductspace(V, F)

Defines an inner product space `V` over a field `F`.
"""
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
            associations::Associations

            function $(esc(ex.args[1]))(label::String, value::VectorValue, constraints::Constraints, oracles::Oracles, next::State)
                associations = Dict(Dual => LinearFunctional{$(esc(ex.args[1]))}())
                new(label, value, constraints, oracles, next, associations)
            end
        end
    end
end

"""
    Gram <: Expression

A Gram matrix is a matrix of inner product between all pairs of a set of vectors.
"""
struct Gram <: Expression
    label:: String 
    value:: Missing
    constraints::Constraints
    oracles::Oracles
    next::State{Zero}
    vecs::Vector{V} where {F<:Field, V<:InnerProductSpace{F}}

    function Gram(vecs::Vector{V} where {F<:Field, V<:InnerProductSpace{F}})
        new("", missing, Constraints(), Oracles(), missing, vecs)
    end
end

############################################################################################
# Constructors

# label
function (::Type{T})(label::String = "Variable{$T}") where {T<:AbstractVectorSpace}
    if T <: RandomField
        T(label, missing, Constraints(), Oracles(), missing, deterministic(T)())
    else
        T(label, missing, Constraints(), Oracles(), missing)
    end
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
    if value isa Decomposition && length(weights(value)) == 1 && first(values(weights(value))) == 1
        first(keys(weights(value)))
    else
        if T <: RandomField
            T(label, value, Constraints(), Oracles(), missing, deterministic(T)())
        else
            T(label, value, Constraints(), Oracles(), missing)
        end
    end
end
# AFTER
function (::Type{T})(value::Union{Missing, Zero, Decomposition, Vector}) where {T<:VectorSpace}
    if isempty(value)
        label = "Variable{$T}"
    elseif iszero(value)
        label = "0"
    else
        label = ""
    end
    if value isa Decomposition && length(weights(value)) == 1 && first(values(weights(value))) == 1
        first(keys(weights(value)))
    else
        T(label, value, Constraints(), Oracles(), missing)
    end
end


############################################################################################
# Methods
constraints(e::Expression) = e.constraints

field(::Type{T}) where {F<:Field, T<:VectorSpace{F}} = F
 
"""
    oracles(e)

List of oracles that have been sampled at the expression `e`.

# Examples
```julia-repl
julia> x = Rⁿ()
julia> oracles(x)
```
"""
oracles(e::Expression) = e.oracles

"""
    associations(::Expression)
    associations(e::InnerProductSpace)
    associations(o::Oracle)

List the associations of an input e depending on its type:
-- *Expression*
If the input is an expression, return an empty set of associations.
-- *InnerProductSpace Expression*:
If the input is an inner product space expression, return its associations field.
-- *Oracle*:
If the input is an oracle,  return the set of oracles associated with the oracle `o` if it has a `associations` property, otherwise return an empty set of associations.


# Examples
```julia-repl
julia> e = Rⁿ()
julia> associations(e)
```
"""
associations(::Expression) = Associations()
associations(e::InnerProductSpace) = e.associations

# types of expressions
"""
    isvariable(e)

Check if the expression `e` is a variable.

# Examples
```julia-repl
julia> x = Rⁿ()
julia> isvariable(x)
```
"""
isvariable(e::Expression) = e.value isa Missing

"""
    iszero(e::Expression)
    iszero(o::Oracle) = false
    iszero(o::ZeroFunctional) = true

Check if an input is zero depending on its type
-- *Expression**:
Check if the expression e is a Zero object
-- *Oracle**:
Check wheter an oracle is Zero, only true when it is a ZeroFunctional oracle

# Examples
```julia-repl
julia> x = Rⁿ()
julia> iszero(x)
```

"""
iszero(e::Expression) = e.value isa Zero

"""
    hasdecomposition(e)

Check if the expression `e` has a decomposition.

# Examples
```julia-repl
julia> x = Rⁿ()
julia> hasdecomposition(e)
```
"""
hasdecomposition(e::Expression) = e.value isa Decomposition

"""
    hasvalue(e)

Check if the expression `e` or every expression in an array or set of expression has a value.

# Examples
```julia-repl
julia> x = Rⁿ()
julia> hasvalue(x)

julia> x = [Rⁿ(), Rⁿ()]
julia> hasvalue(x)
```
"""
hasvalue(e::Expression) = !isvariable(e) && !hasdecomposition(e)
hasvalue(a::ArrayOrSet{Expression}) = all(hasvalue(e) for e ∈ a)

"""
    decomposition(e)

Return the decomposition of the expression `e` if it has one, throws an error otherwise.

# Examples
```julia-repl
julia> x = Rⁿ()
julia> decomposition(x)
```
"""
function decomposition(e::Expression)
    hasdecomposition(e) ? e.value : error("Expression $e does not have a decomposition")
end

"""
    value(e)

Return the value of the expression `e` or an array of expression if it has one, throws an error otherwise

# Examples
```julia-repl
julia> x = Rⁿ()
julia> value(x)
```
"""
function value(e::Expression)
    hasvalue(e) ? e.value : error("Expression $e does not have a value")
end

value(a::AbstractArray{<:Expression}) = [ value(e) for e ∈ a ]

"""
    value!(e, val)

Assign a value to an expression or array of expressions. 

# Examples
```julia-repl
julia> x = Rⁿ()
julia> value!(x,val)
```
"""
value!(e::Expression, val) = (e.value = val)
function value!(a::AbstractArray{<:Expression}, val::AbstractArray)
    if size(a) ≠ size(val)
        error("Sizes incompatible for assignment")
    else
        foreach( (e,v) -> value!(e, v), zip(a,val) )
    end
end

"""
    variables(e)

Return variable expression of an expression `e`.

# Examples
```julia-repl
julia> x = Rⁿ()
julia> variables(x)
```
"""
function variables(e::Expression)
    if hasdecomposition(e)
        variables(decomposition(e))
    elseif e isa Gram
        Set(e.vecs)
    elseif isvariable(e)
        Expressions([e])
    else
        Expressions()
    end
end

"""
    selfdecomp(e)

Return the decomposition of an expression if it has a non-empty decomposition, return its LinearDecomposition otherwise.

# Examples
```julia-repl
julia> x = Rⁿ()
julia> selfdecomp(x)
```
"""
function selfdecomp(e::T) where {T<:Expression}
    if hasdecomposition(e) && !isempty(decomposition(e))
        decomposition(e)
    else
        LinearDecomposition(e)
    end
end

"""
    next!(e1, e2)

Set the expression e2 as the next field of the expression e1
# Examples
```julia-repl
julia> e1 = Rⁿ()
julia> e2 = Rⁿ()
julia> next(e1, e2)
```
"""
next!(x::T, y::State{T}) where {T<:Expression} = x.next = y

"""
    next(f::AbstractFunction)
    next(f::Oracle)
    next(f::Wrapper{<:Oracle})
    next(d:: Dual{})
    next(e::Expression)
    next(a::AbstractArray{<:Expression})
    next(o::Oracle)

Return the next state of the input `x`. The behavior of `next` depends on the type and structure of `x`:

- **AbstractFunction (`f`)**:
If `f` is an abstract function that returns itself when sampled at an expression `e`
- **Expression (`e`)**:  
  If `e` has a `next` field, return it.  
  If `e` was created by sampling an oracle at another expression `x`, and `x` has a `next` state, return the oracle sampled at `next(x)`.  
  If `e` has a decomposition where all variable expressions have a `next` field, return a new expression constructed from the next state of each component.  
  Otherwise, return `missing`.
  If `e` is the transpose of `e'`, and `f'` is the next state of `e'`, return the transpose of `f'`.

- **Oracle (`o`)**:  
  Return the oracle itself, assuming it represents its own next state.

- **Array or set of expressions (`a`)**:  
  Return a collection containing the next state of each expression in `a`.

# Examples
```julia-repl
julia> e = Rⁿ()
julia> next(e)

julia> e = e'
julia> next(e)

julia> f = DifferentiableFunctional{Rⁿ}()
julia> f ∈ SmoothStronglyConvex(m, L)
julia> next(f')

julia> a = [Rⁿ(), Rⁿ()]
julia> next(a)
```
"""
function next(f::AbstractFunction)
    if f isa LinearFunctional
        io = inputs_outputs(f)
        index = findfirst(ex -> ex === f, io[2])
        if index === nothing
            return missing
        end
        nextx = next(io[1][index])
        if nextx === missing
            return missing
        end
        for i in eachindex(io[2])
            if nextx === io[1][i] || (hasdecomposition(nextx) && hasdecomposition(io[1][i]) && abs(sum(collect(values(weights(nextx - io[1][i]))))) < 1e-10)
                return io[2][i]
            end
        end
        return missing
    else
        return f
    end
end

next(f::Oracle) = f
next(f::Wrapper{<:Oracle}) = f
next(d:: Dual{}) = d'.next'
next(::Missing) = missing

function next(x::Expression)
    if !ismissing(x.next)
        return x.next
    end
    if !hasdecomposition(x)
        orc, input = get_oracle_input(x)
        nextx = next(input)
        nextoracle = next(orc)
        if ismissing(nextoracle) || ismissing(nextx)
            return missing
        end
        nextio = inputs_outputs(nextoracle)
        for i in eachindex(nextio[1])
            if nextx === nextio[1][i] || iszero(nextx - nextio[1][i]) || (hasdecomposition(nextx) && hasdecomposition(nextio[1][i]) && abs(sum(collect(values(weights(nextx - nextio[1][i]))))) < 1e-10)
                if hasfield(typeof(x), :next)
                    next!(x, nextio[2][i])
                end
                return nextio[2][i]
            end
        end
        return missing
    else
        nextx = zero(x)
        for i in collect(keys(weights(decomposition(x))))
            if ismissing(i.next)
                return missing
            end
            nextx = nextx + weights(decomposition(x))[i] * i.next
        end
        next!(x, nextx)
        return nextx
    end   
end
next(a::AbstractArray{<:Expression}) = [ next(x) for x ∈ a ]

"""
    update!(p)

Given a pair of expressions, update the second expression as the next state of the first expression.

# Examples
```julia-repl
julia> x  = Rⁿ()
julia> x⁺ = Rⁿ()
julia> update!( x => x⁺ )
```
"""
function update!(p::Pair{T, <:State{T}}) where {T}
    next!(first(p), last(p))
    nothing
end

"""
    weights(e)

If the expression `e` have a decomposition, return a dictionary whose entries are variable expressions in `e`'s decomposition and their corresponding weights in `e`.
# Examples
```julia-repl
julia> x0 = Rⁿ()
julia> x1 = x0 - 0.2*f'(x0) 
julia> weights(x1)
```
"""
weights(e::Expression) = weights(decomposition(e))


size(::Expression) = (1,1)
size(g::Gram) = size(evaluate(g))

length(::Expression) = 1
iterate(e::Expression) = iterate(e,1)
iterate(e::Expression, state::Int) = (state > 1 ? nothing : (e, state+1))


############################################################################################
# Evaluate

"""
    evaluate(e::Expression)

Evaluates an expression.

If the expression has a value, this returns the value. Otherwise, it returns `missing`.
"""
function evaluate(e::Expression)
    if hasvalue(e)
        value(e)
    elseif hasdecomposition(e)
        evaluate(decomposition(e))
    else
        missing
    end
end
evaluate(x::LinearDecomposition) = mapreduce(p -> last(p)*evaluate(first(p)), +, weights(x))
evaluate(a::AbstractArray{<:Expression}) = [ evaluate(e) for e ∈ a ]
function evaluate(g::Gram)
    return g.vecs ⊗ g.vecs
end

"""
    ⊂(G1, G2)

Returns whether or not Gram matrix `G1` is a strict subset of Gram matrix `G2`.
"""
⊂(g1::Gram, g2::Gram) = ⊂(Expressions(g1.vecs), Expressions(g2.vecs))

"""
    ⊆(g1, g2)

Return whether or not Gram matrix `G1` is a subset or equal of Gram matrix `G2`.
"""
⊆(g1::Gram, g2::Gram) = ⊆(Expressions(g1.vecs), Expressions(g2.vecs))

⊂(s1::Expressions, s2::Expressions) = isempty(setdiff(s1, s2)) && !isempty(setdiff(s2, s1))
⊆(s1::Expressions, s2::Expressions) = isempty(setdiff(s1, s2))
