"A node in an abstract linear computational graph."
abstract type Node{V,F} <: Vec{V,F} end

###############################################################################
# Each `Node` must provide a specialized method for the following functions.

"Get the children of a node, which is a dictionary that maps vectors to scalars."
function children(n::Node) end

"Construct a node from its children."
function Node{V,F}(children::Dict{V,F}) where {V,F} end

###############################################################################
# Derived node functions.

"Add nodes."
sum(n1::Node{V1,F1}, n2::Node{V2,F2}) where {V,F,V1<:V,V2<:V,F1<:F,F2<:F} = V1(mergewith(+,children(n1),children(n2)))

"Multiply node by scalar."
scale(a::F1, n::Node{V,F2}) where {V,F,F1<:F,F2<:F} = V(Dict(keys(children(n)) .=> map(x->a*x, values(children(n)))))



# NodeType(::Type{<:InnerNode}) = InnerNode()
# NodeType(::Type{<:LeafNode}) = LeafNode()
# children(n::InnerNode) = n.children

# "Convert Leaf to Inner."
# convert(::Type{InnerNode}, n::LeafNode) = InnerNode(n)


# abstract type Node
#   # is_leaf::Bool
#   # weight::Dict

#   # Node(weight::Dict) = new(false,weight)
  
#   # function Node()
#   #   n = new(true,Dict())
#   #   n.weight[n] = 1
#   #   return n
#   # end
# end

# "Add nodes."
# Base.:+(n1::Node, n2::Node)::Node = sum(n1,n2) # Node(merge(n1.weight,n2.weight))

# "Subtract nodes."
# Base.:-(n1::Node, n2::Node)::Node = n1 + (-n2)

# "Multiply node by scalar."
# Base.:*(a::Number, n::Node)::Node = scale(a,n) # Node(Dict(keys(n.weight) .=> map(x->a*x, values(n.weight))))

# "Negate node."
# Base.:-(n::Node)::Node = -1*n


# abstract type Vec end

# @class mutable struct LeafVec <: Vec
#   value::Number

#   LeafVec(val=NaN) = new(val)
# end

# @class mutable struct BranchVec <: Vec
#   weight::Dict

#   BranchVec(p::BranchVec) = p
#   BranchVec(p::LeafVec) = new(Dict(p => 1))
#   BranchVec(d::Dict) = new(d)
# end

# "Convert LeafVec to BranchVec."
# convert(::Type{BranchVec}, x::LeafVec) = BranchVec(x)

# "Add vecs."
# Base.:+(p1::Vec, p2::Vec)::Vec = BranchVec(merge(BranchVec(p1).weight,BranchVec(p2).weight))

# "Subtract vecs."
# Base.:-(p1::Vec, p2::Vec)::Vec = p1 + (-p2)

# "Multiply vec by scalar."
# Base.:*(a::Number, p::Vec)::Vec = BranchVec(Dict(keys(BranchVec(p).weight) .=> map(x->a*x, values(BranchVec(p).weight))))

# "Negate vec."
# Base.:-(p::Vec)::Vec = -1*p

# "Squared norm of vec."
# squared_norm(p::Vec)::Expression = p*p

