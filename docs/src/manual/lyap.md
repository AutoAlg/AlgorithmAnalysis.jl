# Lyapunov Analysis

In the control analysis, we intepret an iterative algorithm as a *dynamical system*. As a system, the iteration $k$ of the algorithm corresponds to (discrete) time. The *state* completely describes the system, or algorithm, at each point in time, and the *dynamics* of the system describe how the state evolves over time. One of the key differences between the PEP approach and the control approach to algorithm analysis is that, in the control approach, the algorithm has a *state*. The algorithm then describes how this state is updated. For an algorithm $A$ with state $x_k$ at iteration $k$ and oracle $o$, the state is updated according to
```math
  x_{k+1} = A(x_k,o(x_k)).
```

!!! example "Gradient descent as a dynamical system"
    Gradient descent applied to an objective function $f\in\mathcal{F}$ with initial condition $x_0\in\mathbb{R}^n$ and constant stepsize $\alpha>0$ is
    ```math
      x_{k+1} = x_k - \alpha\,\nabla f(x_k).
    ```
    This is a dynamical system, where the state is the iterate $x_k$, and the oracle is the first-order oracle for the objective function $f$.

Similar to the PEP methodology, given an oracle class $\mathcal{O}$, the main idea is to replace the oracle with its interpolation conditions. Let $y_k = o(x_k)$ denote the output of the oracle at iteration $k$. The state update then has the form
```math
  x_{k+1} = A(x_k,y_k) \qquad\text{subject to}\qquad (x_k,y_k)\text{ is $\mathcal{O}$-interpolable}.
```
If we can prove something about this system for any iterates $(x_k,y_k)$ that are $\mathcal{O}$-interpolable, then the result also applies to the original system for any oracle $o\in\mathcal{O}$.

!!! example
    Continuing our previous example, suppose the objective function is convex. Applying the convex interpolation conditions, the algorithm is equivalent to
    ```math
      x_{k+1} = x_k - \alpha\,g_k \qquad\text{subject to}\qquad (x_k,(f_k,g_k)).
    ```
    This is a dynamical system, where the state is the iterate $x_k$, and the oracle is the first-order oracle for the objective function $f$.

```math
  x_{k+1} = A x_k + B u_k \qquad\text{subject to}\qquad (x_k,u_k) \in K.
```
Here, $k$ is the iteration index, $x_k$ is the state, $u_k$ is the input, and $K$ is the interpolation cone. The control approach searches for a *Lyapunov function* $V(x)$ that satisfies the following conditions:

- **Performance condition:** $P(x) \leq V(x)$ for all $x$
- **Decrease condition:** $V(Ax+Bu) \leq \rho\,V(x)$ for all $x$ and $u$ in $K$

The parameter $\rho\in(0,1)$ is the *rate*, which specifies how quickly the performance measure decreases. If there exists such a function $V(x)$, then we have the chain of inequalities:
```math
  P(x_k) \leq V(x_k) \leq \rho\,V(x_{k-1}) \leq \ldots \leq \rho^k\,V(x_0).
```
This guarantees that the performance measure $P(x_k)$ decreases by $O(\rho^k)$.

The main difficulty in the control analysis is in finding a Lyapunov function. To show that this performance measure and Lyapunov function candidate satisfy the performance and decrease conditions, we use the fact that the state and input belong to the interpolation cone. Consider the *dual* of the interpolation cone,
```math
  K^* = \{\lambda : 0\leq\langle\lambda,\xi\rangle \text{ for all }\xi\in K\}.
```
The dual $K^*$ is always a convex cone (even when $K$ is not convex) and precisely characterizes all quantities $\lambda$ whose inner product with any element of the cone is nonnegative. Since the state-input pair $\xi_k = (x_k,u_k)$ belongs to the cone $K$, we have the inequality
```math
  0 \leq \langle \xi_k, \lambda_k\rangle \qquad\text{for all}\qquad \lambda_k\in K^*.
```
Therefore, if we can find $\lambda\in K^*$ and $\mu\in K^*$, called *multipliers*, such that, for all pairs $\xi = (x,u)$,
```math
  P(x) \leq V(x) - \langle \xi,\lambda\rangle
```
and
```math
  V(Ax+Bu) \leq \rho\,V(x) - \langle \xi,\mu\rangle,
```
then $V(x)$ satisfies the performance and decrease conditions are therefore is a Lyapunov function that guarantees convergence of the performance measure with rate $\rho$.

