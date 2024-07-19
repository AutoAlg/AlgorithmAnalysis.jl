
# a constraint expression
const ConEx = Union{Expression,AbstractArray{<:Expression}}

############################################################################################
# Add constraint

"Add a constraint to all variables in an expression."
function add_constraint!(x::ConEx, c::Constraint)
    map(v -> push!(constraints(v), c), collect(variables(x)))
end


############################################################################################
# Constraint

function ∈(x::Expression, s::ConstraintSet)
    error("∈ not implemented for expression $(typeof(x)) and set $(typeof(s)).")
end

expression(c::Constraint) = error("expression not implemented for constraint $(typeof(c)).")
set(c::Constraint) = error("set not implemented for constraint $(typeof(c)).")

function isequal(lhs::Constraint, rhs::Constraint)
    isequal( set(lhs), set(rhs) ) && isequal( expression(lhs), expression(rhs) )
end

struct Satisfied <: Constraint end
struct Unsatisfied <: Constraint end


############################################################################################
# Cone constraint

abstract type Cone <: ConstraintSet end
struct PositiveSemidefiniteCone <: Cone end
struct PositiveOrthant <: Cone end
struct ZeroSet <: Cone end

struct ConeConstraint{K<:Cone} <: Constraint
    x::ConEx
    
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

==(lhs::ConEx, rhs::ConEx) = Equality(lhs-rhs)
==(lhs::ConEx, rhs) = Equality(lhs-rhs)
==(lhs, rhs::ConEx) = Equality(lhs-rhs)

≤(lhs::ConEx, rhs::ConEx) = Positive(rhs-lhs)
≤(lhs::ConEx, rhs) = Positive(rhs-lhs)
≤(lhs, rhs::ConEx) = Positive(rhs-lhs)

≥(lhs::ConEx, rhs::ConEx) = Positive(lhs-rhs)
≥(lhs::ConEx, rhs) = Positive(lhs-rhs)
≥(lhs, rhs::ConEx) = Positive(lhs-rhs)

⪯(lhs::ConEx, rhs::ConEx) = Semidefinite(rhs-lhs)
⪯(lhs::ConEx, rhs) = Semidefinite(rhs-lhs)
⪯(lhs, rhs::Expression) = Semidefinite(rhs-lhs)

⪰(lhs::ConEx, rhs::ConEx) = Semidefinite(lhs-rhs)
⪰(lhs::ConEx, rhs) = Semidefinite(lhs-rhs)
⪰(lhs, rhs::ConEx) = Semidefinite(lhs-rhs)


############################################################################################
# Duality

# dual cones
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

check(x, ::Type{ZeroSet}) = (hasvalue(x) && evaluate(x) == 0)
check(x, ::Type{PositiveOrthant}) = (hasvalue(x) && evaluate(x) ≥ 0)
check(x, ::Type{PositiveSemidefiniteCone}) = (hasvalue(x) && evaluate(x) ⪰ 0)


############################################################################################
# Prune

"""
    prune!(s)

Prune a set of constraints by removing any constraints that are satisfied.
"""
prune!(s::Constraints) = setdiff!(s, Set([Satisfied()]))
