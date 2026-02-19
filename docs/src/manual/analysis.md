# Analysis

Mathematically, optimization problems are modeled as minimizing a function subject to constraints. The automated analysis methodology applies to black-box algorithms, which obtain information about the objective function only through queries to an oracle that returns information about the queried point [nemirovski-yudin,nesterov-book](@cite).

!!! example "Example: First-order oracle"
    A first-order oracle for a differentiable function $f$ has the form $o(x) = (f(x), \nabla f(x))$, where $\nabla f$ is the gradient of $f$.

## Key Ideas

There are several key ideas that are common to both types of analysis. We now describe the main ideas behind the PEP and IQC approaches to worst-case automated algorithm analysis on the unconstrained optimization problem of minimizing an objective function $f$ in a class $\mathcal{F}$ of (differentiable) functions.

### Interpolation

The first main idea in the analysis is to replace all oracles with their *interpolation conditions*. Consider a class $\mathcal{O}$ of oracles, where each oracle in $\mathcal{O}$ is a set-valued function from $X$ to $Y$. Consider also a set of points $S \subset X\times Y$, where each element of $S$ has the form $(x,y)$ with $x\in X$ and $y\in Y$. The interpolation conditions are necessary and sufficient conditions on the set $S$ for there to exist an oracle $o\in\mathcal{O}$ that interpolates the data:
```math
  \text{there exists }o\in\mathcal{O} \text{ such that }y = o(x) \text{ for all }(x,y)\in S.
```
For an algorithm involving an oracle $o\in\mathcal{O}$, its worst-case performance is equivalent to that of its iterates subject to the interpolation conditions. We can therefore replace the oracle with its interpolation conditions in the analysis.

!!! example "Example: Convex interpolation"
    Let $\mathcal{O}$ be the class of first-order oracles for differentiable convex functions from $\mathbb{R}^n$ to $\mathbb{R}$. The domain of the oracle is $X = \mathbb{R}^n$, and the codomain is $Y = \mathbb{R}\times\mathbb{R}^n$. Given a finite set $S = \{x_i,(f_i,g_i)\}$, the interpolation conditions are that [pep](@cite)
    ```math
      f_i \geq f_j + g_j^\top ( y_i-y_j) \qquad\text{for all $i$ and $j$}.
    ```
    If these conditions hold, then there exists a convex function $f : \mathbb{R}^n\to\mathbb{R}$ such that $f_i = f(x_i)$ and $g_i = \nabla f(x_i)$ for all $i$.

!!! example "Example: Gram transformation"
    Consider a set of vectors $x_1,x_2,\ldots,x_n\in X$, where $X$ is a vector space with inner product $\langle\cdot,\cdot\rangle$. 

### Gram Transformation

The second main idea behind the analysis is that, for first-order oracles, the problem is convex in the Gram matrix of inner products and the vector of function values,
```math
  G = \begin{bmatrix} \langle y_0, g_0\rangle & \langle y_0, g_1\rangle & \ldots & \langle y_0,g_N\rangle \\ \langle y_1, g_0\rangle & \langle y_1, g_1\rangle & \ldots & \langle y_1,g_N\rangle \\ \vdots & \vdots & \ddots & \vdots \\ \langle y_N,g_0\rangle & \langle y_N,g_1\rangle & \ldots & \langle y_N,g_N\rangle \end{bmatrix}
  \quad\text{and}\quad
  F = \begin{bmatrix} f_0 \\ f_1 \\ \vdots \\ f_N \end{bmatrix}.
```
The Gram matrix is positive semidefinite for any set of iterates. Moreover, any positive semidefinite matrix is the Gram matrix of a set of iterates, provided that the dimension of the space in which the iterates belong is sufficiently large. In particular, the dimension must be at least the rank of the Gram matrix. The analysis can still be used to construct bounds when this "high dimension" assumption fails, but the analysis may not be tight in that case.

## Types of Analysis

There are two main approaches to automated algorithm analysis: the *performance estimation problem* (PEP) approach from the optimization community and *integral quadratic constraints* (IQCs) from the control community.

The PEP approach formulates the automated analysis as the problem of finding the sequence of iterates and the optimization problem for which a given algorithm attains its worst-case behavior in terms of a specified measure of performance over some finite number of iterations [drori-teboulle](@cite). While this optimization problem involves searching over an infinite-dimensional class of functions, it can be convexified by replacing the search over the function itself with constraints on the iterates such that there exists some function in the class that interpolates the points, along with a large-scale asumption on the dimension of the underlying domain of the optimization problem [pep](@cite). While the PEP approach constructs provably tight bounds on the iterates of the algorithm, it can do so only over finite time horizons. Furthermore, the complexity of the analysis scales with the number of iterations, so the analysis is only computationally tractable for up to a few hundred iterations.

In contrast, the IQC approach interprets an optimization algorithm as a dynamical system [lessard16](@cite). Similar to the PEP approach, the ``uncertainty'' (such as the gradient of the objective function for first-order methods) is replaced by constraints between its inputs and outputs (the term *integral quadratic constraint* comes from the fact that these constraints are often sums of quadratic forms, and the sums become integrals for continuous-time systems). These constraints are then used to search for a parameterized Lyapunov function whose existence is a certificate of convergence [taylor2018lyapunov](@cite). This approach solves small semidefinite programs to produce bounds on the iterates of the algorithm that hold over any number of iterations. These bounds are tight in that, if a Lyapunov function of the parameterized form exists, this technique will find it [taylor2018lyapunov](@cite). But there is in general no guarantee of such systems having a Lyapunov function of a particular form, so in general the convergence bounds may not be tight.

