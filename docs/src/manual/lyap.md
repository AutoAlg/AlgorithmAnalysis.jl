# Lyapunov Analysis

Iterative algorithms can be interpreted as dynamical systems, which can then be analyzed using tools from control theory. With this interpretation, convergence of the algorithm corresponds to stability of the system. We now describe one of the main tools to certify stability of a dynamical system: searching for a Lyapunov function.

!!! info "Implementation in AlgorithmAnalysis.jl"
    This section provides a mathematical description of the Lyapunov approach to algorithm analysis. To see how this approach is implemented in the package, please see the [overview](./../manual/overview.md) section of the manual.

!!! info "Prerequisite"
    The Lyapunov approach to algorithm analysis uses many of the same fundamental techniques as in the performance estimation approach. If you are unfamiliar with that approach, we recommend that you first read the [performance estimation](./../manual/pep.md) section of the manual.


## Algorithms as Dynamical Systems

One of the key differences between the PEP approach and the control approach to algorithm analysis is that, in the control approach, the algorithm is interpreted as a dynamical system which has a *state* that evolves over time [lessard16](@cite). While dynamical systems may evolve in either continuous or discrete time, algorithms are naturally represented as discrete-time systems in which time represents the iteration of the algorithm.

!!! tip "Terminology"
    When interpreting an algorithm as a dynamical system, we may use terminology from either viewpoint. For reference, some related terms are as follows:
    - Algorithm → Dynamical System
    - Iteration → Discrete-time index
    - Iterates → State
    - Convergence → Stability

At each point in time, the state completely describes the system in that it uniquely determines the state at the next iteration. To describe the algorithm, we must therefore describe how the state changes between each iteration. When the update has the same form at each iteration, the system is *time invariant* and we only need to specify the update at some (generic) iteration.

For an algorithm $A$ with state $x_k$ at iteration $k$ and oracle $o$, the state is updated according to
```math
    x_{k+1} = A(x_k,o(x_k)).
```

!!! example "Gradient descent as a dynamical system"
    Gradient descent applied to an objective function $f\in\mathcal{F}$ with initial condition $x_0\in\mathbb{R}^n$ and constant stepsize $\alpha>0$ is
    ```math
        x_{k+1} = x_k - \alpha\,\nabla f(x_k).
    ```
    This is a dynamical system, where the state is the iterate $x_k$, and the oracle is the first-order oracle for the objective function $f$.


## Transforming to Standard Form

Similar to the PEP methodology, given an oracle class $\mathcal{O}$, the main idea is to replace the oracle with its interpolation conditions [taylor2018lyapunov](@cite). The state update then has the form
```math
    x_{k+1} = A(x_k,y_k) \quad\text{subject to}\quad (x_k,y_k) \text{ is $\mathcal{O}$-interpolable}.
```
If we can prove something about this system for any iterates $(x_k,y_k)$ that are $\mathcal{O}$-interpolable, then the result also applies to the original system for any oracle $o\in\mathcal{O}$.

!!! example "Example (continued)"
    Continuing our previous example, suppose the objective function satisfies the sector bound
    ```math
        (\nabla f(x) - \mu x)^\top (\nabla f(x) - L x) \leq 0
    ```
    with parameters $0<\mu<L$ for all $x\in\mathbb{R}^n$. Replacing the oracle with the sector constraint, the algorithm is equivalent to
    ```math
        x_{k+1} = x_k - \alpha\,g_k
    ```
    subject to the constraint
    ```math
        (g_k - \mu x_k)^\top (g_k - L x_k) \leq 0.
    ```
    This is a now a *constrained* dynamical system, where the constraint is quadratic in the state. We can instead interpret this as a dynamical system in terms of the Gram matrix,
    ```math
        G_k = \begin{bmatrix} \|x_k\|^2 & \langle x_k,g_k\rangle \\ \langle g_k,x_k\rangle & \|g_k\|^2 \end{bmatrix} \in \mathbb{R}^{2\times 2}.
    ```
    Not all components of the Gram matrix are parts of the state, as we only have a state update for $x_k$ but not $g_k$. Therefore, the only component of the Gram matrix whose update is known is the top-left component, which evolves over time as
    ```math
        \|x_{k+1}\|^2 = \|x_k - \alpha g_k\|^2 = \|x_k\|^2 - 2 \alpha \langle x_k,g_k\rangle + \alpha^2 \|g_k\|^2.
    ```
    Moreover, in terms of these inner products, the sector constraint is
    ```math
        \|g_k\|^2 - (L+\mu) \langle x_k,g_k\rangle + \mu L \|x_k\|^2 \leq 0.
    ```
    Therefore, we can interpret this as a constrained dynamical system in which the state is the scalar $\|x_k\|^2$ and the remaining components of the Gram matrix, $\langle x_k,g_k\rangle$ and $\|g_k\|^2$, are constrained by the sector constraint.

Motivated by this example, after applying the interpolation conditions and Gram transformation, the algorithm often has the form of a constrained dynamical system in which the dynamics are linear in the (transformed) state $\xi_k$ and some auxiliary variables $u_k$, called the *input*, where the state and input satisfy a constraint:
```math
    \xi_{k+1} = A \xi_k + B u_k \qquad\text{subject to}\qquad (\xi_k,u_k) \in K.
```
Here, $k$ is the iteration index, $\xi_k$ is the state, $u_k$ is the input, and $K$ is the constraint set. We say that this transformed dynamical system is in *standard form*.

