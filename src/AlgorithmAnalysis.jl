module AlgorithmAnalysis

# ------------------------------------------------------
# IMPORT
# ------------------------------------------------------

using SymbolicUtils, TermInterface
using SymbolicUtils: Sym, BasicSymbolic, Term, FnType, Rewriters, @rule, istree, term
using SymbolicUtils: hasmetadata, setmetadata, getmetadata

import Base: +, -, *, adjoint, show, ==, ≤, ≥, isless, <=, >=, zero, one, ∈, iterate
import LinearAlgebra: dot, ⋅

const symtype = SymbolicUtils.symtype

# ------------------------------------------------------
# INCLUDE
# ------------------------------------------------------

include("utils.jl")
include("representation.jl")
include("transformation.jl")
include("show.jl")

end
