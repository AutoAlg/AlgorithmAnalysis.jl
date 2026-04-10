
export trueeq
const trueeq = deepcopy(Base.:(==))

"""
    Constraint

A `Constraint` represents a condition that an `Expression` must satisfy with respect to a specified `ConstraintSet`. It encapsulates the relationship between an expression and the constraints imposed on it.
"""
struct Constraint <: AbstractConstraint
    x::Expression
    s::ConstraintSet
    
    function Constraint(x::Expression, s::ConstraintSet)
        if !hasvalue(x)
            this = new(x, s)
            add_constraint!(x, this)
            this
        else
            @show value(x)
            check(x,s) ? Satisfied() : Unsatisfied()
        end
    end
end

∈(x::Expression, s::ConstraintSet) = Constraint(x, s)
∈(w::Wrapper, s::ConstraintSet) = unwrap(w) ∈ s

############################################################################################
# Add constraint

"Add a constraint to all variables in an expression."
function add_constraint!(x::Expression, c::Constraint)
    push!(constraints(x), c)
    map(v -> push!(constraints(v), c), collect(variables(x)))
    for o in oracles(variables(x))
        inputs, outputs = inputs_outputs(o)
        for e in inputs ∪ outputs
            push!(constraints(e), c)
        end
    end
    # for o in oracles(x)
    #     push!(constraints(o), c)
    #     for a in associations(o)
    #         push!(constraints(last(a)), c)
    #     end
    # end
end


############################################################################################
# Constraint

# function ∈(x::Expression, s::ConstraintSet)
#     error("∈ not implemented for expression $(typeof(x)) and set $(typeof(s)).")
# end
# expression(c::Constraint) = error("expression not implemented for constraint $(typeof(c)).")
# set(c::Constraint) = error("set not implemented for constraint $(typeof(c)).")

size(c::Constraint) = size(expression(c))

variables(c::Constraint) = variables(expression(c))


"""
    Satisfied <: AbstractConstraint

Represents a constraint that is considered satisfied. This type is used to indicate that a particular constraint condition holds true.

# Examples

```julia-repl
julia> c = Satisfied()
Satisfied()
```
"""
struct Satisfied <: AbstractConstraint end

"""
    Unsatisfied <: AbstractConstraint

Represents a constraint that is considered unsatisfied. This type is used to indicate that a particular constraint condition does not hold true.

# Examples

```julia-repl
julia> c = Unsatisfied()
Unsatisfied()
```
"""
struct Unsatisfied <: AbstractConstraint end

expression(::Satisfied) = Expressions()
expression(::Unsatisfied) = Expressions()

############################################################################################
# Cone constraint

"""
    Cone <: ConstraintSet

An abstract type representing cones in the constraint set framework.
Cones capture specific properties used to impose constraints.
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
    UnrestrictedCone <: Cone

A cone representing the unrestricted set, used to indicate that a variable is not subject to any specific constraints.
"""
struct UnrestrictedCone <: Cone end

"""
    Constraint{K<:Cone} <: Constraint

A constraint that associates an expression with a cone `K` to enforce cone-specific properties.

# Fields
- `x::Expression`: The expression to which the constraint is applied.

# Constructor Behavior
When constructing a `Constraint` with an expression `x`:
- **If** `x` does not already have an associated value (i.e. `!hasvalue(x)` is `true`), a new `Constraint` is created, registered via `add_constraint!(x, this)`, and returned.
- **Otherwise**, the function checks if `x` satisfies the constraint for cone `K` using `check(x, K)`. It returns `Satisfied()` if the check passes, or `Unsatisfied()` if it fails.

# Example

```julia-repl
julia> x0 = Rⁿ()
julia> c = Constraint{PositiveOrthant}(x0)
```
"""
# struct Constraint <: AbstractConstraint
#     x::Expression
#     K::Cone
    
#     function Constraint(x::Expression, K::Cone)
#         if !hasvalue(x)
#             this = new(x, K)
#             add_constraint!(x, this)
#             this
#         else
#             check(x,K) ? Satisfied() : Unsatisfied()
#         end
#     end
# end

