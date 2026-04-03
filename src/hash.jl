import Base.hash

"""
    hash(x, h::UInt)

Hash of an expression. Custom types must provide specialized methods for this function due to [this issue](https://github.com/JuliaLang/julia/issues/10267).
"""
function hash end

hash(e::Oracle, h::UInt) = hash(relation(e), h)

function hash(e::Expression, h::UInt)
    if !ismissing(e.value)
        hash(e.value, hash(:Expression, h))
    else
        hash(objectid(e), h)
    end
end
hash(x::LinearDecomposition, h::UInt) = hash(weights(x), hash(:LinearDecomposition, h))
hash(c::Constraint, h::UInt) = hash(set(c), hash(expression(c), hash(:Constraint, h)))
hash(c::Satisfied, ::UInt) = objectid(c)
hash(c::Unsatisfied, ::UInt) = objectid(c)
hash(g::Gram, h::UInt) = hash(vecs1(g), hash(vecs2(g), hash(constraints(g), hash(oracles(g), hash(:Gram, h)))))

function hash(a::AbstractArray{<:Expression}, h::UInt)
    h = hash(size(a), hash(:AbstractArray, h))
    for x ∈ a
        h = hash(x, h)
    end
    h
end


############################################################################################
# IsEqual

isequal(::Expression, ::Any) = false
isequal(::Any, ::Expression) = false
isequal(::Expression, ::Expression) = false

function isequal(x1::T, x2::T) where {T<:Expression}
    if !isdefined(x1, :value) || !isdefined(x2, :value)
        false
    elseif !isvariable(x1) && !isvariable(x2)
        isequal(value(x1), value(x2))
    elseif isvariable(x1) && isvariable(x2)
        x1.value == x2.value
    else
        false
    end
end

isequal(g1::Gram, g2::Gram) = isequal(vecs1(g1), vecs1(g2)) && isequal(vecs2(g1), vecs2(g2))

function isequal(x1::AbstractArray{<:Expression}, x2::Expression)
    length(x1) == 1 && isequal(x1[1], x2) ? true : false
end
isequal(x1::Expression, x2::AbstractArray{<:Expression}) = isequal(x2,x1)

function isequal(x1::LinearDecomposition{T}, x2::LinearDecomposition{T}) where {T}
    isequal(weights(x1), weights(x2))
end
function isequal(a1::AbstractArray{T}, a2::AbstractArray{T}) where {T<:Expression}
    isequal(size(a1), size(a2)) && all( isequal(a1[i],a2[i]) for i ∈ eachindex(a1) )
end

isequal(x::T, y::Wrapper{T}) where {T} = isequal(x, unwrap(y))
isequal(x::Wrapper{T}, y::T) where {T} = isequal(unwrap(x), y)

function isequal(lhs::Constraint, rhs::Constraint)
    isequal( set(lhs), set(rhs) ) && isequal( expression(lhs), expression(rhs) )
end
isequal(::Satisfied, ::Satisfied) = true
isequal(::Unsatisfied, ::Unsatisfied) = true
isequal(::Satisfied, ::Constraint) = false
isequal(::Unsatisfied, ::Constraint) = false
isequal(::Constraint, ::Satisfied) = false
isequal(::Constraint, ::Unsatisfied) = false