############################################################################################
# DECOMPOSITION

"""
    LinearDecomposition

Decomposition of an expression as a linear function of other expressions.

# Fields
    weights::Dict{T, Number}

# Constructors
    LinearDecomposition{T}()
    LinearDecomposition{T}(x)
    LinearDecomposition{T}(weights)
"""
mutable struct LinearDecomposition{T<:VectorOrWrapper} <: AbstractLinearDecomposition{T}
    label::String
    weights::Dict{T,Number}

    LinearDecomposition{T}() where {T} = new{T}("",Dict{T,Number}())

    LinearDecomposition{T}(x::T) where {T} = new{T}("",Dict{T,Number}(x=>1))

    function LinearDecomposition{T}(weights::Dict{<:T,<:Number}) where {T}
        new{T}( "", Dict{T,Number}(weights) )
    end
end

label(x::LinearDecomposition) = x.label
label!(x::LinearDecomposition, label::String) = (x.label=label; nothing)

"Weights of a linear decomposition."
weights(x::LinearDecomposition) = x.weights

"Check if a decomposition is empty."
isempty(x::LinearDecomposition) = isempty(weights(x))

prune(d::Dict) = filter( p -> !iszero(first(p)) && !iszero(last(p)), d )

prune(x::LinearDecomposition{T}) where {T} = isempty(weights(x)) ? T(Zero()) : x

value(x::LinearDecomposition) = mapreduce( p->last(p)*value(first(p)), +, weights(x); init=Zero() )

variables(x::LinearDecomposition) = Variables( v for v ∈ keys(weights(x)) if !hasvalue(v) )

function constant(x::LinearDecomposition)
    y = Zero()
    for (key,val) ∈ weights(x)
        if hasvalue(key)
            y += val * value(key)
        end
    end
    y
end

zero(::LinearDecomposition) = Zero()

############################################################################################
# CONVERSION AND PROMOTION

promote_rule(::Type{LinearDecomposition{T}}, ::Type{T}) where {T} = LinearDecomposition{T}

convert(::Type{LinearDecomposition{T}}, x::T) where {T} = LinearDecomposition{T}(x)

# +(x::Decomposition, y::Decomposition) = +(promote(x,y)...)
# +(x::Decomposition, y) = +(promote(x,y)...)
# +(x, y::Decomposition) = +(promote(x,y)...)
# -(x::Decomposition, y::Decomposition) = +(promote(x,y)...)
# -(x::Decomposition, y) = +(promote(x,y)...)
# -(x, y::Decomposition) = +(promote(x,y)...)
+(x::VectorWrapperDecomposition, y::VectorWrapperDecomposition) = +(promote(x,y)...)
-(x::VectorWrapperDecomposition, y::VectorWrapperDecomposition) = -(promote(x,y)...)
# *(x::VectorWrapperDecomposition, y::VectorWrapperDecomposition) = *(promote(x,y)...)
# /(x::VectorWrapperDecomposition, y::VectorWrapperDecomposition) = /(promote(x,y)...)


############################################################################################
# ALGEBRA

# Summation
function +(x::LinearDecomposition{T}, y::LinearDecomposition{T}) where {T}
    prune( LinearDecomposition{T}( prune( mergewith( +, weights(x), weights(y) ) ) ) )
end
# function +(x::LinearDecomposition{T}, y::T) where {T<:VectorOrWrapper}
#     x + LinearDecomposition{T}(Dict(y=>1))
# end
# +(x::T, y::LinearDecomposition{T}) where {T<:VectorOrWrapper} = y + x
+(x::T, y::T) where {T<:VectorOrWrapper} = LinearDecomposition{T}(Dict(x=>1, y=>1))

function +(x::LinearDecomposition, a::Number)
    iszero(a) ? x : error("Cannot add linear decompositions and numbers")
end
+(a::Number, x::LinearDecomposition) = x + a


function +(x::T, a::Number) where {T<:AbstractVectorSpace}
    if iszero(a)
        x
    else
        error("Cannot add vectors and numbers")
    end
end
+(a::Number, x::AbstractVectorSpace) = x + a


# Subtraction
-(x::VectorExpression, y::VectorExpression) = x + (-y)

-(x::VectorExpression, a::Number) = x + (-a)
-(a::Number, x::VectorExpression) = -x + a

# Multiplication
function *(x::LinearDecomposition, y::LinearDecomposition)
    f = p -> (first(first(p))*first(last(p)) => last(first(p))*last(last(p)))
    op = (p1,p2)->mergewith(+, Dict(p1), Dict(p2))
    itrs = Iterators.product( weights(x), weights(y) )
    d = mapreduce( f, op, itrs )
    LinearDecomposition{keytype(d)}(d)
end

*(x::LinearDecomposition, y::VectorOrWrapper) = x * LinearDecomposition{typeof(y)}(Dict(y=>1))
*(x::VectorOrWrapper, y::LinearDecomposition) = LinearDecomposition{typeof(x)}(Dict(x=>1)) * y

# Scaling
*(a::Number, x::T) where {T<:VectorOrWrapper} = LinearDecomposition{T}(Dict(x=>a))

function *(a::Number, x::LinearDecomposition{T}) where {T}
    new_weights = Dict{T,Number}(keys(weights(x)) .=> map(x->a*x, values(weights(x))))
    LinearDecomposition{T}( new_weights )
end

*(x::VectorExpression, a::Number) = a*x
/(x::VectorExpression, a::Number) = (1/a)*x

# Negation
-(x::VectorExpression) = -1*x


# Squared norm of a vector in a normed vector space
function ^(v::Union{NormedVectorSpace,Wrapper,Decomposition}, n::Int)
    if n == 2
        squarednorm(v)
    else
        error("Can only take inner product of vectors.")
    end
end

squarednorm(v::Union{InnerProductSpace,Wrapper{<:InnerProductSpace},Decomposition{<:InnerProductSpace}}) = v'*v

"""
    ⊗(x,x)

Outer product (Gram matrix) of two vectors whose elements are themselves vectors in the same inner product space.

# Examples
```julia-repl
julia> x = [ Rⁿ(); Rⁿ(); Rⁿ() ]
julia> y = [ Rⁿ(); Rⁿ() ]
julia> G = x ⊗ y
```
"""
function ⊗(x1::Vector{V}, x2::Vector{V}) where {F<:Field, V<:InnerProductSpace{F}}
    F[ x'*y for x ∈ x1, y ∈ x2 ]
end

+(::Missing, ::Any) = missing
+(::Any, ::Missing) = missing
-(::Missing, ::Any) = missing
-(::Any, ::Missing) = missing
*(::Missing, ::Any) = missing
*(::Any, ::Missing) = missing
/(::Missing, ::Any) = missing
/(::Any, ::Missing) = missing


+(x::AbstractArray, y::Number) = iszero(y) ? x : error("Addition of array and number is ill-defined")
+(x::Number, y::AbstractArray) = y + x
-(x::AbstractArray, y::Number) = x + (-y)
-(x::Number, y::AbstractArray) = x + (-y)
