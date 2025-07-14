# Manual

## Expressions

Algorithms are mathematical descriptions of computation. In AlgorithmAnalysis.jl, every mathematical object is an `Expression`. An algorithm then systematically manipulates input expressions to construct output expressions. AlgorithmAnalysis.jl finds worst-case performance guarantees for an algorithm over a class of problems.

Each expression `e` has a type `T <: Expression`. AlgorithmAnalysis.jl defines several common types of expressions, and also makes it simple for users to define their own types. The built-in types are as follows:
- `R` represents the set of real numbers
- `Rⁿ` and `Rᵐ` are real inner product spaces of arbitrary dimension (the superscripts `n` and `m` do *not* refer to concrete numbers as `Rⁿ` is a single symbol in Julia).

You can construct expressions like this:
```julia-repl
julia> a = R()
julia> u = Rⁿ()
```
Displaying an expression prints various information about the expression. For the scalar `a` for instance, the default display is
```julia-repl
Scalar in R
  Label: Variable{R}
```
The first line is a basic description of the variable, and the second line indicates its label. Every expression has a label, which is used when displaying expressions in compact form. For instance, if we stack two expressions into a vector, Julia displays the output as:
```julia
julia> [a, a]
2-element Vector{R}:
 Variable{R}
 Variable{R}
```
Here, the label of the label is used when displaying the expression. While the default label `Variable{R}` is not very descriptive, we can set the label of an expression as follows:
```julia
label!(a, "a")
```
Now AlgorithmAnalysis.jl will use the label in displaying the expression, for example:
```julia
julia> a
Scalar in R
  Label: a

julia> [a, a]
2-element Vector{R}:
 a
 a
```
Labeling each expression like this is tedious. Instead, we provide a macro `@algorithm` to automatically label expressions:
```julia
@algorithm a = R()
```
This constructs the expression and then labels it with the symbol used to represent the variable in the code (the left-hand side of the assignment). Beyond labeling, the macro also enables us to more closely resemble standard mathematical notation. For instance, we can instead construct expressions like this:
```julia
@algorithm a ∈ R
@algorithm u, v ∈ Rⁿ
```
When applied to multiple lines of code, it is convenient to put the code inside a block:
```julia
@algorithm begin
    a ∈ R
    u, v ∈ Rⁿ
end
```
We make extensive use of this macro throughout the manual. Whenever using the macro, we first explain the code without the macro to make explicit how the code is structured within Julia, but then show how to express the code more elegantly with the macro.

## Oracles

In addition to scalar and vector spaces, expressions can also be `Oracle`s, which are black-box functions (or more generally, relations) between other expression types. For instance, we can define a map from `Rⁿ` to `Rᵐ` like this:

```julia-repl
julia> f = Map{Rⁿ, Rᵐ}()
Oracle
  Description: Map from Rⁿ to Rᵐ
  Label: Map{Rⁿ,Rᵐ}
```

!!! tip
    AlgorithmAnalysis.jl uses `Map` to represent single-valued functions (since `Function` is already a keyword in Julia) and `Operator` to denote set-valued functions.

As with scalars and vectors, oracles have a label. We can again use the `@algorithm` macro to automatically label the oracle as well as to use standard mathematical notation:
```julia-repl
julia> @algorithm f : Rⁿ → Rᵐ
julia> f
Oracle
  Description: Map from Rⁿ to Rᵐ
  Label: f
```
We can access the domain and codomain of an oracle using:
```julia-repl
julia> domain(f)
Rⁿ
julia> codomain(f)
Rᵐ
```
Oracles can be sampled at expressions in their domain to produce expressions in their codomain.
```julia-repl
julia> @algorithm u ∈ Rⁿ
julia> f(u)
Vector in Rᵐ
  Label: f(u)
  Oracles: f
  Associations: Dual => f(u)*
```
The result is a vector in `Rᵐ`, which is given the intuitive label `f(u)`. The vector also has a set of `Oracles`, which are oracles for which the expression is an input or output. Since objects of type `Map` are functions, evaluating them at the same point yields the same output:
```julia-repl
julia> f(u) === f(u)
true
```
For a set-valued map, use
```julia-repl
julia> @algorithm F : Rⁿ => Rᵐ
julia> F
Oracle
  Description: Operator from Rⁿ to Rᵐ
  Label: F
```
Evaluating set-valued maps at the same expression yields different results:
```julia-repl
julia> F(u) === F(u)
false
```

