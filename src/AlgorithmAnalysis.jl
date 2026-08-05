module AlgorithmAnalysis

# ------------------------------------------------------
# USING AND IMPORT
# ------------------------------------------------------

using SymbolicUtils, TermInterface, Printf
using SymbolicUtils: Sym, Term, FnType, Rewriters
using SymbolicUtils: symtype, @rule, iscall, issym, term
using SymbolicUtils: hasmetadata, setmetadata, getmetadata

import Base: +, -, *, /, ^, ==, ≤, ≥, <=, >=, ∈
import Base: isequal, hash, adjoint, isless, zero, one
import Base: iterate, getindex, size, iszero, isone, length
import LinearAlgebra as la
import LinearAlgebra: dot, ⋅

# ------------------------------------------------------
# INCLUDE
# ------------------------------------------------------

include("nodes/_main.jl")
include("utils/_main.jl")
include("transformations/_main.jl")
include("numerics/_main.jl")
include("show.jl")

end
