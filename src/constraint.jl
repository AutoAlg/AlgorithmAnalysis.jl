
export set, add_constraint!
export Cone, PositiveSemidefiniteCone, PositiveOrthant, ZeroSet, Positive, Semidefinite, Equality
export ConeConstraint, Satisfied, Unsatisfied, prune!, check, dual, cone
export ⪯, ⪰, ⊆
export Gram, evaluate, gram_to_constraint


########################################################
# Constraint
########################################################

function ∈(x::Object, s::ConstraintSet)
    error("∈ not implemented for expression $(typeof(x)) and set $(typeof(s)).")
end
expression(c::Constraint) = error("expression not implemented for constraint $(typeof(c)).")
set(c::Constraint) = error("set not implemented for constraint $(typeof(c)).")

size(c::Constraint) = size(expression(c))

"""
    Satisfied <: Constraint

Represents a constraint that is considered satisfied. This type is used to indicate that a particular constraint condition holds true.

# Examples

```julia-repl
julia> c = Satisfied()
Satisfied()
```
"""
struct Satisfied <: Constraint end

"""
    Unsatisfied <: Constraint

Represents a constraint that is considered unsatisfied. This type is used to indicate that a particular constraint condition does not hold true.

# Examples

```julia-repl
julia> c = Unsatisfied()
Unsatisfied()
```
"""
struct Unsatisfied <: Constraint end


########################################################
# Cone constraint

"""
    Cone <: ConstraintSet

An abstract type representing cones in the constraint set framework.
Cones capture specific traits used to impose constraints.
"""
abstract type Cone <: ConstraintSet end

"""
    PositiveSemidefiniteCone <: Cone

A cone representing the set of positive semidefinite matrices.
"""
struct PositiveSemidefiniteCone <: Cone end

"""
    PositiveOrthant <: Cone

A cone representing the positive orthant.
It is used to impose non-negativity constraints on variables.
"""
struct PositiveOrthant <: Cone end

"""
    ZeroSet <: Cone

A cone representing the zero set, used to enforce equality constraints (i.e. requiring a variable to be exactly zero).
"""
struct ZeroSet <: Cone end

"""
    ConeConstraint{K<:Cone} <: Constraint

A constraint that associates an expression with a cone `K` to enforce cone-specific traits.

# Fields
- `x::Expression`: The expression to which the constraint is applied.

# Constructor Behavior
When constructing a `ConeConstraint` with an expression `x`:
- **If** `x` does not already have an associated value (i.e. `!hasvalue(x)` is `true`), a new `ConeConstraint` is created, registered via `add_constraint!(x, this)`, and returned.
- **Otherwise**, the function checks if `x` satisfies the constraint for cone `K` using `check(x, K)`. It returns `Satisfied()` if the check passes, or `Unsatisfied()` if it fails.

# Example

```julia-repl
julia> x0 = Rⁿ()
julia> c = ConeConstraint{PositiveOrthant}(x0)
```
"""
struct ConeConstraint{K<:Cone} <: Constraint
    x::Object
    
    function ConeConstraint{K}(x) where {K<:Cone}
        this = new(x)
        push!(constraints(x), this)
        this
    end
end

"""
    Positive

A shortcut for creating a ConeConstraint with the PositiveOrthant cone. Use this constant to impose non-negativity constraints on an expression.
"""
const Positive = ConeConstraint{PositiveOrthant}

"""
    Semidefinite

A shortcut for creating a ConeConstraint with the PositiveSemidefiniteCone cone. Use this constant to impose positive semidefiniteness constraints on an expression.
"""
const Semidefinite = ConeConstraint{PositiveSemidefiniteCone}

"""
    Equality

A shortcut for creating a ConeConstraint with the ZeroSet cone. Use this constant to impose equality (zero) constraints on an expression. 
"""
const Equality = ConeConstraint{ZeroSet}

"""
    ∈(x::Expression, ::K) where {K<:Cone}

Creates a cone constraint for an expression `x` using the cone type `K`.

# Example

```julia-repl
julia> x0 = Rⁿ()
julia> x ∈ PositiveOrthant
```
"""
∈(x::Object, ::K) where {K<:Cone} = ConeConstraint{K}(x)

"""
    expression(c::ConeConstraint)

Extracts and returns the underlying expression `x` stored in a cone constraint `c`.

# Example

```julia-repl
julia> x0 = Rⁿ()
julia> c = ConeConstraint{PositiveOrthant}(x0)
julia> expression(c)   # Returns the expression associated with the constraint
```
"""
expression(c::ConeConstraint) = c.x

"""
    set(::ConeConstraint{K}) where {K<:Cone}

Returns the cone type `K` associated with the given cone constraint. This function allows you to query the cone that the constraint is enforcing.

# Example

```julia-repl
julia> x0 = Rⁿ()
julia> c = ConeConstraint{PositiveOrthant}(x0)
julia> set(c)   # Returns PositiveOrthant
```
"""
set(::ConeConstraint{K}) where {K<:Cone} = K

"""
    cone(c::ConeConstraint)

Alias for `set(c)`. Returns the cone type associated with the cone constraint `c`.

# Example

```julia-repl
julia> x0 = Rⁿ()
julia> c = ConeConstraint{PositiveOrthant}(x0)
julia> cone(c)
```
"""
cone(c::ConeConstraint) = set(c)