These approaches have been applied to a variety of algorithm forms such as fixed-step first-order methods [pep](@cite), Nesterov's accelerated method [hu-lessard2017](@cite), the alternating direction method of multipliers (ADMM) [admm,iqcadmm_ICML](@cite), Markov jump linear systems [hu-syed2019](@cite), inexact gradient and Newton methods [deklerk-glineur-taylor2020](@cite), and decentralized methods [colla-hendrickx2023](@cite) among others.

While the convergence properties of an algorithm depend on the specific objective function $f$, algorithms are typically designed and analyzed for an entire class of functions $\mathcal{F}$. In this case, the goal may be to characterize the *worst-case* performance of the algorithm over any objective function in the class [rmm](@cite), or to characterize the distribution of the performance over all problems in the class (such as *average-case* performance [robey-chamon-pappas-hassani2022](@cite)).

### Performance Estimation

A performance estimation problem (PEP) is an optimization problem whose solution characterizes the exact worst-case convergence properties of a black-box algorithm over a finite number of iterations [pep-original,pep](@cite). Given an oracle $O_f$ and initial point $y_0$, a black-box method $M$ constructs a sequence of points $y_1,y_2,\ldots$ as follows:
```math
  \begin{aligned}
    y_1 &= M_0(y_0,O_f(y_0)), \\
    y_2 &= M_1(y_0,O_f(y_0),O_f(u_1)), \\
      &\ \, \vdots \\
    y_{k+1} &= M_k(y_0,O_f(y_0),\ldots,O_f(y_k)).
  \end{aligned}
```
At iteration $k$, the next iterate $y_{k+1}$ is constructed from the initial condition $y_0$ and the oracle applied to all the previous iterates, $O_f(y_0),\ldots,O_f(y_k)$. Given a function class $\mathcal{F}$, a black-box algorithm $M$, and an initial point $y_0$, a typical PEP has the form
```math
  \begin{aligned}
    \text{maximize} \quad & \text{performance of algorithm $M$ with oracle $O_f$ over $N$ iterations} \\
    \text{subject to} \quad & f\in\mathcal{F}
  \end{aligned}
```
where the variables are the function $f$ and the iterates of the algorithm. As stated, this problem is intractible since it requires optimizing over the function class $\mathcal{F}$. The PEP is still nonconvex since the performance measure and interpolation conditions are typically nonconvex in the iterates. If the dimension of the iterates is sufficiently large, then the PEP can be formulated in terms of the Gram matrix and function values as the following \textit{convex} optimization problem:
```math
  \begin{aligned}
    \text{maximize} \quad & \text{performance of $(G,F)$ over $N$ iterations} \\
    \text{subject to} \quad & \text{$(G,F)$ corresponds to iterates generated by algorithm $M$ with oracle $O_f$} \\
      & \text{$(G,F)$ is $\mathcal{F}$-interpolable}
  \end{aligned}
```
This problem can be solved efficiently, for example, using standard interior point methods [boyd,numerical-optimization](@cite). The optimal value is the exact worst-case performance after $N$ iterations over the function class $\mathcal{F}$. As the size of the problem grows with the time horizon $N$, the complexity of the analysis grows as well, so the PEP approach is typically only tractible for up to a few hundred iterations.


### Control Analysis

One of the key differences between the PEP approach and the control approach to algorithm analysis is that, in the control approach, the algorithm has a *state*. The algorithm then describes how this state is updated. Using the interpolation conditions and Gram transformation, the state update has the form
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
  (p,0) = (v,0) - \lambda \qquad\text{and}\qquad (A^* v,B^* v) = \rho\,(v,0) - \mu.
```
In other words, if there exist vector $v$ and multipliers $\lambda\in K^*$ and $\mu\in K^*$ that satisfy the above equations, then the performance measure converges at rate $\rho$.

!!! result "Control Analysis"
    Consider the dynamics
    ```math
        x_{k+1} = A x_k + B u_k \qquad\text{subject to}\qquad (x_k,u_k)\in K.
    ```
    If there exist a vector $v$ and multipliers $\lambda,\mu\in K^*$ such that
    ```math
      (p,0) = (v,0) - \lambda \qquad\text{and}\qquad (A^* v,B^* v) = \rho\,(v,0) - \mu,
    ```
    then $V(x) = \langle v,x\rangle$ is a Lyapunov function that certifies that the performance measure $P(x) = \langle p,x\rangle$ converges at rate $O(\rho^k)$.

### Comparison of Approaches

The IQC and PEP approaches to automated algorithm analysis are related: they are *dual* problems of each other [taylor2018lyapunov](@cite). This insight has numerous benefits. For instance, IQCs can be derived directly from the interpolation conditions for a class of uncertainties, which provides a systematic method to construct IQCs as well as theoretical guarantees about the tightness of the constraints and the resulting analysis. Similar to the PEP approach, the IQC analysis extends in a straightforward manner to include \textit{function values}. When the uncertainty is the gradient of a function, $\Delta = \nabla f$, we can include the function values $f(y_t)$ in the analysis to handle function classes that are defined by inequalities involving them, such as quadratic growth which is defined by the inequality $f(x) \geq \frac{\mu}{2} \|x\|^2$ for all $x$. In either case, the analysis consists of solving a convex semidefinite program for which efficient solvers [mosek,cosmo,scs](@cite) and modeling languages [yalmip,cvx1,cvx2](@cite) are readily available.


## References

```@bibliography
```