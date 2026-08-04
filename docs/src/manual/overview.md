# Overview

Algorithms are mathematical descriptions of computation. AlgorithmAnalysis.jl implements a domain-specific language (DSL) that enables users to represent algorithms symbolically with syntax that closely resembles their mathematical description, and then manipulate the algorithm both symbolically and numerically. We now provide an overview of this process; for more details please see the [API](./../api/fundamentals.md).


## Symbolics

Each mathematical object is a symbolic expression in some space. AlgorithmAnalysis defines several common spaces, such as [`R`](@ref) for the field of real numbers, [`Rⁿ`](@ref) for a real finite-dimensional vector space, and [`Prop`](@ref) for the set of propositions. Following standard mathematical notation, we can create variables in a space using the [`@alg`](@ref) macro as follows:
```julia-repl
julia> @alg a ∈ R
julia> @alg u ∈ Rⁿ
julia> @alg p, q ∈ Prop
```
Common methods are implemented for each of these spaces. For instance,
```julia-repl
julia> p ∧ q  # conjunction p and q
julia> a * u  # scale vector u by a
```
(the symbol `∧` can be typed by `\wedge<tab>`). We can also represent functions:
```julia-repl
julia> f ∈ functional(Rⁿ)
```
This constructs a functional `Rⁿ → R`, which can then be evaluated at vectors in `Rⁿ` to produce scalars in `R` and has standard associated methods:
```julia-repl
julia> f(u)         # scalar in R
julia> domain(f)    # Rⁿ
julia> codomain(f)  # R
```
Algorithms manipulate expressions to perform computation. Depending on the type of expression, we can form other expressions using basic algebraic operations. With the real numbers `R`, for instance, we can construct other scalars using addition and multiplication:
```julia
julia> @alg a, b ∈ R
julia> 2a + b
```
Here, the literal constant `2` is promoted to a symbolic expression in `R`, which can be done explicitly with `R(2)`, and assigned the constant value `2`. The vector space `Rⁿ` has similar algebraic operations as well as an inner product and norm:
```julia
julia> @alg u, v ∈ Rⁿ
julia> u'(v)   # inner produce of u and v
julia> u^2     # squared norm of u
```
The inner product and norm produce scalars in `R`. The inner product uses the function evaluation notation `u'(v)` since the adjoint `u'` of a vector is a linear functional `Rⁿ → R` which can then be evaluated at vectors to produce scalars. The notation `u^2` is not standard mathematical notation, but is a shorthand for `‖u‖²`.

AlgorithmAnalysis can represent constraints on expressions as propositions. The most basic propositions are those that are identically satisfied or unsatisfied:
```julia-repl
julia> satisfied()
true

julia> unsatisfied()
false
```
While these print as `true` and `false`, they are actually symbolic expressions with symtype `Prop`. Propositions that state equality between two expressions are formed as:
```julia-repl
julia> a == 0
a = 0
```

!!! warning
    To follow standard mathematical notation as closely as possible, AlgorithmAnalysis overloads `==` for propositional equality. As such, it should *not* be used to test for equality of two expression. Instead, we can check if two expressions are the same using `isequal(x,y)`.

We can also create inequality constraints on real scalars:
```julia-repl
julia> @alg a ∈ R
julia> a ≥ 0
```
For symmetric matrices, we can specify that a matrix is semidefinite as:
```julia-repl
julia> @alg A ∈ Sⁿ
julia> A ⪰ 0
```


## Numerics

