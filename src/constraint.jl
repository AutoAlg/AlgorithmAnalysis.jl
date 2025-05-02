############################################################################################
# Add constraint

"Add a constraint to all variables in an expression."
function add_constraint!(x::Object, c::Constraint)
    map(v -> push!(constraints(v), c), collect(variables(x)))
end


############################################################################################
# Constraint

function ∈(x::Object, s::ConstraintSet)
    error("∈ not implemented for expression $(typeof(x)) and set $(typeof(s)).")
end

expression(c::Constraint) = error("expression not implemented for constraint $(typeof(c)).")
set(c::Constraint) = error("set not implemented for constraint $(typeof(c)).")

size(c::Constraint) = size(expression(c))

struct Satisfied <: Constraint end
struct Unsatisfied <: Constraint end


############################################################################################
# Cone constraint

abstract type Cone <: ConstraintSet end
struct PositiveSemidefiniteCone <: Cone end
struct PositiveOrthant <: Cone end
struct ZeroSet <: Cone end

struct ConeConstraint{K<:Cone} <: Constraint
    x::Object
    
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

∈(x::Object, ::K) where {K<:Cone} = ConeConstraint{K}(x)

expression(c::ConeConstraint) = c.x

set(::ConeConstraint{K}) where {K<:Cone} = K

cone(c::ConeConstraint) = set(c)

==(lhs::Object, rhs::Object) = Equality(lhs-rhs)
==(lhs::Object, rhs) = Equality(lhs-rhs)
==(lhs, rhs::Object) = Equality(lhs-rhs)

≤(lhs::Object, rhs::Object) = Positive(rhs-lhs)
≤(lhs::Object, rhs) = Positive(rhs-lhs)
≤(lhs, rhs::Object) = Positive(rhs-lhs)

≥(lhs::Object, rhs::Object) = Positive(lhs-rhs)
≥(lhs::Object, rhs) = Positive(lhs-rhs)
≥(lhs, rhs::Object) = Positive(lhs-rhs)

⪯(lhs::Object, rhs::Object) = Semidefinite(rhs-lhs)
⪯(lhs::Object, rhs) = Semidefinite(rhs-lhs)
⪯(lhs, rhs::Object) = Semidefinite(rhs-lhs)

⪰(lhs::Object, rhs::Object) = Semidefinite(lhs-rhs)
⪰(lhs::Object, rhs) = Semidefinite(lhs-rhs)
⪰(lhs, rhs::Object) = Semidefinite(lhs-rhs)


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
    check(x::Object, S::ConstraintSet)

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