"""
    ∈(x::Expression, ::K) where {K<:Cone}

Creates a cone constraint for an expression `x` using the cone type `K`.

# Example

```julia-repl
julia> x0 = Rⁿ()
julia> x ∈ PositiveOrthant   # Returns a Constraint(x, PositiveOrthant())
```
"""
∈(x::Expression, K::Cone) = Constraint(x, K)

"""
    expression(c::Constraint)

Extracts and returns the underlying expression `x` stored in a cone constraint `c`.

# Example

```julia-repl
julia> x0 = Rⁿ()
julia> c = Constraint(x0, PositiveOrthant())
julia> expression(c)   # Returns the expression associated with the constraint
```
"""
expression(c::Constraint) = c.x

"""
    set(::Constraint{K}) where {K<:Cone}

Returns the cone type `K` associated with the given cone constraint. This function allows you to query the cone that the constraint is enforcing.

# Example

```julia-repl
julia> x0 = Rⁿ()
julia> c = Constraint(x0, PositiveOrthant())
julia> set(c)   # Returns PositiveOrthant()
```
"""
set(c::Constraint) = c.s

"""
    cone(c::Constraint)

Alias for `set(c)`. Returns the cone type associated with the cone constraint `c`.

# Example

```julia-repl
julia> x0 = Rⁿ()
julia> c = Constraint(x0, PositiveOrthant())
julia> cone(c)   # Returns PositiveOrthant()
```
"""
cone(c::Constraint) = set(c)

