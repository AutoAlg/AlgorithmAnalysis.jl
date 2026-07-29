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

# transformations
include("transformations/convex.jl")
include("transformations/extract_lmi_coefficients.jl")
include("transformations/gram.jl")
include("transformations/propagate_constants.jl")
include("transformations/s_procedure.jl")
include("transformations/smooth_convex.jl")
include("transformations/smooth_strongly_convex.jl")

include("transformation.jl")
include("numeric.jl")
include("show.jl")

end
