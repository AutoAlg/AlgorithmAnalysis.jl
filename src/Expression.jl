struct Expression <: Node{Expression, Number}
  is_leaf::Bool
  children::Dict
  
  Expression(children::Dict) = new(false,children)
  
  Expression() = new(true,Dict())
  
  Expression(a::Number) = new(false,Dict(:constant => a))
  Expression(p1::Point,p2::Point) = new(false,Dict( (p1,p2) => 1))
end

children(e::Expression) = (e.is_leaf ? Dict(e => 1) : e.children)

"Add an expression and a number."
function Base.:+(e::Expression, a::T)::Expression where {T<:Number}
  children = e.children
  if haskey(children, :constant)
    children[:constant] += a
  else
    children[:constant] = a
  end
  Expression(children)
end

Base.:+(a::Number, e::Expression)::Expression = e+a
Base.:-(a::Number, e::Expression)::Expression = a-1*e
Base.:-(e::Expression, a::Number)::Expression = e-a

"Negate expression."
Base.:-(e::Expression)::Expression = -1*e

convert(::Type{Expression}, a::Number) = Expression(a)
convert(::Type{Expression}, p::Tuple{Point, Point}) = Expression(p[1],p[2])

# abstract type Expression end

# mutable struct LeafExpression <: Expression
#   value::Number

#   LeafExpression(val=NaN) = new(val)
# end

# mutable struct BranchExpression <: Expression
#   weight::Dict

#   BranchExpression(e::BranchExpression) = e
#   BranchExpression(e::LeafExpression) = new(Dict(e => 1))
#   BranchExpression(d::Dict) = new(d)
#   BranchExpression(p1::LeafPoint,p2::LeafPoint) = new(Dict( (p1,p2) => 1))
#   BranchExpression(a::Number) = new(Dict(a => 1))
# end

# "Convert LeafExpression to BranchExpression."
# convert(::Type{BranchExpression}, x::LeafExpression) = BranchExpression(x)

# "Add expressions."
# Base.:+(e1::Expression, e2::Expression)::Expression = BranchExpression(merge(BranchExpression(e1).weight,BranchExpression(e2).weight))

# "Add expression and number."
# Base.:+(e::Expression, a::Number)::Expression = BranchExpression(merge(BranchExpression(e).weight,BranchExpression(a).weight))

# "Subtract expressions."
# Base.:-(e1::Expression, e2::Expression)::Expression = BranchExpression(merge(BranchExpression(e1).weight,BranchExpression(-1*e2).weight))

# "Multiply expression by scalar."
# Base.:*(a::Number, e::Expression)::Expression = BranchExpression(Dict(keys(BranchExpression(e).weight) .=> map(x->a*x, values(BranchExpression(e).weight))))

# "Negate expression."
# Base.:-(e::Expression)::Expression = -1*e
