
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
    elseif e isa Gram
        Set(e.vecs)
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
                return nextio[2][i]
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
    if x.next !== missing #|| (!hasdecomposition(x) && isa(x, R))
        return x.next
    end
    if !hasdecomposition(x)
        orc = nothing
        if length(oracles(x)) == 0
            return missing
        elseif length(oracles(x)) == 1
            orc = first(oracles(x))
        else
            for o in oracles(x)
                io = inputs_outputs(o)
                index = findfirst(ex -> ex === x, io[2])
                if !isnothing(index)  
                    orc = o
                end
            end
        end
        if isnothing(orc)
            return missing
        end
        io = inputs_outputs(orc)
        index = findfirst(ex -> ex === x, io[2])
        nextx = next(io[1][index])
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

function update!(p::Pair{T, <:State{T}}) where {T}
    next!(first(p), last(p))
    nothing
end

weights(e::Expression) = weights(decomposition(e))

size(e::Expression) = (1,1)
length(e::Expression) = 1

iterate(e::Expression) = iterate(e,1)
iterate(e::Expression, state::Int) = (state > length(e) ? nothing : (e, state+1))

############################################################################################
# Evaluate

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

# Gram expression
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

function evaluate(g::Gram)
    return g.vecs ⊗ g.vecs
end

size(g::Gram) = size(evaluate(g))

function ⊂(g1::Gram, g2::Gram) # strict subset
    v1, v2 = Set(g1.vecs), Set(g2.vecs)
    return isempty(setdiff(v1, v2)) && !isempty(setdiff(v2, v1))
end

function ⊆(g1::Gram, g2::Gram) # subset or equal
    v1, v2 = Set(g1.vecs), Set(g2.vecs)
    return isempty(setdiff(v1, v2))
end

prune!(s::Constraints) = setdiff!(s, Set([Satisfied()]))
function prune_grams(s::Constraints)
    pruned = Constraints()
    for c in s
        if expression(c) isa Gram
            to_remove = Constraints()  # Store constraints to remove
            should_add = true
            for existing_c in pruned
                if expression(existing_c) isa Gram
                    if expression(existing_c) ⊂ expression(c) # Existing is a strict subset → Mark it for removal
                        push!(to_remove, existing_c)
                    end
                    if expression(c) ⊆ expression(existing_c)  # New one is a subset of existing
                        should_add = false  # Don't add the new one
                        break
                    end
                end
            end
            for r in to_remove # Remove outdated constraints
                delete!(pruned, r)
            end
            if should_add # Add the new constraint if it is not a subset of any existing one
                push!(pruned, c)
            end
        else
            push!(pruned, c)  # Keep non-Gram constraints
        end
    end
    # pruned = gram_to_constraint(pruned)
    return pruned
end