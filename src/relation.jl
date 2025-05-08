"""
    Relation{X,Y}

A relation is a subset of the product space X × Y.
"""
abstract type Relation{X,Y} end

# A set of relations.
const Relations = Set{Relation}

# Domain of a relation.
domain(::Relation{X,Y}) where {X,Y} = X

# Codomain of a relation.
codomain(::Relation{X,Y}) where {X,Y} = Y

# Check equality of two relations.
==(r1::Relation, r2::Relation) = isequal(pairs(r1),pairs(r2))

# Number of elements in a relation.
length(r::Relation) = length(pairs(r))

# Inputs of a relation.
inputs(r::Relation) = Set(first(p) for p ∈ pairs(r))

# Outputs of a relation.
outputs(r::Relation) = Set(last(p) for p ∈ pairs(r))

# Vectors of inputs and outputs of a relation.
function inputs_outputs(r::Relation)
    v = collect(pairs(r))
    [first(p) for p ∈ v], [last(p) for p ∈ v]
end

# Iterate over the pairs of a relation.
iterate(r::Relation) = iterate(r,1)
function iterate(r::Relation, state::Int)
    if state > length(r)
        nothing
    else
        collect(pairs(r))[state], state+1
    end
end

############################################################################################
# Multi-valued relation

"A relation is a subset of the Cartesian product of its domain `X` and codomain `Y`."
mutable struct MultiValuedRelation{X,Y}
  pairs::Set{Pair{X,Y}}

  # Construct an empty multi-valued relation.
  MultiValuedRelation{X,Y}() where {X,Y} = new(Set{Pair{X,Y}}())

  # Construct a multi-valued relation from a set of input-output pairs.
  MultiValuedRelation(s::Set{Pair{X,Y}}) where {X,Y} = new{X,Y}(s)
  MultiValuedRelation{X,Y}(s::Set{Pair{<:X,<:Y}}) where {X,Y} = new(s)
end

# Construct a multi-valued relation from a generator of pairs of points.
MultiValuedRelation(g::Generator) = MultiValuedRelation(Set(p for p ∈ g))

# Evaluate a multi-valued relation at a point (or set of points) in its domain. Returns a set of points in the codomain. To evaluate a relation `r` at a point `y` in its codomain, use `inv(r)(y)`.
(r::MultiValuedRelation{X,Y})(x::X) where {X,Y} = Set{Y}(last(p) for p ∈ pairs(r) if isequal(first(p),x))
(r::MultiValuedRelation{X,Y})(s::Set{X}) where {X,Y} = union([r(x) for x ∈ s]...)
(r::MultiValuedRelation{X,Y})(v::Vector{X}) where {X,Y} = r(Set(v))


############################################################################################
# Single-valued relation
# ============================================
# New TwoInput Relation Type
# ============================================

"""
    TwoInputSingleValuedRelation{P, Q, R}

A relation that maps a tuple `(p, q)`—with `p` of type `P` and `q` of type `Q`—to an output of type `R`.
"""
mutable struct TwoInputSingleValuedRelation{P, Q, R} <: Relation{Tuple{P, Q}, R}
    pairs::Dict{Tuple{P, Q}, R}

    TwoInputSingleValuedRelation{P, Q, R}() where {P, Q, R} = new(Dict{Tuple{P, Q}, R}())
    TwoInputSingleValuedRelation(d::Dict{Tuple{P, Q}, R}) where {P, Q, R} = new{P, Q, R}(d)
    TwoInputSingleValuedRelation{P, Q, R}(d::Dict{Tuple{P, Q}, R}) where {P, Q, R} = new(d)
end

mutable struct TwoInputTwoOutputRelation{P, Q} <: Relation{Tuple{P, Q}, Tuple{P, Q}}
    pairs::Dict{Tuple{P, Q}, Tuple{P, Q}}

    TwoInputTwoOutputRelation{P, Q}() where {P, Q} = new(Dict{Tuple{P, Q}, Tuple{P, Q}}())
    TwoInputTwoOutputRelation(d::Dict{Tuple{P, Q}, Tuple{P, Q}}) where {P, Q} = new{P, Q}(d)
    TwoInputTwoOutputRelation{P, Q}(d::Dict{Tuple{P, Q}, Tuple{P, Q}}) where {P, Q} = new(d)