By parameterizing a suitable class of functions, the search can be made convex. Suppose the performance measure and Lyapunov function candidates are both linear in the state:
```math
  P(x) = \langle p, x\rangle \qquad\text{and}\qquad
  V(x) = \langle v, x\rangle
```
for some vectors $p$ and $v$. The above inequalities are then equivalent to
```math
  (p,0) = (v,0) - \lambda
```
and
```math
  (A^* v,B^* v) = \rho\,(v,0) - \mu.
```
In other words, if there exist vector $v$ and multipliers $\lambda\in K^*$ and $\mu\in K^*$ that satisfy the above equations, then the performance measure converges at rate $\rho$.

In the current implementation, `certify(trans, oracle_con, perf, rate)` is treated as a fixed-rate feasibility problem. After interpolation and Gram transformation, the tool introduces scalar certificate variables and nonnegative multipliers for inequality constraints, then enforces affine coefficient-matching constraints corresponding to
```math
  V(x) \ge P(x), \qquad V(x^+) \le \rho V(x).
```
This gives an automated certificate search in the transformed scalar space.


## Comparison of Approaches

There are two main approaches to automated algorithm analysis: the *performance estimation problem* (PEP) approach from the optimization community and *integral quadratic constraints* (IQCs) from the control community.

The PEP approach formulates the automated analysis as the problem of finding the sequence of iterates and the optimization problem for which a given algorithm attains its worst-case behavior in terms of a specified measure of performance over some finite number of iterations [drori-teboulle](@cite). While this optimization problem involves searching over an infinite-dimensional class of functions, it can be convexified by replacing the search over the function itself with constraints on the iterates such that there exists some function in the class that interpolates the points, along with a large-scale asumption on the dimension of the underlying domain of the optimization problem [pep](@cite). While the PEP approach constructs provably tight bounds on the iterates of the algorithm, it can do so only over finite time horizons. Furthermore, the complexity of the analysis scales with the number of iterations, so the analysis is only computationally tractable for up to a few hundred iterations.

In contrast, the IQC approach interprets an optimization algorithm as a dynamical system [lessard16](@cite). Similar to the PEP approach, the ``uncertainty'' (such as the gradient of the objective function for first-order methods) is replaced by constraints between its inputs and outputs (the term *integral quadratic constraint* comes from the fact that these constraints are often sums of quadratic forms, and the sums become integrals for continuous-time systems). These constraints are then used to search for a parameterized Lyapunov function whose existence is a certificate of convergence [taylor2018lyapunov](@cite). This approach solves small semidefinite programs to produce bounds on the iterates of the algorithm that hold over any number of iterations. These bounds are tight in that, if a Lyapunov function of the parameterized form exists, this technique will find it [taylor2018lyapunov](@cite). But there is in general no guarantee of such systems having a Lyapunov function of a particular form, so in general the convergence bounds may not be tight.

These approaches have been applied to a variety of algorithm forms such as fixed-step first-order methods [pep](@cite), Nesterov's accelerated method [hu-lessard2017](@cite), the alternating direction method of multipliers (ADMM) [admm,iqcadmm_ICML](@cite), Markov jump linear systems [hu-syed2019](@cite), inexact gradient and Newton methods [deklerk-glineur-taylor2020](@cite), and decentralized methods [colla-hendrickx2023](@cite) among others.

While the convergence properties of an algorithm depend on the specific objective function $f$, algorithms are typically designed and analyzed for an entire class of functions $\mathcal{F}$. In this case, the goal may be to characterize the *worst-case* performance of the algorithm over any objective function in the class [rmm](@cite), or to characterize the distribution of the performance over all problems in the class (such as *average-case* performance [robey-chamon-pappas-hassani2022](@cite)).

The IQC and PEP approaches to automated algorithm analysis are related: they are *dual* problems of each other [taylor2018lyapunov](@cite). This insight has numerous benefits. For instance, IQCs can be derived directly from the interpolation conditions for a class of uncertainties, which provides a systematic method to construct IQCs as well as theoretical guarantees about the tightness of the constraints and the resulting analysis. Similar to the PEP approach, the IQC analysis extends in a straightforward manner to include \textit{function values}. When the uncertainty is the gradient of a function, $\Delta = \nabla f$, we can include the function values $f(y_t)$ in the analysis to handle function classes that are defined by inequalities involving them, such as quadratic growth which is defined by the inequality $f(x) \geq \frac{\mu}{2} \|x\|^2$ for all $x$. In either case, the analysis consists of solving a convex semidefinite program for which efficient solvers [mosek,cosmo,scs](@cite) and modeling languages [yalmip,cvx1,cvx2](@cite) are readily available.


## References

```@bibliography
```