!!! example "Example (continued)"
    In our previous example, the state is
    ```math
        \xi_k = \|x_k\|^2,
    ```
    the input is
    ```math
        u_k = \begin{bmatrix} \langle x_k,g_k\rangle \\ \|g_k\|^2 \end{bmatrix},
    ```
    the state-space matrices are
    ```math
        A = 1 \quad\text{and}\quad B = \begin{bmatrix} -2\alpha & \alpha^2 \end{bmatrix},
    ```
    and the constraint set is
    ```math
        K = \{(\xi,u) : u_2 - (L+\mu) u_1 + \mu L \xi \leq 0\}.
    ```

## Searching for a Lyapunov Function

Now that our problem is in standard form, we can formulate the search for a Lyapunov function that certifies convergence. Consider a *performance measure* $P(\xi)$ that depends on the transformed state $\xi$, and a scalar $\rho\in(0,1)$ called the *rate*. Our goal is then to show that the performance measure decreases over time like $\rho^k$.

!!! info "Performance measures"
    For first-order methods, common performance measures are the (squared) distance to the optimizer $\|x-x_\star\|^2$ where $x_\star$ is the optimizer, the (squared) distance to stationarity $\|\nabla f(x)\|^2$, and the optimality gap $f(x) - f(x_\star)$. Each of these performance measures is linear in inner products of the iterates and the scalar function values, which are often the components of the transformed state and input.

To certify convergence, we search for a scalar-valued function $V(\xi)$, called a *Lyapunov function*, that satisfies the following two conditions:

- **Performance condition:** $P(\xi) \leq V(\xi)$ for all $\xi$
- **Decrease condition:** $V(A\xi+Bu) \leq \rho\,V(\xi)$ for all $\xi$ and $u$ in $K$

If there exists such a function $V(x)$, then we have the chain of inequalities:
```math
  P(\xi_k) \leq V(\xi_k) \leq \rho\,V(\xi_{k-1}) \leq \ldots \leq \rho^k\,V(\xi_0).
```
This guarantees that the performance measure $P(\xi_k)$ decreases by some constant factor of $\rho^k$, which establishes convergence to zero when $\rho<1$.

!!! info "Terminology"
    The parameter $\rho$ has various names including the *rate* and the *contraction factor*.

### S-Procedure

The main difficulty in the control analysis is in finding a Lyapunov function. To verify that a function $V(x)$ satisfies the performance and decrease conditions (and is therefore a valid Lyapunov function), we use the fact that the state and input belong to the set $K$.

Recall that the state-input pair $\eta = (\xi,u)$ is constrained to the set $K$. To leverage this fact to search for a Lyapunov function, we will use the *dual cone* of $K$, which is defined as
```math
    K^* = \{\lambda : \langle\lambda,\eta\rangle \geq 0 \text{ for all }\eta\in K\}.
```
The dual $K^*$ is always a convex cone, even when $K$ is neither convex nor a cone. Moreover, the dual cone consists of all elements $\lambda$ whose inner product with any element of $K$ is nonnegative. Since the state-input pair $\eta = (\xi,u)$ belongs to the set $K$, we have the inequality
```math
  \langle \eta, \lambda\rangle \geq 0 \quad\text{for all}\quad \lambda\in K^*.
```
Therefore, if we can find $\lambda\in K^*$ and $\mu\in K^*$, called *multipliers*, such that, for all pairs $\eta = (\xi,u)$,
```math
    P(\xi) \leq V(\xi) - \langle \eta,\lambda\rangle
```
and
```math
    V(A\xi+Bu) \leq \rho\,V(\xi) - \langle \eta,\mu\rangle,
```
then $V(\xi)$ satisfies the performance and decrease conditions and therefore is a Lyapunov function that guarantees convergence of the performance measure with rate $\rho$.

!!! info "S-Procedure"
    Recall that our goal is to find a function $V(x)$ that satisfies the performance and decrease inequalities subject to the constraint that the state-input pair belong to the constraint set. A sufficient condition is that there exist multipliers that satisfy the above two inequalities, where the constraint is replaced by a search over the dual cone. This process is called the *S-procedure*.

### Parameterization of Lyapunov Candidates

The search over multipliers that satisfy the corresponding performance and decrease conditions is still intractable, as the function $V$ is a decision variable. To make the problem tractable, we parameterize a suitable class of functions, in which case the search becomes convex. Suppose the performance measure and Lyapunov function candidates are both linear in the state:
```math
  P(x) = \langle p, x\rangle \quad\text{and}\quad
  V(x) = \langle v, x\rangle
```
for some vectors $p$ and $v$. For the above inequalities to hold for all $\eta = (\xi,u)$, we must have that
```math
  (p,0) = (v,0) - \lambda
```
and
```math
  (A^* v,B^* v) = \rho\,(v,0) - \mu.
```
In other words, if there exist vector $v$ and multipliers $\lambda\in K^*$ and $\mu\in K^*$ that satisfy the above equations, then the performance measure converges at rate $\rho$. These equations are linear in the decision variables, and the multipliers are constrained to a convex cone (the dual cone). Therefore, this is a semidefinite program that can be solved efficiently.


## Iterating a System

As described above, an algorithm evaluates the oracle only once per iteration so that the discrete-time index corresponds to the number of oracle evaluations. For the analysis, however, it is often useful to iterate the system some number of times, say $m$, so that the oracle is evaluated $m$ times each iteration. By iterating the system $m$ times, the transformed state and input become larger, so the computational complexity of the analysis scales with $m$. The benefit of iterating the system, however, is that the transformed state and input involve the original state at multiple time steps, which are then constrained by the interpolation conditions for the oracle. Therefore, increasing $m$ may make the analysis more tight (that is, able to certify a faster rate) at the cost of increased computation.


## References

```@bibliography
Pages = ["lyap.md"]
```
