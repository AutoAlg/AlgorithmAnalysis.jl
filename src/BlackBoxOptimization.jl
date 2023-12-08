# cd("C:\\Users\\vanscob\\.julia\\dev\\BlackBoxOptimization\\")
# ] activate .
# using Revise
# using BlackBoxOptimization

# ] test BlackBoxOptimization

module BlackBoxOptimizationP

const m = BlackBoxOptimization

export BlackBoxOptimization, m, maximize

import Convex, SCS
import Base.zero

"An abstract expression that evaluates to a value of type `T`."
abstract type Expression end

"An abstract constraint on expressions that evaluates to a value of type `T`."
abstract type Constraint end

include("relation.jl")    # no dependencies

# include("ast.jl")         # requires Oracle and Constraint
include("oracle.jl")      # requires relation.jl and Expression
include("expression.jl")  

include("constraint.jl")  # requires Expression
include("solve.jl")

include("interpolation.jl")

###############################################################################
# Conversion and promotion

# import Base.promote_rule, Base.convert

# "Promote a subtype of `Value` to a subtype of `Expression`."
# promote_rule(::Type{T}, ::Type{<:Value}) where {T<:Expression} = T

# "Promote `Number` and `Scalar` to `Scalar`."
# promote_rule(::Type{T}, ::Type{<:Number}) where {T<:Expression{Scalar}} = T

# "Promote `AbstractArray` and `Point` to `Point`."
# promote_rule(::Type{T}, ::Type{<:AbstractArray}) where {T<:Expression{Point}} = T

# "Convert a subtype of `Value` to a subtype of `Expression`."
# convert(::Type{T1}, x::T2) where {T1<:Expression,T2<:Value} = T1(x)

# "Convert `Number` to `Constant{Scalar}`."
# convert(::Type{<:Expression{Scalar}}, x::T) where {T<:Number} = Constant(Scalar(x))

# "Convert `AbstractArray` to `Constant{Point}`."
# convert(::Type{<:Constant{Point}}, x::T) where {T<:AbstractArray} = Constant(Point(x))


###############################################################################
# Default tuple constructors

# Tuple{X,Y}() where {X,Y} = (X(),Y())
# Tuple{X,Y,Z}() where {X,Y,Z} = (X(),Y(),Z())
# Tuple{Expression{Scalar}, Expression{Point}}() = ( Variable{Scalar}(), Variable{Point}() )
Tuple{Scalar, Point}() = ( Scalar(), Point() )


###############################################################################
# Hash

# Override hash function because of
# https://github.com/JuliaLang/julia/issues/10267
import Base.hash

const hash_seed = UInt === UInt64 ? 0x7f53e68ceb575e76 : 0xeb575e7

function hash(a::Array{Expression}, h::UInt)
    h += hash_seed
    h += hash(size(a))
    for x in a
        h = hash(x, h)
    end
    return h
end

"Recursively compute the hash of an expression based on the hashes of its leaf nodes (variables and constants)."
function hash(x::Expression, h::UInt)
  if isleaf(x)
    objectid(x)
  else
    hash(x.children, h)
  end
end

hash(c::Constraint, h::UInt) = hash(c.x, h)

end
