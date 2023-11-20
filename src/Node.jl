const Node = DAG

abstract type InnerNode <: Node end
abstract type LeafNode <: Node end

function children end

NodeType(::Type{<:InnerNode}) = InnerNode()
NodeType(::Type{<:LeafNode}) = LeafNode()
children(n::InnerNode) = n.children

"Convert Leaf to Inner."
convert(::Type{InnerNode}, n::LeafNode) = InnerNode(n)

"Add nodes."
Base.:+(n1::T1, n2::T2) where {T1<:Node,T2<:Node} = InnerNode(merge(children(n1),children(n2)))  # sum(n1,n2)

"Subtract nodes."
Base.:-(n1::Node, n2::Node)::Node = n1 + (-n2)

"Multiply node by scalar."
Base.:*(a::Number, n::T) where {T<:Node} = T(Dict(keys(children(n)) .=> map(x->a*x, values(children(n)))))  # scale(a,n)

"Negate node."
Base.:-(n::Node)::Node = -1*n


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