"""
    ==(lhs::Expression, rhs::Expression)
    ==(lhs::Expression, rhs)
    ==(lhs, rhs::Expression)

Defines an equality constraint between expressions by subtracting `rhs` from `lhs` and wrapping the result with the `Equality` constraint.
This allows you to create a constraint on two expressions to be equal.

# Example

```julia-repl
julia> x, y = Rⁿ(), Rⁿ()
julia> x == y   # Returns Equality(x - y)
```
"""
==(lhs::Expression, rhs::Expression) = Constraint(lhs-rhs, ZeroSet())
==(lhs::Expression, rhs) = Constraint(lhs-rhs, ZeroSet())
==(lhs, rhs::Expression) = Constraint(lhs-rhs, ZeroSet())

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
≤(lhs::Expression, rhs::Expression) = Constraint(rhs-lhs, PositiveOrthant())
≤(lhs::Expression, rhs) = Constraint(rhs-lhs, PositiveOrthant())
≤(lhs, rhs::Expression) = Constraint(rhs-lhs, PositiveOrthant())

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
julia> x ≥ y   # Returns Positive(x - y)
```
"""
≥(lhs::Expression, rhs::Expression) = Constraint(lhs-rhs, PositiveOrthant())
≥(lhs::Expression, rhs) = Constraint(lhs-rhs, PositiveOrthant())
≥(lhs, rhs::Expression) = Constraint(lhs-rhs, PositiveOrthant())

"""
    ⪯(lhs::Expression, rhs::Expression)
    ⪯(lhs::Expression, rhs)
    ⪯(lhs, rhs::Expression)

Defines a positive semidefinite constraint on the difference between 2 expressions by applying a `Semidefinite` cone constraint on `rhs - lhs`.
This allows you to create a constraint on the the difference subtract the left hand side expression `lhs` from the right hand side expression `rhs` to be positive semidefinite.

# Example

```julia-repl
julia> A, B = Rⁿ(), Rⁿ()
julia> A ⪯ B   # Returns Semidefinite(B - A)
```
"""
⪯(lhs::Expression, rhs::Expression) = Constraint(rhs-lhs, PositiveSemidefiniteCone())
⪯(lhs::Expression, rhs) = Constraint(rhs-lhs, PositiveSemidefiniteCone())
⪯(lhs, rhs::Expression) = Constraint(rhs-lhs, PositiveSemidefiniteCone())

"""
    ⪰(lhs::Expression, rhs::Expression) = Constraint(lhs-rhs, PositiveSemidefiniteCone())
    ⪰(lhs::Expression, rhs) = Constraint(lhs-rhs, PositiveSemidefiniteCone())
    ⪰(lhs, rhs::Expression) = Constraint(lhs-rhs, PositiveSemidefiniteCone())

Defines a positive semidefinite constraint on the difference between two expressions.

# Example

```julia-repl
julia> A, B = Rⁿ(), Rⁿ()
julia> A ⪯ B   # Returns Semidefinite(B - A)
```
"""
⪰(lhs::Expression, rhs::Expression) = Constraint(lhs-rhs, PositiveSemidefiniteCone())
⪰(lhs::Expression, rhs) = Constraint(lhs-rhs, PositiveSemidefiniteCone())
⪰(lhs, rhs::Expression) = Constraint(lhs-rhs, PositiveSemidefiniteCone())


############################################################################################
# Duality

# dual cones
dual(::PositiveSemidefiniteCone) = PositiveSemidefiniteCone()
dual(::PositiveOrthant) = PositiveOrthant()
dual(::ZeroSet) = UnrestrictedCone()
dual(::UnrestrictedCone) = ZeroSet()

# function dual(c::Positive, G, model)
#     JuMP.@variable(model, λ[1:length(x)] ≥ 0)
#     M = linearform(G, expression(c))
    
#     λ*M
# end

# function dual(c::Semidefinite, G, model)
#     JuMP.@variable(model, λ[1:length(x)] ≥ 0)
#     M = linearform(G, expression(c))
    
#     λ*M
# end


"""
    get_element(model::JuMP.Model, K::Cone, sz::Tuple)

Given a JuMP model, a cone type `K`, and a size tuple `sz`, this function creates and returns a variable that belongs to the specified cone `K` with the given size. The variable is constrained according to the properties of the cone.
"""
function get_element(model::JuMP.Model, K::Cone, sz::Tuple)

    if K == UnrestrictedCone()
        var = JuMP.@variable(model, [1:sz[1], 1:sz[2]])

    elseif K == ZeroSet()
        var = JuMP.@variable(model, [1:sz[1], 1:sz[2]])
        JuMP.@constraint(model, var == 0)

    elseif K == PositiveOrthant()
        var = JuMP.@variable(model, [1:sz[1], 1:sz[2]])
        JuMP.@constraint(model, var .≥ 0)

    elseif K == PositiveSemidefiniteCone()
        var = JuMP.@variable(model, [1:sz[1], 1:sz[2]], Symmetric)
        JuMP.@constraint(model, var >= 0, JuMP.PSDCone())

    else
        error("Unsupported cone type: $K")
    end
    return var
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

check(x, ::ZeroSet) = hasvalue(x) && !hasdecomposition(x) && evaluate(x) == 0
check(x, ::PositiveOrthant) = hasvalue(x) && !hasdecomposition(x) && evaluate(x) ≥ 0
check(x, ::PositiveSemidefiniteCone) = hasvalue(x) && !hasdecomposition(x) && evaluate(x) ⪰ 0

check(::Oracle, ::ConstraintSet) = false

############################################################################################
# Prune

"""
    prune!(s)

Prune a set of constraints by removing any constraints that are satisfied.
"""
function prune!(cons::Constraints)
    cons = setdiff!(cons, Set([Satisfied()]))

    pruned = Constraints()
    for c in cons
        if expression(c) isa Gram
            to_remove = Constraints()  # Store constraints to remove
            should_add = true
            for existing_c in pruned
                if expression(existing_c) isa Gram
                    if expression(existing_c) ⊆ expression(c) # Existing is a subset → Mark it for removal
                        push!(to_remove, existing_c)
                    end
                    if expression(c) ⊆ expression(existing_c)  # New one is a subset of existing
                        should_add = false  # Don't add the new one
                        break
                    end
                end
            end
            for r in to_remove # Remove outdated constraints
                delete!(pruned, r)
            end
            if should_add # Add the new constraint if it is not a subset of any existing one
                push!(pruned, c)
            end
        else
            push!(pruned, c)  # Keep non-Gram constraints
        end
    end
    # pruned = gram_to_constraint(pruned)
    pruned
end
# prune!(s::Constraints) = setdiff!(s, Set([Satisfied()]))
# function prune!(s::Constraints)
#     filtered = Constraints()
#     for c in s
#         if expression(c) isa Gram
#             push!(filtered, Constraint{cone(c)}(evaluate(expression(c))))
#         else
#             push!(filtered, c)
#         end
#     end
#     setdiff!(filtered, Set([Satisfied()]))
# end