While symbolic manipulations enable us to specify algorithms, analyzing them often requires numeric computation. To mix symbolic and numeric computations, AlgorithmAnalysis uses scoped values to construct a local scope in which symbolic expressions are instantiated with numeric values. As a simple example, we can substitute a numeric value for a parameter:
```julia
@alg begin
    a ∈ R
    with_parameters(Dict(a => 2)) do
        evaluate(a) == 2  # true
    end
end
```
This code constructs a scalar `a`, defines a local scope in which it has the value `2`, and then evaluates it within this scope. We can also use JuMP to numerically solve optimization problems. For instance, the following feasibility problem is (trivially) true:
```julia
@alg begin
    a ∈ R
    feas = feasible((x ≥ 1) ∧ (x ≤ 2))
    with_numerics() do
        evaluate(opt)  # true
    end
end
```
This construct a feasibility problem using [`feasible`](@ref), defines a local scope in which symbolic expressions are evaluated using a JuMP model using [`with_numerics`](@ref), and then solves the feasibility problem within this scope. While these examples are quite simple, we can use the same ideas to solve more general linear programs:
```julia
@alg let
    x, y ∈ R
    c1 = 50x + 24y ≤ 2400
    c2 = 30x + 33y ≤ 2100
    c3 = x ≥ 45
    c4 = y ≥ 5
    cons = c1 ∧ c2 ∧ c3 ∧ c4
    obj = x + y - 50
    opt = maximize(obj, cons)
    with_numerics() do
        evaluate(opt) ≈ 1.25 && evaluate(x) ≈ 45.0 && evaluate(y) ≈ 6.25  # true
    end
end
```
Since `with_numerics` creates a local scope, expressions that are obtained numerically maintain their numeric values within this scope. The above code first solves the optimization problem to obtain the numeric values for `x` and `y`, and then compares these numeric values against the known solution to the problem. Beyond linear programs, we can also solve semidefinite programs in a similar way:
```julia
@alg let
    x ∈ R
    A = [2 x; x 2]
    opt = maximize(x, A ⪰ 0)
    with_numerics() do
        evaluate(opt) ≈ 2.0  # true
    end
end
```

## Transformations

