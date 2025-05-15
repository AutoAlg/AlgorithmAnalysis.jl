module AlgorithmAnalysis

############################################################################################
# EXPORTS
############################################################################################

export Object, Space, Atom, Constraint, Constraints, ConstraintSet, Atoms, Spaces
export Operator, Operators, Property, Properties, Structures
export VectorSpace, NormedVectorSpace, InnerProductSpace, Field, field, Subset, Module
export R, Rⁿ, Rᵐ, Zero, One, 𝟎, 𝟏, ×, →, ⇒
export isimplementable, juliatype, algorithmtype
export @field, @vectorspace, @normedvectorspace, @innerproductspace, @algorithm

export label, label!, haslabel, getlabel, defaultlabel

export value!, clear, structures, field, vectorspace

export GroupOperator, addition, space, instance, Addition, Multiplication
export operators, oracles, properties, elements, evaluate, value, isclean, simplify!

export Associative, Commutative, Scaling

export CartesianProduct, CartesianPower, tree, spaces, children, getfields
export hasoperators, nodes, DifferentiableFunctional, 𝓕, 𝓛, Functional, LinearFunctional
export LinearMap, AbstractFunction, FunctionSpace, OperatorSpace

export UnaryOperator, BinaryOperator, NaryOperator, arity, neighbors
export issinglevalued, flatten, hasvalue, adjoint, objects, SetSpace, Subset, graph
export Powerset, base, @set, sample

# relation
export Relation, Relations, SingleValuedRelation, MultiValuedRelation, ConstantRelation
export domain, codomain, inputs, outputs, inputs_outputs, inputs_and_outputs, relation
export samples, canevaluate, isfunction

############################################################################################
# IMPORTS
############################################################################################

using JuMP

import Zeros: Zero, One, 𝟎, 𝟏
import AbstractTrees: children, print_tree

import Base: +, -, *, /, ^, ==, ≤, ≥, ∈, ∘, ∩
import Base: isempty, iszero, isone, isequal, hash
import Base: promote_rule, convert, show, zero, one, zeros, adjoint, hasfield
import Base: length, Generator, iterate, size, push!, inv, pairs, parent, map, issubset
import Base: numerator, denominator, empty!

include("abstract.jl")
# include("traits.jl")
include("object.jl")
include("relation.jl")
include("constraint.jl")
include("algebra.jl")
include("label.jl")
include("evaluate.jl")
include("hash.jl")
include("adjoint.jl")
include("space.jl")
include("show.jl")

end
