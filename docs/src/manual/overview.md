# Overview

Algorithms are mathematical descriptions of computation. AlgorithmAnalysis.jl implements a domain-specific language (DSL) that enables users to represent algorithms symbolically with syntax that closely resembles their mathematical description, and then manipulate the algorithm both symbolically and numerically. We now provide an overview of this process; for more details please see the [API](./../api/index.md).

```@meta
ShareDefaultModule = true
```

```@setup
using AlgorithmAnalysis
```

## Symbolics

Each mathematical object is a symbolic expression in some space. AlgorithmAnalysis defines several common spaces, such as [`R`](@ref) for the field of real numbers, [`Rⁿ`](@ref) for a real finite-dimensional vector space, and [`Prop`](@ref) for the set of propositions. Following standard mathematical notation, we can create variables in a space using the [`@alg`](@ref) macro as follows:
```@repl
@alg a ∈ R
@alg u ∈ Rⁿ
@alg p, q ∈ Prop
```
Common methods are implemented for each of these spaces. For instance,
```@repl
p ∧ q  # conjunction p and q, the symbol `∧` can be typed by `\wedge<tab>`
a * u  # scale vector u by a
```
To assign these expressions to other variables, we again use the `@alg` macro:
```@repl
@alg r = p ∧ q
```

!!! note
    The [`@alg`](@ref) macro is used to define symbolic variables and assign symbolic expressions. While assignments could be done without the macro (such as `r = p ∧ q`), the macro automatically converts objects to symbolic expressions (when available) and labels them with the symbol on the left side of the assignment so that expressions are printed using the same symbol that represents the expression in the code. We therefore recommend using the `@alg` macro whenever creating variables or assigning symbolic expressions.

We can also represent functions:
```@repl
@alg f ∈ functional(Rⁿ)
```
This constructs a functional `Rⁿ → R`, which can then be evaluated at vectors in `Rⁿ` to produce scalars in `R`:
```@repl
@alg a = f(u)
```
Depending on the type of expression, we can form other expressions using basic algebraic operations. With the real numbers `R`, for instance, we can construct other scalars using addition and multiplication:
```@repl
@alg a, b ∈ R
2a + b
```
Here, the literal constant `2` is promoted to a symbolic expression in `R`, which can be done explicitly with `R(2)`, and assigned the constant value `2`. The vector space `Rⁿ` has similar algebraic operations as well as an inner product and norm:
```@repl
@alg u, v ∈ Rⁿ
u'(v)   # inner product of u and v
u^2     # squared norm of u
```
The inner product and norm produce scalars in `R`. The inner product uses the function evaluation notation `u'(v)` since the adjoint `u'` of a vector is a linear functional `Rⁿ → R` which can then be evaluated at vectors to produce scalars. The notation `u^2` is not standard mathematical notation, but is a shorthand for `‖u‖²`.

AlgorithmAnalysis can represent constraints on expressions as propositions. For instance, the proposition that two expressions are equal is formed as:
```@repl
a == 0
```

!!! warning
    To follow standard mathematical notation as closely as possible, AlgorithmAnalysis overloads `==` for propositional equality. As such, it should *not* be used to test for equality of two expression. Instead, use `isequal(x,y)` to check if two expressions are the same.

We can also create inequality constraints on real scalars:
```@repl
@alg a ∈ R
a ≥ 0
```
For symmetric matrices, we can specify that a matrix is semidefinite as:
```@repl
@alg A ∈ Sⁿ
A ⪰ 0
```


## Numerics

While symbolic manipulations enable us to specify algorithms, analyzing them often requires numeric computation. To mix symbolic and numeric computations, AlgorithmAnalysis uses scoped values to construct a local scope in which symbolic expressions are instantiated with numeric values. As a simple example, we can substitute a numeric value for a parameter:
```julia
@alg let
    a ∈ R
    with_parameters(Dict(a => 2)) do
        evaluate(a)  # 2
    end
    evaluate(a)  # a
end
```
This code constructs a scalar `a`, defines a local scope in which it has the value `2`, and then evaluates it within this scope. Outside of this scope, however, `a` is still a symbolic variable.

We can also formulate symbolic optimization problems and then solve them numerically use JuMP. For instance, the following feasibility problem is (trivially) true:
```julia
@alg let
    x ∈ R
    feas = feasible((x ≥ 1) ∧ (x ≤ 2))
    with_numerics() do
        evaluate(feas)  # true
    end
end
```
This construct a feasibility problem using [`feasible`](@ref), defines a local scope in which symbolic expressions are evaluated using a JuMP model using [`with_numerics`](@ref), and then solves the feasibility problem within this scope to obtain the boolean literal `true`. While these examples are quite simple, we can use the same ideas to solve more general linear programs:
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

