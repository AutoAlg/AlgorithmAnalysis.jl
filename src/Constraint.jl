export Constraint, Cone, PositiveSemidefinite, PositiveOrthant, EqualityConstraint, ConeConstraint

import Base.==, Base.<=, Base.>=, Base.<, Base.>, Base.in, Base.∩, Base.isequal, Base.∈, Base.:≤, Base.:≥

# abstract type Constraint end

"Add a constraint to all variables in an expression."
function add_constraint!(x::Expression, c::Constraint)
  vars = variables(x)
  for v ∈ vars
    if isa(v, Tuple)
      for w ∈ v
        push!(w.constraints, c)
      end
    else
      push!(v.constraints, c)
    end
  end
  nothing
end

###############################################################################
# Each `Constraint` must specialize the following methods.

function isequal(c1::Constraint, c2::Constraint)::Bool end

###############################################################################
# ConeConstraint

abstract type Cone end
struct PositiveSemidefinite <: Cone end
struct PositiveOrthant <: Cone end

struct ConeConstraint{K<:Cone} <: Constraint
  x::Expression
  
  function ConeConstraint{K}(x::Expression) where {K<:Cone}
    this = new(x)
    add_constraint!(x, this)
    return this
  end
end

struct EqualityConstraint <: Constraint
  x::Expression
  
  function EqualityConstraint(x::Expression)
    this = new(x)
    add_constraint!(x, this)
    return this
  end
end

isequal(lhs::EqualityConstraint, rhs::EqualityConstraint) = isequal(lhs.x,rhs.x)
isequal(lhs::ConeConstraint{K}, rhs::ConeConstraint{K}) where {K<:Cone} = isequal(lhs.x,rhs.x)

==(lhs::Expression, rhs::Expression) = EqualityConstraint(lhs-rhs)
==(lhs::Expression, rhs) = EqualityConstraint(lhs-rhs)
==(lhs, rhs::Expression) = EqualityConstraint(lhs-rhs)

≤(lhs::Expression, rhs::Expression) = ConeConstraint{PositiveOrthant}(rhs-lhs)
≤(lhs::Expression, rhs) = ConeConstraint{PositiveOrthant}(rhs-lhs)
≤(lhs, rhs::Expression) = ConeConstraint{PositiveOrthant}(rhs-lhs)

≥(lhs::Expression, rhs::Expression) = ConeConstraint{PositiveOrthant}(lhs-rhs)
≥(lhs::Expression, rhs) = ConeConstraint{PositiveOrthant}(lhs-rhs)
≥(lhs, rhs::Expression) = ConeConstraint{PositiveOrthant}(lhs-rhs)

⪯(lhs::Expression, rhs::Expression) = ConeConstraint{PositiveSemidefinite}(rhs-lhs)
⪯(lhs::Expression, rhs) = ConeConstraint{PositiveSemidefinite}(rhs-lhs)
⪯(lhs, rhs::Expression) = ConeConstraint{PositiveSemidefinite}(rhs-lhs)

⪰(lhs::Expression, rhs::Expression) = ConeConstraint{PositiveSemidefinite}(lhs-rhs)
⪰(lhs::Expression, rhs) = ConeConstraint{PositiveSemidefinite}(lhs-rhs)
⪰(lhs, rhs::Expression) = ConeConstraint{PositiveSemidefinite}(lhs-rhs)

in(x::Expression, ::K) where {K<:Cone} = ConeConstraint{K}(x)

# "Add constraints."
∩(c1::Array{<:Constraint},c2::Array{<:Constraint}) = append!(append!(Constraint[], c1), c2)
∩(c1::Constraint, c2::Constraint) = [c1] ∩ [c2]
∩(c1::Constraint, c2::Array{<:Constraint}) = [c1] ∩ c2
∩(c1::Array{<:Constraint}, c2::Constraint) = c1 ∩ [c2]





# export Constraint, Cone, PositiveSemidefinite, PositiveOrthant, EqualityConstraint, ConeConstraint

# import Base.==, Base.<=, Base.>=, Base.<, Base.>, Base.in, Base.∩, Base.isequal, Base.∈, Base.:≤, Base.:≥

# # abstract type Constraint end

