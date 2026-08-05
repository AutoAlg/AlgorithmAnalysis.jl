export →

"""
    Node{T} = SymbolicUtils.BasicSymbolic{T}

Abstract type of a symbolic expression with symtype `T`.
"""
const Node{T} = SymbolicUtils.BasicSymbolic{T}

abstract type NodeType end

abstract type Category end
abstract type LinearFunctional <: Category end
abstract type DifferentiableFunctional <: Category end
abstract type Gradient <: Category end
abstract type GramMatrix <: Category end

function constant end

include("alg.jl")
include("id.jl")
include("equality.jl")
include("linear_algebra.jl")
include("analysis.jl")
include("propositions.jl")
include("optimization.jl")

"""
    →(x,y)
    x → y

Construct a transition from node `x` to node `y`. This indicates that node `x` is a state of the algorithm whose value at the next iteration is `y`.
"""
const → = function (x, y)
    T1, T2 = typeof(x), typeof(y)
    if T1 ≠ T2
        error("Transitions must be between nodes of the same type, got $T1 and $T2")
    end
    Term{Transition{T1}}(→, [x, y])
end

leaf(T::DataType, sym::Symbol) = Sym{T}(sym)
branch(T::DataType, sym::Symbol, op, args) = (t=Term{T}(op, args); set_id(t, sym); t)
to_symbolic(x::Any) = convert(Node, x)
is_constant(x::Node) = iscall(x) && isequal(operation(x), constant)