At this point, AlgorithmAnalysis can be viewed as a domain-specific language for optimization, similar to other DSLs such as JuMP and Convex. The main benefits come when combining symbolic and numeric computations together, which can create emergent behavior that can be useful in analyzing algorithms. To that end, consider the following optimization problem:
```@repl
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
```@repl
opt
```
We can view all leaf nodes in this optimization problem using [`leaves`](@ref):
```@repl
leaves(opt)
```
One of the leaf variables in this problem is the differentiable function `f : Rⁿ → R`, so the problem is intractable as written. However, we can symbolically simplify this optimization problem by replacing the ``L``-smooth convex function ``f`` with its interpolation conditions between all of the points at which it is evaluated:
```@repl
transformed_opt = smooth_convex_interpolation(opt)
```
This transformation has completely removed the function `f` from the problem. While some of the expressions appear to still depend on `f`, these have all been flattened to leaf expressions:
```@repl
leaves(transformed_opt)
```
For instance, the symbol `∇f(x)` represents a leaf node in `Rⁿ`, and *not* the evaluation of the gradient of `f` at `x`. The optimization problem is still intractable though, as it involves vectors in `Rⁿ` whose dimension is arbitrarily large and therefore cannot be instantiated with numeric values. However, these vectors only appear in the optimization problem as inner products. A necessary and sufficient condition on these scalar values to be the inner product of such vectors is that the Gram matrix of all combinations of their inner products is positive semidefinite. We can therefore replace these vectors with their (flattened) inner products subject to the constraint that the Gram matrix is positive semidefinite. This is done automatically using:
```@repl
final_opt = gram_transformation(transformed_opt)
```
The first 9 constraints are from the interpolation conditions, the next two are from the original problem, and the last constraint is that the Gram matrix of inner products is positive semidefinite. Again, this appears to still depend on vectors, but notice that all the inner products are now leaf expressions:
```@repl
leaves(final_opt)
```
All of these quantities are symbolic variables in `R`, and *not* function evaluations. To help distinguish between inner products of vectors and their flattened scalar variables, the inner product between `u` and `v` is printed as `u'(v)` while the corresponding flattened scalar leaf prints as `⟨u,v⟩` when the vectors are different and `‖u‖²` when they are the same. The optimization problem has now been transformed to a semidefinite program (once the parameters `α` and `L` are fixed) and can therefore be solved numerically:
```@repl
with_numerics(parameters = Dict(α => 0.075, L => 10.0)) do
    evaluate(final_opt)
end
```
While we manually selected which transformations to apply and in what order (smooth convex interpolation followed by the gram transformation), this process can be *automated*. These transformations and more are implemented in [`simplify`](@ref), which automatically reconstructs the final semidefinite program from the original optimization problem as:
```@repl
final_opt = simplify(opt);
```
Also, numerically evaluating a symbolic expression does *not* modify the expression (which is immutable). Therefore, an expression can be evaluated again with different parameters:
```@repl
with_numerics(parameters = Dict(α => 0.075, L => 10.0)) do
    evaluate(final_opt)
end
with_numerics(parameters = Dict(α => 1/3, L => 3.0)) do
    evaluate(final_opt)
end
```
For more details on this approach to algorithm analysis, see the [performance estimation](./../manual/pep.md) section of the manual.


## Iterative algorithms as dynamical systems

We can interpret iterative algorithms as dynamical systems, which can then be analyzed using tools from control theory. Dynamical systems have a *state* that evolves over *time*. At each point in time, the state completely describes the behavior of the system. While time may either be continuous or discrete, algorithms are naturally represented as discrete-time systems in which the discrete time index represents the iteration of the algorithm. To describe the algorithm, we must therefore describe how the state changes between each iteration. When the update has the same form at each iteration, the system is *time invariant* and we only need to specify the update at some (generic) iteration.

We represent a state transition as:
```@repl
@alg x₁, x₂ ∈ R
@alg t = x₁ → x₂
```
This defines a state transition `t` (which is a proposition) that specifies that `x₁` is a component of the algorithm state whose value at the next iteration is `x₂`. An algorithm may have more than one component in the state, and any node on the left side of a transition is considered part of the state. For instance, a state with multiple components is
```@repl
@alg y₁, y₂ ∈ Rⁿ
@alg t = (x₁ → x₂) ∧ (y₁ → y₂)
```
This specifies that the state consists of both `x₁` and `y₁` whose values at the next iteration are `x₂` and `y₂`, respectively.