"""
    ==(lhs::Expression, rhs::Expression)
    ==(lhs::Expression, rhs)
    ==(lhs, rhs::Expression)

Defines an equality constraint between expressions by subtracting `rhs` from `lhs` and wrapping the result with the `Equality` constraint.
This allows you to create a constraint on two expressions to be equal.

# Example

```julia-repl
julia> x, y = Rⁿ(), Rⁿ()
julia> x == y
```
"""
==(lhs::Object, rhs::Object) = Equality(lhs-rhs)
==(lhs::Object, rhs) = Equality(lhs-rhs)
==(lhs, rhs::Object) = Equality(lhs-rhs)

"""
    ≤(lhs::Expression, rhs::Expression)
    ≤(lhs::Expression, rhs)
    ≤(lhs, rhs::Expression)

Defines a less-than-or-equal-to constraint between expressions. It creates a constraint by computing `rhs - lhs` and applying the `Positive` cone constraint,
ensuring that the difference lies within the positive orthant.
This allows you to create a constraint on the left hand side expression `lhs` to be smaller or equal to the the right hand side expression `rhs`.

# Example

```julia-repl
julia> x, y = Rⁿ(), Rⁿ()
julia> x ≤ y   # Returns Positive(y - x)
```
"""
≤(lhs::Object, rhs::Object) = Positive(rhs-lhs)
≤(lhs::Object, rhs) = Positive(rhs-lhs)
≤(lhs, rhs::Object) = Positive(rhs-lhs)

"""
    ≥(lhs::Expression, rhs::Expression)
    ≥(lhs::Expression, rhs)
    ≥(lhs, rhs::Expression)

Defines a greater-than-or-equal-to constraint between expressions. It creates a constraint by computing `lhs - rhs` and applying the `Positive` cone constraint,
ensuring that the difference lies within the positive orthant.
This allows you to create a constraint on the left hand side expression `lhs` to be greater or equal to the the right hand side expression `rhs`.

# Example

```julia-repl
julia> x, y = Rⁿ(), Rⁿ()
julia> x ≥ y
```
"""
≥(lhs::Object, rhs::Object) = Positive(lhs-rhs)
≥(lhs::Object, rhs) = Positive(lhs-rhs)
≥(lhs, rhs::Object) = Positive(lhs-rhs)

"""
    ⪯(lhs::Expression, rhs::Expression)
    ⪯(lhs::Expression, rhs)
    ⪯(lhs, rhs::Expression)

Defines a positive semidefinite constraint on the difference between 2 expressions by applying a `Semidefinite` cone constraint on `rhs - lhs`.
This allows you to create a constraint on the the difference subtract the left hand side expression `lhs` from the right hand side expression `rhs` to be positive semidefinite.

# Example

```julia-repl
julia> A, B = Rⁿ(), Rⁿ()
julia> A ⪯ B
```
"""
⪯(lhs::Object, rhs::Object) = Semidefinite(rhs-lhs)
⪯(lhs::Object, rhs) = Semidefinite(rhs-lhs)
⪯(lhs, rhs::Object) = Semidefinite(rhs-lhs)

"""
    ⪰(lhs::Expression, rhs::Expression) = Semidefinite(lhs-rhs)
    ⪰(lhs::Expression, rhs) = Semidefinite(lhs-rhs)
    ⪰(lhs, rhs::Expression) = Semidefinite(lhs-rhs)

Defines a positive semidefinite constraint on the difference between two expressions.

# Example

```julia-repl
julia> A, B = Rⁿ(), Rⁿ()
julia> A ⪯ B
```
"""
⪰(lhs::Object, rhs::Object) = Semidefinite(lhs-rhs)
⪰(lhs::Object, rhs) = Semidefinite(lhs-rhs)
⪰(lhs, rhs::Object) = Semidefinite(lhs-rhs)


########################################################
# Duality

adjoint(K::Type{<:Cone}) = dual(K)

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


#######################################################
# Check

"""
    check(c::Constraint)
    check(x::Expression, S::ConstraintSet)

Check whether or not a constraint is satisfied.
"""
function check end

check(c::Constraint) = check(expression(c), set(c))

check(x, ::Type{ZeroSet}) = hasvalue(x) && evaluate(x) == 0
check(x, ::Type{PositiveOrthant}) = hasvalue(x) && evaluate(x) ≥ 0
check(x, ::Type{PositiveSemidefiniteCone}) = hasvalue(x) && evaluate(x) ⪰ 0


########################################################
# Prune

"""
    prune!(s)

Prune a set of constraints by removing any constraints that are satisfied.
"""
prune!(s::Constraints) = setdiff!(s, Set([Satisfied()]))



########################################################
# SHOW

show(io::IO, c::Equality) = print(io, "0 = ", expression(c))
show(io::IO, c::Positive) = print(io, "0 ≤ ", expression(c))
show(io::IO, c::Semidefinite) = print(io, "0 ⪯ ", expression(c))

function show(io::IO, ::MIME"text/plain", cons::Constraints)
    prune!(cons)
    if isempty(cons)
        print(io, "Empty set of constraints")
    else
        print(io, "Set of constraints with $(length(cons)) " * (isone(length(cons)) ? "element:" : "elements:"))
        foreach( c -> print(io, "\n  ", c), cons )
    end
end
