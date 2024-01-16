# Override hash function because of
# https://github.com/JuliaLang/julia/issues/10267
import Base.hash

"Hash of an expression."
hash(e::Expression, h::UInt) = isvariable(e) ? objectid(e) : hash(value(e), hash(decomposition(e), h))
hash(x::LinearDecomposition, h::UInt) = hash(weights(x), h)
hash(x::AffineDecomposition, h::UInt) = hash(linear(x), hash(constant(x), h))
hash(c::Constraint, h::UInt) = hash(set(c), hash(expression(c), h))
hash(c::Satisfied, h::UInt) = objectid(c)
hash(c::Unsatisfied, h::UInt) = objectid(c)

function hash(a::AbstractArray{<:Expression}, h::UInt)
  h = hash(size(a), h)
  for x ∈ a
    h = hash(x, h)
  end
  h
end