As a more interesting example, consider the following algorithm, which represents gradient descent applied to a differentiable function:
```@repl
@alg begin
    α, μ, L ∈ R
    x, xs ∈ Rⁿ
    f ∈ differentiable_functional(Rⁿ)
    gs = f'(xs)
    g  = f'(x)
    x₊ = x - α * g
    t1 = x → x₊
    t2 = xs → xs
    t3 = f → f
    c1 = sector_bounded(f, μ, L)
    c2 = gs^2 == zero(R)
    con = t1 ∧ t2 ∧ t3 ∧ c1 ∧ c2
    perf = (x - xs)^2
end
```
The main algorithmic update is the first transition, `t1 = x → x₊` where `x` represents the iterate of the algorithm at some generic point in time and `x₊ = x - α * f'(x)` its value at the next iteration. The other two transitions are for the stationary point `xs` and the objective function `f`, which are specified to be time invariant by the transitions `t2 = xs → xs` and `t3 = f → f`.

!!! info
    State transitions are included in the constraint, as they are propositions.

Given these symbolic expressions, we can symbolically construct the problem of searching for a certificate that guarantees convergence of the algorithm with a particular rate:
```@repl
@alg ρ ∈ R
prob = certify(con, perf, ρ)
```
This high-level symbolic object represents searching for a Lyapunov-based stability certificate for the given rate, performance measure, and constraint. Before formulating the search for a Lyapunov function that certifies stability, however, we must first apply several transformations to make the problem tractable. As before, the problem contains the function `f` as a variable, which cannot be used as a numeric decision variable. Instead, we replace the function with the sector bound:
```@repl
transformed_prob1 = sector_bounded_interpolation(prob)
```
The function `f` has now been completely removed from the problem:
```@repl
leaves(transformed_prob1)
```
Some of these leaves are vectors in `Rⁿ`, which also cannot be used as numeric decision variables. Replacing these vectors with the constraint that their Gram matrix is positive semidefinite yields the transformed problem:
```@repl
transformed_prob2 = gram_transformation(transformed_prob1)
```
All inner products have now been flattened to scalar leaf variables:
```@repl
leaves(transformed_prob2)
```
Also, recall that the state transitions in the original problem involved vectors like `x` and `xs`. Before flattening inner products, these transitions were first propagated to all applicable inner products, which resulted in the following three transitions:
```julia
‖xs‖² → ‖xs‖²
⟨x,xs⟩ → (⟨x,xs⟩ - α * ⟨xs,∇f(x)⟩)
‖x‖² → ((‖x‖² - α * ⟨x,∇f(x)⟩) - (α * ⟨x,∇f(x)⟩ - α * α * ‖∇f(x)‖²))
```
These transitions were able to be inferred from those of `x` and `xs`. Other inner products, such as `⟨x,∇f(xs)⟩`, however, do not appear as states with a transition since at least one component of the inner product is not a state and therefore has no available transition (in this case, the gradient `∇f(xs)`).

Now that all expressions in the problem are scalars in `R`, we can formulate the search for a Lyapunov function that certifies convergence with the given rate. Doing so yields the final semidefinite program:
```@repl
transformed_prob3 = with_parameters(Dict(ρ => 0.81, α => 0.1, μ => 1.0, L => 10.0)) do
    lyapunov_transformation(transformed_prob2)
end
```
While this problem appears quite complex, it is a semidefinite program that is systematically constructed from the transformed problem.

!!! info "Parameters in Lyapunov analysis"
    The Lyapunov transformation requires all expressions to be scalars in `R`. Moreover, the objective function and each constraint must be affine functions of the decision variables (all flattened inner products). Therefore, this transformation must be executed in a scope in which all parameters are specified (the specific values of the parameters are not used, only which leaf variables have a value).

Now that the problem of searching for a Lyapunov certificate of convergence has been formulated as a semidefinite program, we can evaluate it numerically as before:
```@repl
with_numerics(parameters = Dict(ρ => 0.81, α => 0.1, μ => 1.0, L => 10.0)) do
    evaluate(transformed_prob3)
end
```
For this problem, the symbolic simplification process required applying `sector_bounded_interpolation` followed by `gram_transformation` and then `lyapunov_transformation`. Again, this process is automated with `simplify`, which systematically constructs the final semidefinite program directly from the original problem:
```@repl
transformed_prob = with_parameters(Dict(ρ => 0.81, α => 0.1, μ => 1.0, L => 10.0)) do
    simplify(prob)
end;
```
While `certify` constructed the search for a Lyapunov certificate for a particular rate, we often want to compute the fastest (smallest) rate that can be certified. This can be constructed as:
```@repl
opt = rate(con, perf)
```
Evaluating this node performs a bisection search to find the smallest rate for which `certify` is true:
```@repl
with_parameters(Dict(α => 0.1, μ => 1.0, L => 10.0)) do
    evaluate(simplify(opt))
end
```
For more details on this approach to algorithm analysis, see the [Lyapunov analysis](./../manual/lyap.md) section of the manual.
