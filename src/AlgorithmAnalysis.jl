module AlgorithmAnalysis

# ------------------------------------------------------
# USING AND IMPORT
# ------------------------------------------------------

using SymbolicUtils, TermInterface
using SymbolicUtils: Sym, BasicSymbolic, Term, FnType, Rewriters
using SymbolicUtils: symtype, @rule, istree, term
using SymbolicUtils: hasmetadata, setmetadata, getmetadata
using SymbolicUtils: issym, nameof

import Base: +, -, *, adjoint, show, ==, ≤, ≥, isless, <=, >=, zero, one, ∈
import Base: iterate, getindex
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