end


"A single-valued relation (also known as a function) is a relation in which there is a unique element of the codomain associated with each element of the domain."
mutable struct SingleValuedRelation{X,Y} <: Relation{X,Y}
    pairs::Dict{X,Y}

    # Construct an empty relation.
    SingleValuedRelation{X,Y}() where {X,Y} = new(Dict{X,Y}())

    # Construct a relation from a set of input-output pairs.
    SingleValuedRelation(d::Dict{X,Y}) where {X,Y} = new{X,Y}(d)
    SingleValuedRelation{X,Y}(d::Dict{X,Y}) where {X,Y} = new(d)
end

# Construct a relation from a generator of pairs of points.
SingleValuedRelation(g::Generator) = SingleValuedRelation(Dict(p for p ∈ g))

# Evaluate a single-valued relation at a point in its domain.
# Returns a point in the codomain or `missing`.
#
# WARNING: must use Dict(pairs(r)) instead of r.pairs to avoid odd behavior after setting the value of the keys
(r::SingleValuedRelation{X,Y})(x::X) where {X,Y} = get(Dict(pairs(r)), x, missing)
(r::TwoInputSingleValuedRelation{P, Q, R})(x::Tuple{P, Q}) where {P, Q, R} = get(Dict(pairs(r)), x, missing)
(r::TwoInputTwoOutputRelation{P, Q})(x::Tuple{P, Q}) where {P, Q} = get(Dict(pairs(r)), x, missing)



# ## Testing Dual Input
# mutable struct DualInputRelation{X1, X2, Y} <: Relation{Tuple{X1, X2}, Y}
#     pairs::Dict{Tuple{X1, X2}, Y}

#     # Construct an empty dual-input relation.
#     DualInputRelation{X1, X2, Y}() where {X1, X2, Y} = new(Dict{Tuple{X1, X2}, Y}())

#     # Construct a dual-input relation from a dictionary of pairs.
#     DualInputRelation(d::Dict{Tuple{X1, X2}, Y}) where {X1, X2, Y} = new(d)
# end

# Construct a relation from a generator of pairs.
# DualInputRelation(g::Generator) = DualInputRelation(Dict(p for p ∈ g))

# # Evaluate a dual-input relation at a pair of inputs.
# # Returns a value in the codomain or `missing`.
# (r::DualInputRelation{X1, X2, Y})(x::Tuple{X1, X2}) where {X1, X2, Y} =
#     get(r.pairs, x, missing)


############################################################################################
# Constant relation

"A constant relation is a relation in which there is a unique element of the codomain that is associated with any element of the domain."
mutable struct ConstantRelation{X,Y} <: Relation{X,Y}
    inputs::Set{X}
    output::Y

    # Construct an empty relation.
    ConstantRelation{X,Y}() where {X,Y} = new(Dict{X,Y}())
    ConstantRelation{X,Y}(::Missing) where {X,Y} = new(Dict{X,Y}())

    # Construct a relation from a set of input-output pairs.
    ConstantRelation(x::Set{X}, y::Y) where {X,Y} = new{X,Y}(x, y)
    ConstantRelation{X,Y}(x::Set{<:X}, y::Y) where {X,Y} = new(x, y)
end

# Evaluate a constant relation at a point in its domain.
(r::ConstantRelation{X,Y})(::X) where {X,Y} = r.output


############################################################################################
# push!

push!(r::MultiValuedRelation{X,Y}, p::Pair{X,Y}) where {X,Y} = push!(r.pairs, p)
push!(r::SingleValuedRelation{X,Y}, p::Pair{X,Y}) where {X,Y} = push!(r.pairs, p)
push!(r::TwoInputSingleValuedRelation{P,Q,R}, p::Pair{Tuple{P,Q},R}) where {P,Q,R} = push!(r.pairs, p)
push!(r::TwoInputTwoOutputRelation{X,Y}, p::Pair{Tuple{X,Y}, Tuple{X,Y}}) where {X,Y} = push!(r.pairs, p)

