abstract type Expression end

mutable struct LeafExpression <: Expression
  value::Number

  LeafExpression(val=NaN) = new(val)
end

mutable struct BranchExpression <: Expression
  weight::Dict

  BranchExpression(e::BranchExpression) = e
  BranchExpression(e::LeafExpression) = new(Dict(e => 1))
  BranchExpression(d::Dict) = new(d)
  BranchExpression(p1::LeafPoint,p2::LeafPoint) = new(Dict( (p1,p2) => 1))
  BranchExpression(a::Number) = new(Dict(a => 1))
end

"Convert LeafExpression to BranchExpression."
convert(::Type{BranchExpression}, x::LeafExpression) = BranchExpression(x)

"Add expressions."
Base.:+(e1::Expression, e2::Expression)::Expression = BranchExpression(merge(BranchExpression(e1).weight,BranchExpression(e2).weight))

"Add expression and number."
Base.:+(e::Expression, a::Number)::Expression = BranchExpression(merge(BranchExpression(e).weight,BranchExpression(a).weight))

"Subtract expressions."
Base.:-(e1::Expression, e2::Expression)::Expression = BranchExpression(merge(BranchExpression(e1).weight,BranchExpression(-1*e2).weight))

"Multiply expression by scalar."
Base.:*(a::Number, e::Expression)::Expression = BranchExpression(Dict(keys(BranchExpression(e).weight) .=> map(x->a*x, values(BranchExpression(e).weight))))

"Negate expression."
Base.:-(e::Expression)::Expression = -1*e
