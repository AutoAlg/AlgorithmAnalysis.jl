module AlgorithmAnalysis

# ------------------------------------------------------
# USING AND IMPORT
# ------------------------------------------------------

using SymbolicUtils, TermInterface
using SymbolicUtils: Sym, Term, FnType, Rewriters
using SymbolicUtils: symtype, @rule, iscall, issym, term
using SymbolicUtils: hasmetadata, setmetadata, getmetadata
using Printf

import Base: +, -, *, /, ^, ==, ≤, ≥, <=, >=, ∈
import Base: adjoint, show, isless, zero, one
import Base: iterate, getindex, size, iszero, isone, length
import LinearAlgebra as la
import LinearAlgebra: dot, ⋅

# ------------------------------------------------------
# INCLUDE
# ------------------------------------------------------

include("representation.jl")
include("utils.jl")
include("transformation.jl")
include("lyapunov.jl")
include("numeric.jl")
include("show.jl")

import Base: isequal, ==, hash

function Base.isequal(a::Node, b::Node)
    a === b && return true

    iscall(a) ≠ iscall(b) && return false

    if iscall(a) && iscall(b)
        return isequal(operation(a), operation(b)) && 
               isequal(arguments(a), arguments(b))
    else
        return symtype(a) == symtype(b) && id(a) == id(b)
    end
end

function Base.hash(a::Node, h::UInt)
    if iscall(a)
        h = hash(:iscall, h)
        h = hash(operation(a), h)
        return hash(arguments(a), h)
    else
        h = hash(:leaf, h)
        return hash(id(a), h)
    end
end

end
