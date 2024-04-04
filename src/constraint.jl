
############################################################################################
# Add constraint

"Add a constraint to all variables in an expression."
add_constraint!(x::Expression, c::Constraint) = map(v -> push!(constraints(v), c), collect(variables(x)))


############################################################################################
# Constraint

∈(x::Expression, s::ConstraintSet) = error("∈ not implemented for expression $(typeof(x)) and set $(typeof(s)).")
expression(c::Constraint) = error("expression not implemented for constraint $(typeof(c)).")
set(c::Constraint) = error("set not implemented for constraint $(typeof(c)).")
isequal(lhs::Constraint, rhs::Constraint) = false

struct Satisfied <: Constraint end
struct Unsatisfied <: Constraint end


############################################################################################
# Cone constraint

abstract type Cone <: ConstraintSet end
struct PositiveSemidefiniteCone <: Cone end
struct PositiveOrthant <: Cone end
struct ZeroSet <: Cone end

struct ConeConstraint{K<:Cone} <: Constraint
    x::Expression
    
    function ConeConstraint{K}(x) where {K<:Cone}
        if !hasvalue(x)
            this = new(x)
            add_constraint!(x, this)
            this
        else
            check(x,K) ? Satisfied() : Unsatisfied()
        end
    end
end

const Positive = ConeConstraint{PositiveOrthant}
const Semidefinite = ConeConstraint{PositiveSemidefiniteCone}
const Equality = ConeConstraint{ZeroSet}

∈(x::Expression, ::K) where {K<:Cone} = ConeConstraint{K}(x)

expression(c::ConeConstraint) = c.x

set(::ConeConstraint{K}) where {K<:Cone} = K

isequal(lhs::ConeConstraint{K}, rhs::ConeConstraint{K}) where {K<:Cone} = isequal(lhs.x,rhs.x)

==(lhs::Expression, rhs::Expression) = Equality(lhs-rhs)
==(lhs::Expression, rhs) = Equality(lhs-rhs)
==(lhs, rhs::Expression) = Equality(lhs-rhs)

≤(lhs::Expression, rhs::Expression) = Positive(rhs-lhs)
≤(lhs::Expression, rhs) = Positive(rhs-lhs)
≤(lhs, rhs::Expression) = Positive(rhs-lhs)

≥(lhs::Expression, rhs::Expression) = Positive(lhs-rhs)
≥(lhs::Expression, rhs) = Positive(lhs-rhs)
≥(lhs, rhs::Expression) = Positive(lhs-rhs)

⪯(lhs::Expression, rhs::Expression) = Semidefinite(rhs-lhs)
⪯(lhs::Expression, rhs::Number) = Semidefinite(rhs-lhs)
⪯(lhs::Number, rhs::Expression) = Semidefinite(rhs-lhs)

⪰(lhs::Expression, rhs::Expression) = Semidefinite(lhs-rhs)
⪰(lhs::Expression, rhs::Number) = Semidefinite(lhs-rhs)
⪰(lhs::Number, rhs::Expression) = Semidefinite(lhs-rhs)

# function ==(lhs::AbstractArray{<:Expression}, rhs::AbstractArray{<:Expression})
#   if size(lhs) ≠ size(rhs)
#     error("Sizes must be the same.")
#   end
#   cons = Constraints()
#   for i ∈ eachindex(lhs)
#     if !iszero(lhs[i] - rhs[i])
#       push!(cons, lhs[i] == rhs[i])
#     end
#   end
#   cons
# end

############################################################################################
# Duality

# duals of cones
dual(::Type{PositiveSemidefiniteCone}) = PositiveSemidefiniteCone
dual(::Type{PositiveOrthant}) = PositiveOrthant
dual(::Type{ZeroSet}) = Any

function dual(c::Positive, G, model)
    JuMP.@variable(model, λ[1:length(x)] ≥ 0)
    M = linearform(G, expression(c))
    
    λ*M
end

function dual(c::Semidefinite, G, model)
    JuMP.@variable(model, λ[1:length(x)] ≥ 0)
    M = linearform(G, expression(c))
    
    λ*M
end


############################################################################################
# Check

"""
    check(c::Constraint)
    check(x::Expression, S::ConstraintSet)

Check whether or not a constraint is satisfied.
"""
function check end

check(c::Constraint) = check(expression(c), set(c))

check(x, ::Type{ZeroSet}) = evaluate(x) == 0
check(x, ::Type{PositiveOrthant}) = evaluate(x) ≥ 0
check(x, ::Type{PositiveSemidefiniteCone}) = evaluate(x) ⪰ 0


############################################################################################
# Prune

"""
    prune!(s)

Prune a set of constraints by removing any constraints that are satisfied.
"""
prune!(s::Constraints) = setdiff!(s, Set([Satisfied()]))
