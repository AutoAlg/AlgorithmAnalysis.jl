abstract type Tensor end

function sum(t1::Tensor, t2::Tensor) end
function scale(a::Number, t::Tensor) end

"Add two tensors of the same dimension."
Base.:+(t1::Tensor, t2::Tensor) = sum(t1,t2)

"Subtract two tensors of the same dimension."
Base.:-(t1::Tensor, t2::Tensor) = t1 + (-t2)

"Scale a tensor by a scalar."
Base.:*(a::Number, t::Tensor) = scale(a,t)

"Divide a tensor by a scalar."
Base.:/(t::Tensor, a::Number) = (1/a)*t

"Negate a tensor."
Base.:-(t::Tensor) = -1*t


abstract type Node <: Tensor end

# Types inherited from Node must have fields is_leaf::Bool and children::Dict.

"Construct a leaf node."
(::Type{T})() where {T<:Node} = T(true,Dict())

"Construct a non-leaf node from its children."
(::Type{T})(children::Dict) where {T<:Node} = T(false,children)

"Get the children of a node."
children(n::Node) = (n.is_leaf ? Dict(n => 1) : n.children)

"Add two nodes of the same dimension."
sum(n1::T, n2::T) where {T<:Node} = T(mergewith(+,children(n1),children(n2)))

"Scale a tensor by a scalar."
scale(a::Number, n::T) where {T<:Node} = T(Dict(keys(children(n)) .=> map(x->a*x, values(children(n)))))


struct Scalar <: Node
  is_leaf::Bool
  children::Dict
  constant::Number
end

Scalar() = Scalar(true,Dict(),0)
Scalar(children::Dict) = Scalar(false,children,0)

"Add a scalar and a number."
Base.:+(a::Number, s::Scalar) = Scalar(false,s.children,s.constant+a)
Base.:+(s::Scalar, a::Number) = a+s

"Subtract a scalar and a number."
Base.:-(a::Number, s::Scalar) = a+(-s)
Base.:-(s::Scalar, a::Number) = s+(-a)

"Scale a scalar by a scalar."
scale(a::Number, s::Scalar) = Scalar(false,Dict(keys(children(s)) .=> map(x->a*x, values(children(s)))),a*s.constant)


struct InnerProductSpace <: Node
  is_leaf::Bool
  children::Dict
end

Base.:*(v1::InnerProductSpace, v2::InnerProductSpace) = Scalar(true,Dict( (v1,v2) => 1 ),0)

const FunctionValue = Scalar
const Point = InnerProductSpace



