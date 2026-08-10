module AlgorithmAnalysis

# ------------------------------------------------------
# IMPORT
# ------------------------------------------------------

import Base: +, -, *, /
import LinearAlgebra as la
import LinearAlgebra: tr, ⋅
import TermInterface: maketerm, metadata
import SymbolicUtils
import SymbolicUtils: Term, FnType
import SymbolicUtils: symtype, issym, @rule
import SymbolicUtils: iscall, operation, arguments
import JuMP, Hypatia, Clarabel
import MathOptInterface as MOI

# ------------------------------------------------------
# INCLUDE
# ------------------------------------------------------

include("nodes/_main.jl")
include("utils/_main.jl")
include("transformations/_main.jl")
include("numerics/_main.jl")
include("show.jl")

end
