module AlgorithmAnalysis

########################################################
# IMPORT
########################################################

using SymbolicUtils, TermInterface
using SymbolicUtils: Sym, BasicSymbolic, Term, FnType, Rewriters, @rule, istree, term

import Base: +, -, *, adjoint, show, ==, ≤, ≥, isless, <=, >=, zero, one, ∈, iterate
import LinearAlgebra: dot, ⋅

const symtype = SymbolicUtils.symtype

# import Base: +, -, *, /, ^, ==, ∈, ∘, ∩, ⊆, ≤, ≥, <=, >=
# import Base: isempty, iszero, isequal, get, min, max
# import Base: promote_rule, convert, show, zero, zeros, one, adjoint
# import Base: length, Generator, iterate, size, push!, inv, pairs, getindex

# using Base.ScopedValues
# using Bijections
# import LinearAlgebra as la


########################################################
# INCLUDE
########################################################

include("utils.jl")
include("representation.jl")
include("transformation.jl")
include("show.jl")

end
