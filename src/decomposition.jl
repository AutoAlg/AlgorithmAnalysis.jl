############################################################################################
# DECOMPOSITION
############################################################################################

"""
    Negation{T}

Negation of an expression.
"""
mutable struct Negation{T} <: Decomposition{T}
    label::String
    arg::Atom{T}

    Negation(x::Atom) = new{space(x)}( "", x )
end

"""
    Inverse{T}

Inverse of an expression.
"""
mutable struct Inverse{T} <: Decomposition{T}
    label::String
    arg::Atom{T}

    Inverse(arg::Atom{T}) where T = new{T}( "", arg )
end

"""
    Sum{T}

Sum of expressions.
"""
mutable struct Sum{T} <: CanonicalDecomposition{T}
    label::String
    args::NTuple{N, Atom{T}} where N

    function Sum(t::NTuple{N, Atom{T}}) where {N, T}
        if !ismagma(T,+)
            error("Cannot add expressions in space $T")
        end
        new{T}( "", t )
    end
end

Sum(e::Atom) = Sum( (e,) )
Sum{T}(e::Atom{T}) where T = Sum( (e,) )

function Sum(e1::Atom{T}, e2::Atom{T}) where T
    if iszero(e1)
        e2
    elseif iszero(e2)
        e1
    else
        Sum( (e1, e2) )
    end
end

"""
    Product{T}

Product of expressions.
"""
mutable struct Product{T} <: CanonicalDecomposition{T}
    label::String
    args::NTuple{N, Atom{T}} where N

    function Product(t::NTuple{N, Atom{T}}) where {N, T}
        if !ismagma(T,*)
            error("Cannot multiply expressions in space $T")
        end
        new{T}( "", t )
    end
end

Product(e::Atom) = Product( (e,) )
Product{T}(e::Atom{T}) where T = Product( (e,) )

function Product(e1::Atom{T}, e2::Atom{T}) where T
    if isone(e1)
        e2
    elseif isone(e2)
        e1
    else
        Product( (e1, e2) )
    end
end

"""
    Scaling{T}

Scaling of a vector expression by a scalar expression.
"""
mutable struct Scaling{T} <: CanonicalDecomposition{T}
    label::String
    scalar::Expression{<:Field}
    vector::Atom{T}

    function Scaling(a::Expression, x::Atom)
        if !isvectorspace(space(x), space(a))
            error("$(space(x)) is not a vector space over $(space(a))")
        end
        new{space(x)}( "", a, x )
    end
end

vector(x::Scaling) = x.vector
scalar(x::Scaling) = x.scalar

"""
    Sampling{T}

Sampling of an expression at another expression.
"""
mutable struct Sampling{T} <: CanonicalDecomposition{T}
    label::String
    func::Expression
    input::Expression

    function Sampling(f::Expression, x::Expression)
        if !isfunction(space(f))
            error("Cannot evaluate an expression in space $(space(f))")
        end
        if !canevaluate(space(f), space(x))
            error("Cannot evaluate function $f at expression $x")
        end
        new{codomain(f)}( "", f, x )
    end
end

func(x::Sampling) = x.func
input(x::Sampling) = x.input


############################################################################################
# Canonical decompositions
############################################################################################

# mutable struct Term{T} <: CanonicalDecomposition{T}
#     label::String
#     args::NTuple{N, Atom{T}} where N

#     Term(t::NTuple{N, Atom{T}}) where {N, T} = new{T}( "", t )
# end

# Term(e::Atom) = Term( (e,) )
# Term(e1::Atom{T}, e2::Atom{T}) where T = Term( (e1, e2) )
# Term{T}(e::Atom{T}) where T = Term(e)

"""
    Polynomial{T}

Polynomial expression.
"""
mutable struct Polynomial{T} <: CanonicalDecomposition{T}
    label::String
    terms::Dict{Product{T}, Expression}

    function Polynomial(d::Dict{Product{T}, <:Expression}) where T
        if !isring(T)
            error("Cannot form a polynomial expression in space $T")
        end
        new{T}( "", d )
    end
end

Polynomial(e::Product{T}) where T = Polynomial( Dict(e => one(ring(T))) )
Polynomial(e::Expression{T}) where T = Polynomial( Product(e) )
Polynomial{T}(::Zero) where T = Polynomial( Dict{Product{T}, Expression}() )
Polynomial{T}(::One) where T = Polynomial( one(T) )
Polynomial{T}(e::Atom{T}) where T = Polynomial(e)
Polynomial(e::Sum) = Polynomial( Dict( Product(x) => one(space(e)) for x ∈ args(e) ) )

terms(p::Polynomial) = p.terms

"""
    Rational{T}

Rational expression.
"""
mutable struct RationalExpression{T} <: CanonicalDecomposition{T}
    label::String
    numerator::Polynomial{T}
    denominator::Polynomial{T}

    function RationalExpression(num::Polynomial{T}, den::Polynomial{T}) where T
        if !isfield(T)
            error("Cannot form a rational expression in space $T")
        end
        new{T}( "", num, den )
    end
