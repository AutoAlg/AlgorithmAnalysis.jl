
############################################################################################
# The zero expression
zero(::T) where {T<:Expression} = T(Zero())
zero(::Type{T}) where {T<:Expression} = T(Zero())

convert(::Type{T}, ::Zero) where {T<:Expression} = T(Zero())


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
            associations::Associations

            function $(esc(ex.args[1]))(label::String, value::VectorValue, constraints::Constraints, oracles::Oracles, next::State)
                associations = Dict(Dual => LinearFunctional{$(esc(ex.args[1]))}())
                new(label, value, constraints, oracles, next, associations)
            end
        end
    end
end

"""
Custom expression for Gram matrices.
    Contains a vector the outter product of which forms the Gram matrix.
"""
struct Gram <: Expression
    label:: String 
    vecs :: Vector{V} where {F<:Field, V<:InnerProductSpace{F}}
    value:: Missing
    constraints::Constraints
    oracles::Oracles
    next::State{Zero}
    function Gram(vecs::Vector{V} where {F<:Field, V<:InnerProductSpace{F}})
        new("", vecs, missing, Constraints(), Oracles(), missing)
    end
end

############################################################################################
# Constructors

# label
function (::Type{T})(label::String = "Variable{$T}") where {T<:AbstractVectorSpace}
    T(label, missing, Constraints(), Oracles(), missing)
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
        T(label, value, Constraints(), Oracles(), missing)
    end
end
function (::Type{T})(value::VectorValue{T}) where {T<:VectorSpace}
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
constraints(e::Tuple{Expression, Expression}) = first(e).constraints ∪ last(e).constraints

"""
    oracles(e)

List the oracles that have been sampled at the expression e

# Examples
```julia-repl
julia> x = Rⁿ()
julia> oracles(x)
```
"""
oracles(e::Expression) = e.oracles
oracles(e::Tuple{Expression, Expression}) = first(e).oracles ∪ last(e).oracles
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

Check if the expression e is a variable

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
iszero(e::Tuple{Expression, Expression}) = first(e).value isa Zero && last(e).value isa Zero
"""
    hasdecomposition(e)

Check if the expression e has a decomposition

# Examples
```julia-repl
julia> x = Rⁿ()
julia> hasdecomposition(e)
```
"""
hasdecomposition(e::Expression) = e.value isa Decomposition
"""
    hasvalue(e)

Check if the expression e or every expression in an array or set of expression has a value

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

Return the decomposition of the expression e if it has one, throws an error otherwise

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

Return the value of the expression e or an array of expression if it has one, throws an error otherwise

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

Assign an expression e a value val or array of expressions with values from an array of values 

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

Return variable expressions of an expression e 
# Examples
```julia-repl
julia> x = Rⁿ()
julia> variables(x)
```
"""
variables(e::Tuple{Expression, Expression}) = variables(first(e)) ∪ variables(last(e))
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

Return the decomposition of an expression e if it has a non-empty decomposition, return its LinearDecomposition otherwise
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

# update
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
"""

function next(e::Tuple{Expression, Expression}) # next of a tuple of expressions to support PD
    if (!ismissing(next(first(e))) && !ismissing(next(last(e)))) # next of a tuple of unsampled expressions
        (next(first(e)), next(last(e)))
    else # next of a tuple of oracle output expressions
        for o in oracles(e)
            index = findfirst(ex -> isequal(e, ex), inputs_outputs(o)[2])
            if index != nothing # oracle found
                nexte = next(inputs_outputs(o)[1][index])
                nextindex = !ismissing(nexte) ? findfirst(ex -> isequal(nexte, ex), inputs_outputs(o)[1]) : missing
                if !ismissing(nextindex)
                    return inputs_outputs(o)[2][nextindex]
                end
            end
        end
        (missing, missing)
    end
end
                

function next(f::AbstractFunction)
    if f isa LinearFunctional
        io = inputs_outputs(f)
        index = findfirst(ex -> ex === f, io[2])
        if index === nothing
            return missing
        end
        nextx = next(io[1][index])
        if ismissing(nextx)
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

function next(f::Oracle)
    return f
end

function next(f::Wrapper{<:Oracle})
    return f
end

function next(d:: Dual{})
    return d'.next'
end

function next(x::Expression)
    if !ismissing(x.next) # If x has a next, return it #|| (!hasdecomposition(x) && isa(x, R))
        return x.next
    end
    if !hasdecomposition(x) # If it is a varible
        # orc = nothing
        # if length(oracles(x)) == 0
        #     return missing
        # elseif length(oracles(x)) == 1 && !isnothing(findfirst(ex -> ex === x, inputs_outputs(first(oracles(x)))[2]))
        #     orc = first(oracles(x))
        # else
        #     for o in oracles(x)
        #         io = inputs_outputs(o)
        #         index = findfirst(ex -> ex === x, io[2])
        #         if !isnothing(index)  
        #             orc = o
        #         end
        #     end
        # end
        # if isnothing(orc)
        #     return missing
        # end
        # io = inputs_outputs(orc)
        # index = findfirst(ex -> ex === x, io[2])
        # nextx = next(io[1][index])
        orc, input = get_oracle_input(x) # Find the oracle and input used to create x
        if ismissing(orc) || ismissing(input)
            return missing
        end
        nextx = next(input) # get nextx in order to sample the oracle at nextx  # nextx = next(io[1][index])
        # if hasfield(typeof(orc), :next) || typeof(orc) == Dual{Rⁿ} || typeof(orc) == LinearFunctional{Rⁿ}
        #     nextoracle = next(orc)
        # else
        #     nextoracle = orc
        # end
        nextoracle = next(orc)
        if nextoracle === missing || nextx === missing
            return missing
        end
        nextio = inputs_outputs(nextoracle)
        for i in eachindex(nextio[1]) # Return oracle(nextx) only if the oracle has been sampled at nextx
            if nextx isa Tuple # Search if tuple nextx has been sampled
                x1, x2, y1, y2 = first(nextx), last(nextx), first(nextio[1][i]), last(nextio[1][i])
                if nextio[1][i] isa Tuple && (isequal(x1, y1) && isequal(x2,y2))
                    next!(x, nextio[2][i]) 
                    return nextio[2][i]
                end
            elseif !(nextio[1][i] isa Tuple) && (nextx === nextio[1][i] || (hasdecomposition(nextx) && hasdecomposition(nextio[1][i]) && isequal(nextx, nextio[1][i]))) #abs(sum(collect(values(weights(nextx - nextio[1][i]))))) < 1e-10) # Search if non-tuple nextx has been sampled on its on
                if hasfield(typeof(x), :next)
                    next!(x, nextio[2][i])
                    return nextio[2][i]
                end
            elseif nextio[1][i] isa Tuple && (nextx === first(nextio[1][i]) || (hasdecomposition(nextx) && hasdecomposition(first(nextio[1][i])) && isequal(nextx, first(nextio[1][i])))) # Search if non-tuple nextx has been sampled as first() of a tuple
                if hasfield(typeof(x), :next)
                    next!(x, first(nextio[2][i]))
                    return first(nextio[2][i])
                end                
            elseif nextio[1][i] isa Tuple && (nextx === last(nextio[1][i]) || (hasdecomposition(nextx) && hasdecomposition(last(nextio[1][i])) && isequal(nextx, last(nextio[1][i])))) # Search if non-tuple nextx has been sampled as last() of a tuple
                if hasfield(typeof(x), :next)
                    next!(x, last(nextio[2][i]))
                    return last(nextio[2][i])
                end 
            end
        end
        return missing
    else
        nextx = zero(x)
        for i in collect(keys(weights(decomposition(x))))
            if i.next === missing
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

Given a pair of expression, update the second expression as the next state of the first expression
# Examples
```julia-repl
julia> a = [Rⁿ(), Rⁿ()]
julia> next(a)
```
"""
function update!(p::Pair{T, <:State{T}}) where {T}
    next!(first(p), last(p))
    nothing
