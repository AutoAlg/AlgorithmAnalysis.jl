abstract type Point end

struct LeafPoint <: LeafNode end

mutable struct InnerPoint <: InnerNode
  children::Dict{LeafPoint, Number}

  InnerPoint(children::Dict{LeafPoint, Number}) = new(children)
  InnerPoint(p::LeafPoint) = new(Dict(p => 1))
end

"Convert Leaf to Inner."
convert(::Type{InnerPoint}, children::Dict{LeafPoint, Number}) = InnerNode(children)

children(n::InnerPoint) = n.children
children(n::LeafPoint) = Dict(n => 1)

# "Inner product of points."
# Base.:*(p1::Point, p2::Point)::Expression = BranchExpression(p1,p2)

# "Squared norm of point."
# squared_norm(p::Point)::Expression = p*p





# abstract type Point end

# mutable struct LeafPoint <: Point
#   value::Number

#   LeafPoint(val=NaN) = new(val)
# end

# mutable struct BranchPoint <: Point
#   weight::Dict

#   BranchPoint(p::BranchPoint) = p
#   BranchPoint(p::LeafPoint) = new(Dict(p => 1))
#   BranchPoint(d::Dict) = new(d)
# end

# "Convert LeafPoint to BranchPoint."
# convert(::Type{BranchPoint}, x::LeafPoint) = BranchPoint(x)

# "Add points."
# Base.:+(p1::Point, p2::Point)::Point = BranchPoint(merge(BranchPoint(p1).weight,BranchPoint(p2).weight))

# "Subtract points."
# Base.:-(p1::Point, p2::Point)::Point = p1 + (-p2)

# "Multiply point by scalar."
# Base.:*(a::Number, p::Point)::Point = BranchPoint(Dict(keys(BranchPoint(p).weight) .=> map(x->a*x, values(BranchPoint(p).weight))))

# "Negate point."
# Base.:-(p::Point)::Point = -1*p

# "Inner product of points."
# Base.:*(p1::Point, p2::Point)::Expression = BranchExpression(p1,p2)

# "Squared norm of point."
# squared_norm(p::Point)::Expression = p*p