# "Add a constraint to all variables in an expression."
# function add_constraint!(x::Expression, c::Constraint)
#   vars = variables(x)
#   for v ∈ collect(vars)
#     push!(v.constraints, c)
#   end
#   nothing
# end

# "Data type that a constraint involves."
# type(::Constraint{T}) where {T<:Value} = T

# ###############################################################################
# # Each `Constraint` must specialize the following methods.

# function isequal(c1::Constraint, c2::Constraint)::Bool end

# ###############################################################################
# # ConeConstraint

# abstract type Cone end
# struct PositiveSemidefinite <: Cone end
# struct PositiveOrthant <: Cone end

# struct ConeConstraint{T<:Value,K<:Cone} <: Constraint{T}
#   x::Expression{T}
  
#   function ConeConstraint{T,K}(x::Expression{T}) where {T<:Value,K<:Cone}
#     this = new(x)
#     add_constraint!(x, this)
#     return this
#   end
# end

# struct EqualityConstraint{T<:Value} <: Constraint{T}
#   x::Expression{T}
  
#   function EqualityConstraint{T}(x::Expression{T}) where {T<:Value}
#     this = new(x)
#     add_constraint!(x, this)
#     return this
#   end
# end

# isequal(lhs::EqualityConstraint, rhs::EqualityConstraint) = isequal(lhs.x,rhs.x)
# isequal(lhs::ConeConstraint{T,C}, rhs::ConeConstraint{T,C}) where {T<:Value,C<:Cone} = isequal(lhs.x,rhs.x)

# ==(lhs::Expression{T}, rhs::Expression{T}) where {T<:Value} = EqualityConstraint{T}(lhs-rhs)
# ==(lhs::Expression{T}, rhs) where {T<:Value} = EqualityConstraint{T}(lhs-rhs)
# ==(lhs, rhs::Expression{T}) where {T<:Value} = EqualityConstraint{T}(lhs-rhs)

# ≤(lhs::Expression{T}, rhs::Expression{T}) where {T<:Value} = ConeConstraint{T,PositiveOrthant}(rhs-lhs)
# ≤(lhs::Expression{T}, rhs) where {T<:Value} = ConeConstraint{T,PositiveOrthant}(rhs-lhs)
# ≤(lhs, rhs::Expression{T}) where {T<:Value} = ConeConstraint{T,PositiveOrthant}(rhs-lhs)

# ≥(lhs::Expression{T}, rhs::Expression{T}) where {T<:Value} = ConeConstraint{T,PositiveOrthant}(lhs-rhs)
# ≥(lhs::Expression{T}, rhs) where {T<:Value} = ConeConstraint{T,PositiveOrthant}(lhs-rhs)
# ≥(lhs, rhs::Expression{T}) where {T<:Value} = ConeConstraint{T,PositiveOrthant}(lhs-rhs)

# ⪯(lhs::Expression{T}, rhs::Expression{T}) where {T<:Value} = ConeConstraint{T,PositiveSemidefinite}(rhs-lhs)
# ⪯(lhs::Expression{T}, rhs) where {T<:Value} = ConeConstraint{T,PositiveSemidefinite}(rhs-lhs)
# ⪯(lhs, rhs::Expression{T}) where {T<:Value} = ConeConstraint{T,PositiveSemidefinite}(rhs-lhs)

# ⪰(lhs::Expression{T}, rhs::Expression{T}) where {T<:Value} = ConeConstraint{T,PositiveSemidefinite}(lhs-rhs)
# ⪰(lhs::Expression{T}, rhs) where {T<:Value} = ConeConstraint{T,PositiveSemidefinite}(lhs-rhs)
# ⪰(lhs, rhs::Expression{T}) where {T<:Value} = ConeConstraint{T,PositiveSemidefinite}(lhs-rhs)

# in(x::Expression{T}, ::C) where {T<:Value,C<:Cone} = ConeConstraint{T,C}(x)

# # "Add constraints."
# ∩(c1::Array{<:Constraint},c2::Array{<:Constraint}) = append!(append!(Constraint[], c1), c2)
# ∩(c1::Constraint, c2::Constraint) = [c1] ∩ [c2]
# ∩(c1::Constraint, c2::Array{<:Constraint}) = [c1] ∩ c2
# ∩(c1::Array{<:Constraint}, c2::Constraint) = c1 ∩ [c2]