end

"""
    weights(e)

If the expression e have a decomposition, return a dictionary whose entries are variable expressions in e's decomposition and their corresponding weights in e.
# Examples
```julia-repl
julia> x0 = Rⁿ()
julia> x1 = x0 - 0.2*f'(x0) 
julia> weights(x1)
```
"""
weights(e::Expression) = weights(decomposition(e))
"""
    size(g::Gram)
    size(e::Expression)
    size(c::Constraint)

Return the size of input `e` depending on its type
- **Gram expression**:
Return the sie of the Gram matrix if `e` is a Gram matrix expression

- **Expression**:
Return (1,1) as the size of an expression e

- **Constraint**:
Return (1,1) as the size of the expression of a constraint `e`
# Examples
```julia-repl
julia> x0 = Rⁿ()
julia> size(x1)
```
"""
size(e::Expression) = (1,1)
size(g::Gram) = size(evaluate(g))
"""
    length(e::Expression)
    length(o::Oracle)

Returns the length of the input depending on its type
-- *Expression*:
Return 1 as the length of an expression
-- *Oracle*:
Return the number of expression at which the oracle e has been sampled

# Examples
```julia-repl
julia> x0 = Rⁿ()
julia> length(x0)

julia> f = DifferentiableFunctional{Rⁿ}()
julia> length(f')
```
"""
length(e::Expression) = 1

iterate(e::Expression) = iterate(e,1)
iterate(e::Expression, state::Int) = (state > length(e) ? nothing : (e, state+1))

############################################################################################
# Evaluate

"""
    evaluate(e::Expression)
    evaluate(g::Gram)

Return the an evaluation of an input e depending on its type:
- **Expression**:  
  If `e` is an expression which has a value, return the value
  If `e` is an expression which has a decomposition, return the value of the expressions in the decomposition
  Otherwise return missing
  If `e` is an array of expressions, evaluate each element and return an array of values
-**Gram matrix expression**
Return the Gram matrix

# Examples
```julia-repl
julia> x0 = Rⁿ()
julia> x1 = x0 - 0.2*f'(x0) 
julia> evaluate(x1)

julia> g = Gram([x0,x1])
julia> evaluate(g)
```
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
    ⊂(g1, g2)

Return whether gram matrix expression g1 is a strict subset of gram matrix expression g2, or if every elements in g1 is in g2 and there is atleast one element in g2 not in g1
"""
# function ⊂(g1::Gram, g2::Gram) # strict subset
#     v1, v2 = Set(g1.vecs), Set(g2.vecs)
#     return isempty(setdiff(v1, v2)) && !isempty(setdiff(v2, v1))
# end
⊂(g1::Gram, g2::Gram) = ⊂(Expressions(g1.vecs), Expressions(g2.vecs))
"""
    ⊆(g1, g2)

Return whether gram matrix expression g1 is a subset or equalof gram matrix expression g2, or if every elements in g1 is in g2
"""
# function ⊆(g1::Gram, g2::Gram) # subset or equal
#     v1, v2 = Set(g1.vecs), Set(g2.vecs)
#     return isempty(setdiff(v1, v2))
# end
⊆(g1::Gram, g2::Gram) = ⊆(Expressions(g1.vecs), Expressions(g2.vecs))

function ⊂(s1::Expressions, s2::Expressions) # strict subset
    return isempty(setdiff(s1, s2)) && !isempty(setdiff(s2, s1))
end
function ⊆(s1::Expressions, s2::Expressions) # subset or equal
    return isempty(setdiff(s1, s2))
end