At this point, AlgorithmAnalysis can be viewed as an alternative domain-specific language for optimization. The main benefits come when combining symbolic and numeric computations together, which can create emergent behavior that can be useful in analyzing algorithms. To that end, consider the following optimization problem:
```julia
@alg begin
    α, L ∈ R, x, xs ∈ Rⁿ, f ∈ differentiable_functional(Rⁿ)

    gs   = f'(xs)
    g    = f'(x)
    init = (x - xs)^2
    x⁺   = x - α * g
    f⁺   = f(x⁺)
    c1   = smooth_convex(f, L)
    c2   = gs^2 == zero(R)
    c3   = init ≤ one(R)
    con  = c1 ∧ c2 ∧ c3
    obj  = f⁺ - f(xs)
    opt  = maximize(obj, con)
end
```
which prints as:
```julia
maximize     f(x - α * ∇f(x)) - f(xs)
subject to   f ∈ SmoothConvex(L)
             ‖∇f(xs)‖² = 0
             ‖x - xs‖² ≤ 1
```
One of the variables in this problem is the differentiable function `f : Rⁿ → R`, so the problem is intractable as written. We can symbolically simplify this optimization problem by replacing this function with its interpolation conditions between all of the points at which it is evaluated:
```julia-repl
julia> transformed_opt = smooth_convex_interpolation(opt)

maximize     f(x⁺) - f(xs)
subject to   f(xs) + ∇f(xs)'(xs - xs) + 1 / 2 * L * ‖∇f(xs) - ∇f(xs)‖² ≤ f(xs)
             f(x⁺) + ∇f(x⁺)'(xs - (x - α * ∇f(x))) + 1 / 2 * L * ‖∇f(xs) - ∇f(x⁺)‖² ≤ f(xs)
             f(x) + ∇f(x)'(xs - x) + 1 / 2 * L * ‖∇f(xs) - ∇f(x)‖² ≤ f(xs)
             f(xs) + ∇f(xs)'((x - α * ∇f(x)) - xs) + 1 / 2 * L * ‖∇f(x⁺) - ∇f(xs)‖² ≤ f(x⁺)
             f(x⁺) + ∇f(x⁺)'((x - α * ∇f(x)) - (x - α * ∇f(x))) + 1 / 2 * L * ‖∇f(x⁺) - ∇f(x⁺)‖² ≤ f(x⁺)
             f(x) + ∇f(x)'((x - α * ∇f(x)) - x) + 1 / 2 * L * ‖∇f(x⁺) - ∇f(x)‖² ≤ f(x⁺)
             f(xs) + ∇f(xs)'(x - xs) + 1 / 2 * L * ‖∇f(x) - ∇f(xs)‖² ≤ f(x)
             f(x⁺) + ∇f(x⁺)'(x - (x - α * ∇f(x))) + 1 / 2 * L * ‖∇f(x) - ∇f(x⁺)‖² ≤ f(x)
             f(x) + ∇f(x)'(x - x) + 1 / 2 * L * ‖∇f(x) - ∇f(x)‖² ≤ f(x)
             ‖∇f(xs)‖² = 0
             ‖x - xs‖² ≤ 1
```
This transformation has completely removed the function `f` from the problem. While some of the expressions appear to still depend on `f`, these have all been flattened to leaf expressions:
```julia-repl
leaves(transformed_opt)
Set{SymbolicUtils.BasicSymbolic} with 10 elements:
  ∇f(x)
  f(x⁺)
  L
  f(xs)
  ∇f(x⁺)
  x
  f(x)
  xs
  ∇f(xs)
  α
```
The optimization problem is still intractable as it involves vectors in `Rⁿ` whose dimension is arbitrarily large and therefore cannot be instantiated with numeric values. However, these vectors only appear in the optimization problem as inner products. A necessary and sufficient condition on these scalar values to be the inner product of such vectors is that the Gram matrix of all combinations of their inner products is positive semidefinite. We can therefore replace these vectors with their (flattened) inner products subject to the constraint that the Gram matrix is positive semidefinite. This is done automatically using:
```julia-repl
julia> final_opt = gram_transformation(transformed_opt)

maximize     f(x⁺) - f(xs)
subject to   f(xs) + ⟨xs,∇f(xs)⟩ - ⟨xs,∇f(xs)⟩ + 1 / 2 * L * ((‖∇f(xs)‖² - ‖∇f(xs)‖²) - (‖∇f(xs)‖² - ‖∇f(xs)‖²)) ≤ f(xs)
             f(x⁺) + ⟨xs,∇f(x⁺)⟩ - (⟨x,∇f(x⁺)⟩ - α * ⟨∇f(x),∇f(x⁺)⟩) + 1 / 2 * L * ((‖∇f(xs)‖² - ⟨∇f(xs),∇f(x⁺)⟩) - (⟨∇f(xs),∇f(x⁺)⟩ - ‖∇f(x⁺)‖²)) ≤ f(xs)
             f(x) + ⟨xs,∇f(x)⟩ - ⟨x,∇f(x)⟩ + 1 / 2 * L * ((‖∇f(xs)‖² - ⟨∇f(x),∇f(xs)⟩) - (⟨∇f(x),∇f(xs)⟩ - ‖∇f(x)‖²)) ≤ f(xs)
             f(xs) + (⟨x,∇f(xs)⟩ - α * ⟨∇f(x),∇f(xs)⟩) - ⟨xs,∇f(xs)⟩ + 1 / 2 * L * ((‖∇f(x⁺)‖² - ⟨∇f(xs),∇f(x⁺)⟩) - (⟨∇f(xs),∇f(x⁺)⟩ - ‖∇f(xs)‖²)) ≤ f(x⁺)
             f(x⁺) + (⟨x,∇f(x⁺)⟩ - α * ⟨∇f(x),∇f(x⁺)⟩) - (⟨x,∇f(x⁺)⟩ - α * ⟨∇f(x),∇f(x⁺)⟩) + 1 / 2 * L * ((‖∇f(x⁺)‖² - ‖∇f(x⁺)‖²) - (‖∇f(x⁺)‖² - ‖∇f(x⁺)‖²)) ≤ f(x⁺)
             f(x) + (⟨x,∇f(x)⟩ - α * ‖∇f(x)‖²) - ⟨x,∇f(x)⟩ + 1 / 2 * L * ((‖∇f(x⁺)‖² - ⟨∇f(x),∇f(x⁺)⟩) - (⟨∇f(x),∇f(x⁺)⟩ - ‖∇f(x)‖²)) ≤ f(x⁺)
             f(xs) + ⟨x,∇f(xs)⟩ - ⟨xs,∇f(xs)⟩ + 1 / 2 * L * ((‖∇f(x)‖² - ⟨∇f(x),∇f(xs)⟩) - (⟨∇f(x),∇f(xs)⟩ - ‖∇f(xs)‖²)) ≤ f(x)
             f(x⁺) + ⟨x,∇f(x⁺)⟩ - (⟨x,∇f(x⁺)⟩ - α * ⟨∇f(x),∇f(x⁺)⟩) + 1 / 2 * L * ((‖∇f(x)‖² - ⟨∇f(x),∇f(x⁺)⟩) - (⟨∇f(x),∇f(x⁺)⟩ - ‖∇f(x⁺)‖²)) ≤ f(x)
             f(x) + ⟨x,∇f(x)⟩ - ⟨x,∇f(x)⟩ + 1 / 2 * L * ((‖∇f(x)‖² - ‖∇f(x)‖²) - (‖∇f(x)‖² - ‖∇f(x)‖²)) ≤ f(x)
             ‖∇f(xs)‖² = 0
             (‖x‖² - ⟨x,xs⟩) - (⟨x,xs⟩ - ‖xs‖²) ≤ 1
             [‖∇f(x⁺)‖² ⟨xs,∇f(x⁺)⟩ ⟨∇f(x),∇f(x⁺)⟩ ⟨x,∇f(x⁺)⟩ ⟨∇f(xs),∇f(x⁺)⟩; ⟨xs,∇f(x⁺)⟩ ‖xs‖² ⟨xs,∇f(x)⟩ ⟨x,xs⟩ ⟨xs,∇f(xs)⟩; ⟨∇f(x),∇f(x⁺)⟩ ⟨xs,∇f(x)⟩ ‖∇f(x)‖² ⟨x,∇f(x)⟩ ⟨∇f(x),∇f(xs)⟩; ⟨x,∇f(x⁺)⟩ ⟨x,xs⟩ ⟨x,∇f(x)⟩ ‖x‖² ⟨x,∇f(xs)⟩; ⟨∇f(xs),∇f(x⁺)⟩ ⟨xs,∇f(xs)⟩ ⟨∇f(x),∇f(xs)⟩ ⟨x,∇f(xs)⟩ ‖∇f(xs)‖²] ⪰ 0
```
Again, this appears to still depend on the vectors, but notice that all the inner products are now leaf expressions:
```julia-repl
julia> leaves(final_opt)
Set{SymbolicUtils.BasicSymbolic} with 20 elements:
  ⟨∇f(x),∇f(xs)⟩
  ⟨∇f(x),∇f(x⁺)⟩
  ⟨xs,∇f(x⁺)⟩
  ⟨x,∇f(xs)⟩
  ⟨x,xs⟩
  ‖∇f(x⁺)‖²
  α
  f(x⁺)
  ‖x‖²
  ‖xs‖²
  f(x)
  ‖∇f(x)‖²
  ⟨xs,∇f(x)⟩
  ⟨xs,∇f(xs)⟩
  ⟨x,∇f(x)⟩
  ‖∇f(xs)‖²
  ⟨∇f(xs),∇f(x⁺)⟩
  ⟨x,∇f(x⁺)⟩
  L
  f(xs)
```
To help distinguish between inner products of vectors and their flattened scalar variables, the inner product between `u` and `v` is printed as `u'(v)` while the corresponding flattened scalar leaf prints as `⟨u,v⟩`. The optimization problem has now been transformed to a semidefinite program (once the parameters `α` and `L`) are fixed and can therefore be solved numerically. 
```
with_numerics(parameters = Dict(α => 0.075, L => 10.0)) do
    evaluate(final_opt) ≈ 2.0
end
```
While we manually selected which transformations to apply and in what order (smooth convex interpolation followed by the gram transformation), this process can be automated using rewrite rules in SymbolicUtils.jl. These transformations and more are implemented in the `simplify` method, which automatically reconstructs the final semidefinite program from the original optimization problem as:
```julia-repl
julia> final_opt = simplify(opt)
```
!!! info
    Numerically evaluating a symbolic expression does *not* modify the expression (which is immutable). Therefore, an expression can be evaluated again with different parameters:
    ```julia
    with_numerics(parameters = Dict(α => 0.075, L => 10.0)) do
        evaluate(final_opt) ≈ 2.0
    end
    with_numerics(parameters = Dict(α => 0.075, L => 6.0)) do
        evaluate(final_opt) ≈ 2.0
    end
    ```
