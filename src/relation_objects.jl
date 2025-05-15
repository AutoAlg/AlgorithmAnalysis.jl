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
mutable struct MultiValuedRelation{X,Y} <: Relation{X,Y}
  pairs::Set{Pair{Object{<:X},Object{<:Y}}}

  # Construct an empty multi-valued relation.
  MultiValuedRelation{X,Y}() where {X,Y} = new(Set{Pair{Object{<:X},Object{<:Y}}}())

  # Construct a multi-valued relation from a set of input-output pairs.
  MultiValuedRelation(s::Set{Pair{Object{X},Object{Y}}}) where {X,Y} = new{X,Y}(s)
  MultiValuedRelation{X,Y}(s::Set{Pair{Object{<:X},Object{<:Y}}}) where {X,Y} = new(s)
  MultiValuedRelation{X,Y}(s::Set{Pair{<:Object{X},<:Object{Y}}}) where {X,Y} = new(s)
end

# Construct a multi-valued relation from a generator of pairs of points.
MultiValuedRelation(g::Generator) = MultiValuedRelation(Set(p for p ∈ g))
MultiValuedRelation{X,Y}(g::Generator) where {X,Y} = MultiValuedRelation{X,Y}(Set(p for p ∈ g))

# Evaluate a multi-valued relation at a point (or set of points) in its domain. Returns a set of points in the codomain. To evaluate a relation `r` at a point `y` in its codomain, use `inv(r)(y)`.
(r::MultiValuedRelation{X,Y})(x::Object{X}) where {X,Y} = Set{Object{Y}}(last(p) for p ∈ pairs(r) if isequal(first(p),x))
(r::MultiValuedRelation{X,Y})(s::Set{Object{X}}) where {X,Y} = union([r(x) for x ∈ s]...)
(r::MultiValuedRelation{X,Y})(v::Vector{Object{X}}) where {X,Y} = r(Set(v))


############################################################################################
# Single-valued relation

"A single-valued relation (also known as a function) is a relation in which there is a unique element of the codomain associated with each element of the domain."
mutable struct SingleValuedRelation{X,Y} <: Relation{X,Y}
    pairs::Dict{Object{<:X},Object{<:Y}}

    # Construct an empty relation.
    SingleValuedRelation{X,Y}() where {X,Y} = new(Dict{Object{<:X},Object{<:Y}}())

    # Construct a relation from a set of input-output pairs.
    SingleValuedRelation(d::Dict{<:Object{<:X},<:Object{<:Y}}) where {X,Y} = new{X,Y}(d)
    SingleValuedRelation{X,Y}(d::Dict) where {X,Y} = new(d)
end

# Construct a relation from a generator of pairs of points.
SingleValuedRelation(g::Generator) = SingleValuedRelation(Dict(p for p ∈ g))
SingleValuedRelation{X,Y}(g::Generator) where {X,Y} = SingleValuedRelation{X,Y}(Dict(p for p ∈ g))

# Evaluate a single-valued relation at a point in its domain.
# Returns a point in the codomain or `missing`.
#
# WARNING: must use Dict(pairs(r)) instead of r.pairs to avoid odd behavior after setting the value of the keys # get(Dict(pairs(r)), convert(Object{X}, x), missing)
(r::SingleValuedRelation{X,Y})(x) where {X,Y} = get(r.pairs, x, missing)
    # get(Dict(pairs(r)), x, missing)



############################################################################################
# Constant relation

"A constant relation is a relation in which there is a unique element of the codomain that is associated with any element of the domain."
mutable struct ConstantRelation{X,Y} <: Relation{X,Y}
    inputs::Set{X}
    output::Y

    # Construct an empty relation.
    ConstantRelation{X,Y}() where {X,Y} = new(Set{X}(), Y())
    ConstantRelation{X,Y}(::Missing) where {X,Y} = new(Set{X}(), Y())
    ConstantRelation{X,Y}(y::Y) where {X,Y} = new(Set{X}(), y)

    # Construct a relation from a set of input-output pairs.
    ConstantRelation(x::Set{X}, y::Y) where {X,Y} = new{X,Y}(x, y)
    ConstantRelation{X,Y}(x::Set{<:X}, y::Y) where {X,Y} = new(x, y)
end

# Evaluate a constant relation at a point in its domain.
(r::ConstantRelation{X,Y})(::X) where {X,Y} = r.output


############################################################################################
# Empty relation

struct EmptyRelation{X,Y} <: Relation{X,Y}
    EmptyRelation() = new{Any,Any}()
end

(::EmptyRelation)(::Any) = error("Cannot sample the empty relation")


empty!(::EmptyRelation) = nothing
empty!(r::MultiValuedRelation) = empty!(r.pairs)
empty!(r::SingleValuedRelation) = empty!(r.pairs)

############################################################################################
# push!

push!(r::MultiValuedRelation{X,Y}, p::Pair{<:X,<:Y}) where {X,Y} = push!(r.pairs, p)
push!(r::SingleValuedRelation{X,Y}, p::Pair{<:Object{<:X},<:Object{<:Y}}) where {X,Y} = push!(r.pairs, p)
push!(r::ConstantRelation{X,Y}, p::Pair{<:X,<:Y}) where {X,Y} = isequal(r.output, last(p)) ? r.output : error("Cannot add the point $(last(p)) to the constant relation $r")


############################################################################################
# pairs / samples

pairs(::EmptyRelation) = Set()
pairs(r::MultiValuedRelation) = r.pairs
pairs(r::ConstantRelation{X,Y}) where {X,Y} = Set{Pair{X,Y}}(x => r.output for x ∈ r.inputs)

# function pairs(r::SingleValuedRelation{X,Y}) where {X,Y}
#     Set{Pair{<:Object{<:X},<:Object{<:Y}}}(first(p) => last(p) for p ∈ collect(r.pairs))
# end
pairs(r::SingleValuedRelation) = Set(r.pairs)

samples(r::Relation) = pairs(r)


############################################################################################
# sample

function sample(r::MultiValuedRelation{<:X,Y}, x::Object{<:X}, label::String="") where {X,Y}
    y = space(Y)()
    label!(y, label)
    push!(r, x => y)
    y
end

function sample(r::SingleValuedRelation{X,Y}, x::Object{<:X}, label::String="") where {X,Y}
    if x ∈ inputs(r)
        r(x)
    else
        y = Y()
        label!(y, label)
        push!(r, x => y)
        y
    end
end

sample(r::ConstantRelation{<:X,Y}, ::X) where {X,Y} = r.output


############################################################################################
# operations

# invert a relation  # Base.typename(T).wrapper
# inv(r::T) where {X,Y,T<:Relation{X,Y}} = MultiValuedRelation{Y,X}(reverse(p) for p ∈ pairs(r))
inv(r::Relation{X,Y}) where {X,Y} = Dict(last(p) => first(p) for p ∈ pairs(r))

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
