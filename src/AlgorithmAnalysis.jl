module AlgorithmAnalysis

# ------------------------------------------------------
# USING AND IMPORT
# ------------------------------------------------------

using SymbolicUtils, TermInterface
using SymbolicUtils: Sym, BasicSymbolic, Term, FnType, Rewriters
using SymbolicUtils: symtype, @rule, iscall, issym, term
using SymbolicUtils: hasmetadata, setmetadata, getmetadata
using Printf

import Base: +, -, *, /, adjoint, show, ==, ≤, ≥, isless, <=, >=, zero, one, ∈
import Base: iterate, getindex, size, iszero, isone
import LinearAlgebra as la
import LinearAlgebra: dot, ⋅

# ------------------------------------------------------
# INCLUDE
# ------------------------------------------------------

include("utils.jl")
include("representation.jl")
include("transformation.jl")
include("numeric.jl")
include("show.jl")

end