end

RationalExpression{T}() where T = RationalExpression( Polynomial{T}(𝟎), Polynomial{T}(𝟏) )
RationalExpression(num::Polynomial{T}) where T = RationalExpression( num, Polynomial{T}(𝟏) )
RationalExpression(e::Product{T}) where T = RationalExpression( Polynomial(e) )
RationalExpression(e::Expression{T}) where T = RationalExpression( Product(e) )
RationalExpression{T}(e::Atom{T}) where T = RationalExpression(e)

numerator(e::RationalExpression) = e.numerator
denominator(e::RationalExpression) = e.denominator

"""
    WeightedSum{T}

Weighted sum of expressions.
"""
mutable struct WeightedSum{T} <: CanonicalDecomposition{T}
    label::String
    weights::Dict{Atom{T}, Expression}

    WeightedSum(d::Dict{<:Atom{T}, <:Expression}) where T = new{T}( "", d )
end

WeightedSum{T}() where T = WeightedSum( Dict{Atom{T}, Expression}() )
WeightedSum(g::Generator) = WeightedSum( Dict(g) )
WeightedSum(p::Pair{<:Atom{T}, <:Expression}) where T = WeightedSum( Dict(p) )
WeightedSum(x::Atom{T}) where T = WeightedSum( x => one(ring(T)) )
WeightedSum{T}(e::Atom{T}) where T = WeightedSum(e)

function WeightedSum(t::NTuple{N, <:Atom{T}}) where {N, T}
    F = field(T)
    d = Dict{Atom{T}, Expression}()
    for x ∈ t
        if haskey(d, x)
            d[x] += one(F)
        else
            d[x] = one(F)
        end
    end
    WeightedSum( d )
end


"""
    dict(x)

Dictionary of a weighted sum that maps points to their corresponding weights.
"""
function dict(x::WeightedSum)
    T = space(x)
    F = field(T)
    Dict{Atom{T},Expression{F}}(x.weights)
end

function prune(x::WeightedSum)
    filter!( p -> !iszero(first(p)) && !iszero(last(p)), x.weights )
    if isempty(dict(x))
        zero(space(x))
    elseif isone(length(dict(x))) && isone(first(values(dict(x))))
        first(keys(dict(x)))
    else
        x
    end
end

"""
    applylinear(f, x)

Apply the linear function `f` to the weighted sum `x`.
"""
function applylinear(f::Function, x::WeightedSum)
    mapreduce( p -> last(p) * f(first(p)), +, dict(x); init=zero(space(x)) )
end


############################################################################################
# Canonical forms

canonicalform(::Type{T}) where {T<:VectorSpace} = WeightedSum{T}
canonicalform(::Type{T}) where {T<:LinearFunctional{<:VectorSpace}} = WeightedSum{T}
canonicalform(::Type{T}) where {T<:Field} = RationalExpression{T}
canonicalform(::Type{T}) where {T<:Ring} = Polynomial{T}

canonicalform(::Type{F}, ::Type{V}) where {F<:Field, V<:VectorSpace{F}} = WeightedSum{V}
canonicalform(::Type{F}, ::Type{V}) where {F<:Field, V<:LinearFunctional{<:VectorSpace{F}}} = WeightedSum{V}


############################################################################################
# Arguments

arg(x::Negation) = x.arg
arg(x::Inverse) = x.arg

args(x::Atom) = (x, )
args(x::Negation) = (arg(x), )
args(x::Inverse) = (arg(x), )
args(x::Sum) = x.args
args(x::Product) = x.args
args(x::Scaling) = (scalar(x), vector(x))
args(x::Sampling) = (func(x), input(x))
args(x::WeightedSum) = Tuple(keys(dict(x)))
args(x::Polynomial) = Tuple(keys(terms(x)))
args(x::RationalExpression) = ( args(numerator(x))..., args(denominator(x))... )
# args(x::Term) = x.args


############################################################################################
# Evaluate

hasvalue(x::Decomposition) = all( hasvalue(a) for a ∈ args(x) )

# function evaluate(x::LinearDecomposition{T}) where T
#     mapreduce( p->value(last(p))*value(first(p)), +, weights(x); init=Zero{T}() )
# end

evaluate(x::Negation) = -evaluate(arg(x))
evaluate(x::Inverse) = inv(evaluate(arg(x)))
evaluate(x::Sum) = mapreduce( evaluate, +, args(x) )
evaluate(x::Product) = mapreduce( evaluate, *, args(x) )
evaluate(x::Sampling) = evaluate(func(x))(evaluate(input(x)))
evaluate(x::Scaling) = evaluate(scalar(x)) * evaluate(vector(x))


############################################################################################
# Iteration

isempty(x::Decomposition) = all( isempty(a) for a ∈ args(x) )
isempty(e::Expression) = false

length(x::Decomposition) = length(args(x))
iterate(x::Decomposition) = iterate(x,1)
function iterate(x::Decomposition, state::Int)
    state > length(x) ? nothing : args(x)[state], state+1
end