## Algebraic manipulations

Algorithms manipulate expressions to perform computation. Depending on the type of expression, we can form other expressions using basic algebraic operations. With the real numbers `R`, for instance, we can construct other scalars using addition and multiplication:
```julia
julia> @algorithm a, b ∈ R
julia> a + b
Scalar in R
  Decomposition: b + a
```
Instead of a label, the expression `a + b` has a decomposition in terms of the expressions `a` and `b`. Note that the decomposition displays the expressions in a different order, although this does not change the expression. We can access this decomposition as follows:
```julia
julia> decomposition(a + b)
Linear decomposition over R:
  b → 1
  a → 1
```
The type of the decomposition is `LinearDecomposition{R}`. Expressions of this type are linear combinations of expressions in `R`. We can access the weights of the decomposition as a dictionary using
```julia
julia> weights(decomposition(a+b))
Dict{R, Union{Number, JuMP.VariableRef, JuMP.AffExpr}} with 2 entries:
  b => 1
  a => 1
```
The keys have type `R` while the weights have type `Number` (or are JuMP variables). As a shortcut, we can also access the weights of the decomposition using `weights(a+b)`.

The reals `R` can also be used with real numbers in Julia,
```julia
julia> 2a + 3b
Scalar in R
  Decomposition: 3 b + 2 a
```

The vector spaces `Rⁿ` and `Rᵐ` have similar algebraic operations as well as an inner product and norm:
```julia
julia> @algorithm u, v ∈ Rⁿ
julia> u'*v
Scalar in R
  Label: ⟨u,v⟩
  Oracles: v*

julia> u^2
Scalar in R
  Label: |u|²
  Oracles: u*
```
The inner product and norm produce scalars in `R`. Moreover, these scalars are given an intuitive label based on the labels of the `u` and `v`. In addition to labels, the scalars formed from the inner product and norm also have a set of `Oracles`, which are functions at which the expressions have been sampled. When forming the inner product, the expression `u'` indicates the transpose of the vector, which is an oracle:
```julia
julia> u'
Oracle
  Description: Linear functional on Rⁿ
  Label: u*
  Properties: Linear()
```
Instead of viewing this as a row vector, this is a linear functional (a function from the vector space to its underlying scalar field) over the vector space `Rⁿ`. Once again, it is given an intuitive label based on the label of the vector `u`. In addition to a label, the oracle has a set of properties, in this case the `Linear()` property. With this understanding, the inner product is applying the linear functional `u'` to the vector `v`, which results in the scalar `u'*v`.

## Constraints

AlgorithmAnalysis.jl can represent constraints on expressions. A constraint `c` has type `Constraint`. The most basic types of constraints are those that are identically satisfied or unsatisfied:
```julia-repl
julia> Satisfied()
Satisfied()

julia> Unsatisfied()
Unsatisfied()
```

A constraint enforces that an expression belongs to some set. In AlgorithmAnalysis.jl, a constraint set has type `ConstraintSet`. A particular type of constraint set is a `Cone`, and the corresponding constraint is a `ConeConstraint{K}` where `K<:Cone`. Some types of cones are:
- `PositiveSemidefiniteCone` is the cone of positive semidefinite matrices
- `PositiveOrthant` is the positive orthant
- `ZeroSet` is the set containing only zero
For convenience, we define the following constants for cone constraints:
- `Semidefinite` is `ConeConstraint{PositiveSemidefiniteCone}`
- `PositiveOrthant` is `ConeConstraint{PositiveOrthant}`
- `Equality` is `ConeConstraint{Zero}`

Cone constraints can be constructed using standard notation. For instance,
```julia-repl
julia> a == 0  # equal zero
julia> u ≥ 0   # positive orthant
julia> P ⪰ 0   # positive semidefinite
```

## Analysis