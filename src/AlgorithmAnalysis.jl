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

end
