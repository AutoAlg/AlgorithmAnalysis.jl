module AlgorithmAnalysis

#########################################################
# IMPORT
#########################################################

import JuMP
import MathOptInterface as MOI

import Base: +, -, *, /, ^, ==, ∈, ∘, ∩, ⊆, ≤, ≥, <=, >=
import Base: isempty, iszero, isequal, get, min, max
import Base: promote_rule, convert, show, zero, zeros, one, adjoint
import Base: length, Generator, iterate, size, push!, inv, pairs, getindex

using Base.ScopedValues


#########################################################
# INCLUDE
#########################################################

include("abstract.jl")
include("set.jl")
include("traits/numeric.jl")
include("traits/subset.jl")
include("traits/product.jl")
include("traits/graph.jl")
include("traits/equality.jl")
include("traits/subdifferential.jl")
include("traits/magma.jl")
include("traits/monoid.jl")
include("traits/group.jl")
include("traits/ring.jl")
include("traits/inner-product-space.jl")
include("traits/binder.jl")
include("traits/matrix.jl")
include("traits/psd.jl")
include("traits/order.jl")
include("traits/logic.jl")
include("dispatch.jl")
include("transformations.jl")
include("analysis.jl")
include("utils.jl")

end