push!(r::ConstantRelation{X,Y}, p::Pair{X,Y}) where {X,Y} = isequal(r.output, last(p)) ? r.output : error("Cannot add the point $(last(p)) to the constant relation $r")


############################################################################################
# pairs / samples

pairs(r::MultiValuedRelation) = r.pairs
pairs(r::SingleValuedRelation{X,Y}) where {X,Y} = Set{Pair{X,Y}}(first(p) => last(p) for p ∈ collect(r.pairs))
pairs(r::ConstantRelation{X,Y}) where {X,Y} = Set{Pair{X,Y}}(x => r.output for x ∈ r.inputs)

pairs(r::TwoInputSingleValuedRelation{P,Q,R}) where {P,Q,R} = Set{Pair{Tuple{P,Q},R}}(first(p) => last(p) for p ∈ collect(r.pairs))
pairs(r::TwoInputTwoOutputRelation{P,Q}) where {P,Q} = Set{Pair{Tuple{P,Q},Tuple{P,Q}}}(first(p) => last(p) for p ∈ collect(r.pairs))


samples(r::Relation) = pairs(r)


############################################################################################
# sample
# function  sample(r::SingleValuedRelation{[X1; X2], F}, ::Vector{InnerProductSpace{F}}, label::String = "")
#     y = codomain(r)(label)
#     push!(r, x => y)
#     y
# end
function sample(r::MultiValuedRelation{X,Y}, x::X, label::String = "") where {X,Y}
    y = codomain(r)(label)
    push!(r, x => y)
    y
end

function sample(r::SingleValuedRelation{X,Y}, x::X, label::String = "") where {X, Y}
    if x ∈ inputs(r)
        r(x)
    else
        y = codomain(r)(label)
        push!(r, x => y)
        y
    end
end

function sample(r::TwoInputSingleValuedRelation{P, Q, R}, x::Tuple{P,Q}, label::String = "") where {P, Q, R}
    if x ∈ inputs(r)
        r(x)
    else
        y = codomain(r)(label)
        push!(r, x => y)
        y
    end
end

function sample(r::TwoInputTwoOutputRelation{P, Q}, x::Tuple{P,Q}, label::String = "") where {P, Q}
    if x ∈ inputs(r)
        r(x)
    else
        y1, y2 = (codomain(r).parameters[1])(label), (codomain(r).parameters[2])(label)
        push!(r, x => (y1, y2))
        (y1, y2)
    end
end

sample(r::ConstantRelation{X,Y}, ::X) where {X,Y} = r.output


############################################################################################
# operations

# invert a relation
inv(r::Relation) = Relation(reverse(p) for p ∈ pairs(r))

# composition of two relations, unicode ∘ can be typed with \\circ[Tab]
function ∘(r1::Relation{Y,Z}, r2::Relation{X,Y}) where {X,Y,Z}
    r = Relation{X,Z}()
    r2inv = inv(r2)
    for y ∈ collect(inputs(r1) ∩ outputs(r2))
        for x ∈ collect(r2inv(y)), z ∈ collect(r1(y))
        push!(r, x => z)
        end
    end
    r
end

# sum of two relations
function +(r1::Relation{X,Y}, r2::Relation{X,Y}) where {X,Y}
    r = Relation{X,Y}()
    for x ∈ collect(inputs(r1) ∩ inputs(r2))
        for y1 ∈ collect(r1(x)), y2 ∈ collect(r2(x))
        push!(r, x => y1 + y2)
        end
    end
    r
end

# scale a relation
*(a::Number, r::Relation) = Relation( first(p) => a*last(p) for p ∈ r )

# negate a relation
-(r::Relation) = (-1)*r

# sum of a relation and an element of its codomain
+(r::Relation{X,Y}, y) where {X,Y} = Relation( first(p) => last(p) + y for p ∈ r )
+(y, r::Relation{X,Y}) where {X,Y} = r + y
