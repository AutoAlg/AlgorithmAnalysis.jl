# Analysis

We now provide an overview of the analysis techniques using by AlgorithmAnalysis.


## Oracles

The automated analysis methodology applies to *black-box* algorithms, which are algorithms that gain information about the problem only through queries to an oracle that returns information about the queried point [nemirovski-yudin,nesterov-book](@cite). The domain $X$ of the oracle is the space of points at which it can be queried, and the codomain $Y$ is the space of the returned information. When sampled at the same point multiple times, the oracle may return the same value or it may return a different value.

!!! example "Example: First-order oracle"
    A first-order oracle for a differentiable function $f$ has the form $o(x) = (f(x), \nabla f(x))$, where $\nabla f$ is the gradient of $f$.


## Interpolation

The main idea behind both the analysis is to replace all oracles with their *interpolation conditions*. Consider a class $\mathcal{O}$ of oracles, where each oracle in $\mathcal{O}$ is a set-valued function from $X$ to $Y$. Consider also a set of points $S \subset X\times Y$, where each element of $S$ has the form $(x,y)$ with $x\in X$ and $y\in Y$. The interpolation conditions are necessary and sufficient conditions on the set $S$ for there to exist an oracle $o\in\mathcal{O}$ that interpolates the data:
```math
  \text{there exists }o\in\mathcal{O} \text{ such that }y = o(x) \text{ for all }(x,y)\in S.
```

!!! example "Example: Convex interpolation"
    Let $\mathcal{O}$ be the class of first-order oracles for differentiable convex functions from $\mathbb{R}^n$ to $\mathbb{R}$. The domain of the oracle is $X = \mathbb{R}^n$, and the codomain is $Y = \mathbb{R}\times\mathbb{R}^n$. Given a finite set $S = \{(x_i,(f_i,g_i))\}_{i=1}^m$, the interpolation conditions are that [pep](@cite)
    ```math
      f_i \geq f_j + g_j^\top (x_i-x_j) \qquad\text{for all $i,j=1,\ldots,m$}.
    ```
    If these conditions hold, then there exists a differentiable convex function $f : \mathbb{R}^n\to\mathbb{R}$ such that $f_i = f(x_i)$ and $g_i = \nabla f(x_i)$ for all $i=1,\ldots,m$.

!!! example "Example: Gram transformation"
    Consider a set of vectors $x_1,x_2,\ldots,x_m\in\mathbb{R}^n$. Associated with each vector $x_i$, we can define the associated oracle $o_i(x) = x_i^\top x$, which is a linear function from $\mathbb{R}^n$ to $\mathbb{R}$. Evaluating each linear function at each of the vectors yields the scalars $g_{ij} = o_i(x_j) = x_i^\top x_j$. The associated *Gram matrix* is the symmetric matrix of inner products,
    ```math
      G = \begin{bmatrix} g_{11} & g_{12} & \ldots & g_{1m} \\ g_{21} & g_{22} & \ldots & g_{2m} \\ \vdots & \vdots & \ddots & \vdots \\ g_{m1} & g_{m2} & \ldots & g_{mm} \end{bmatrix}.
    ```
    For any set of vectors $x_1,\ldots,x_m\in\mathbb{R}^n$, the Gram matrix is positive semidefinite. Moreover, any positive semidefinite matrix in $\mathbb{R}^{n\times n}$ is the Gram matrix of a set of $m$ vectors, provided that the dimension $n$ is sufficiently large. In particular, the dimension must be at least the rank of the Gram matrix. In other words, the interpolation conditions for the set of oracles $o_1,\ldots,o_m$ evaluated at the points $x_1,\ldots,x_m$ are
    ```math
      G \succeq 0 \qquad\text{and}\qquad n \geq \text{rank}(G).
    ```
    If the dimension $n$ is larger than the number of vectors $m$, then the rank condition is trivially satisfied. Moreover, the analysis can still be used to construct bounds when this "high dimension" assumption fails, although the analysis may not be tight in that case.


## Performance Estimation

A performance estimation problem (PEP) is an optimization problem whose solution characterizes the exact worst-case convergence properties of a black-box algorithm over a finite number of iterations. The PEP methodology was first proposed in [pep-original](@cite) and then refined using interpolation in [pep](@cite). Given an oracle $o$ and initial point $x_0$, a black-box algorithm $A$ constructs a sequence of points $x_1,x_2,\ldots$ as follows:
```math
  \begin{aligned}
    x_1 &= A_0(x_0,o(x_0)), \\
    x_2 &= A_1(x_0,o(x_0),o(x_1)), \\
      &\ \, \vdots \\
    x_{k+1} &= A_k(x_0,o(x_0),\ldots,o(x_k)).
  \end{aligned}
```

!!! tip
    Here we write the algorithm as depending on only a single oracle. It is trivial to extend this to multiple oracles, and AlgorithmAnalysis can analyze algorithms with any number of oracles.

At iteration $k$, the next iterate $x_{k+1}$ is constructed from the initial condition $x_0$ and the oracle applied to all the previous iterates, $o(x_0),\ldots,o(x_k)$. Given an oracle class $\mathcal{O}$, a black-box algorithm $A$, and an initial point $x_0$, a typical PEP has the form
```math
  \begin{aligned}
    \text{maximize} \quad & \text{performance of algorithm $A$ with oracle $o$ over $N$ iterations} \\
    \text{subject to} \quad & o\in\mathcal{O}
  \end{aligned}
```
where the variables are the oracle $o$ and the iterates $x_0,x_1,\ldots,x_N$ of the algorithm. As stated, this problem is often intractable since it requires optimizing over the oracle class $\mathcal{O}$. The key idea is to replace the oracle $o\in\mathcal{O}$ with the interpolation conditions on its inputs $x_1,\ldots,x_N$ and corresponding outputs $y_i = o(x_i)$. In terms of these iterates, the algorithm is
```math
  \begin{aligned}
    x_1 &= A_0(x_0,y_0), \\
    x_2 &= A_1(x_0,y_0,y_1), \\
      &\ \, \vdots \\
    x_{k+1} &= A_k(x_0,y_0,\ldots,y_k).
  \end{aligned}
```
Replacing the oracle with its interpolation conditions then transforms the PEP into the following optimization problem in the data $S = \{(x_i,y_i)\}_{i=1}^N$:
```math
  \begin{aligned}
    \text{maximize} \quad & \text{performance of $S$} \\
    \text{subject to} \quad & \text{$S$ corresponds to iterates generated by algorithm $A$ with oracle $o$} \\
      & \text{$S$ is $\mathcal{O}$-interpolable}
  \end{aligned}
```
The optimal value is the exact worst-case performance after $N$ iterations over the oracle class $\mathcal{O}$. Moreover, this problem is typically *convex* can be solved efficiently, for example, using standard interior point methods [boyd,numerical-optimization](@cite). As the size of the problem grows with the time horizon $N$, the complexity of the analysis grows as well, so the PEP approach is typically only tractable for small $N$.

!!! example "PEP for gradient descent on convex functions"
    Let $\mathcal{F}$ be the class of differentiable convex functions on $\mathbb{R}^n$, and let $o_f$ be the corresponding first-order oracle. Consider applying gradient descent to an objective function $f\in\mathcal{F}$ with initial condition $x_0\in\mathbb{R}^n$ and constant stepsize $\alpha>0$,
    ```math
      x_{k+1} = x_k - \alpha\,\nabla f(x_k).
    ```
    Suppose we want to analyze the worst-case value of the performance measure $f(x_1) - f_*$, where $f_*\in\mathbb{R}$ is the optimal value. To make the problem bounded, we add the contraint $\|x_0 - x_*\|^2 \leq 1$ on the initial condition, where $x_*\in\mathbb{R}^n$ is an optimal point. This specifies that the initial condition is at most a distance of one from an optimal solution. The performance estimation problem for this setup is
    ```math
      \begin{aligned}
        \text{maximize} \quad & f(x_1) - f(x_*) \\
        \text{subject to} \quad & \|x_0 - x_*\|^2 \leq 1 \\
          & \|\nabla f(x_*)\|^2 = 0 \\
          & x_1 = x_0 - \alpha\,\nabla f(x_0) \\
          & f \in \mathcal{F}
      \end{aligned}
    ```
    with variables $x_0,x_1,x_*\in\mathbb{R}^n$ and $f : \mathbb{R}^n\to\mathbb{R}$. This problem is both non-convex and inifinite dimensional. Replacing the convex function $f\in\mathcal{F}$ with the interpolation conditions for convex functions, the problem is equivalent to
    ```math
      \begin{aligned}
        \text{maximize} \quad & f_1 - f_* \\
        \text{subject to} \quad & \|x_0 - x_*\|^2 \leq 1 \\
          & \|g_*\|^2 = 0 \\
          & x_1 = x_0 - \alpha\,g_0 \\
          & f_0 \geq f_1 + g_1^\top (x_0 - x_1) \\
          & f_1 \geq f_0 + g_0^\top (x_1 - x_0) \\
          & f_0 \geq f_* + g_*^\top (x_0 - x_*) \\
          & f_* \geq f_0 + g_0^\top (x_* - x_0) \\
          & f_1 \geq f_* + g_*^\top (x_1 - x_*) \\
          & f_* \geq f_1 + g_1^\top (x_* - x_1)
      \end{aligned}
    ```
    with variables $x_0,x_1,x_*,g_0,g_1,g_*\in\mathbb{R}^n$ and $f_0,f_1,f_*\in\mathbb{R}$. The problem is now finite dimensional but still non-convex. By interpreting the transposed vectors as linear functions and replacing these linear functions (and their inputs) with the interpolation conditions on their Gram matrix, the problem is equivalent to
    ```math
      \begin{aligned}
        \text{maximize} \quad & f_1 - f_* \\
        \text{subject to} \quad & G_{x_0 x_0} - G_{x_0 x_*} - G_{x_* x_0} + G_{x_* x_*} \leq 1 \\
          & G_{x_* x_*} = 0 \\
          & x_1 = x_0 - \alpha\,g_0 \\
          & f_0 \geq f_1 + G_{g_1 x_0} - G_{g_1 x_1} \\
          & f_1 \geq f_0 + G_{g_0 x_1} - G_{g_0 x_0} \\
          & f_0 \geq f_* + G_{g_* x_0} - G_{g_* x_*} \\
          & f_* \geq f_0 + G_{g_0 x_*} - G_{g_0 x_0} \\
          & f_1 \geq f_* + G_{g_* x_1} - G_{g_* x_*} \\
          & f_* \geq f_1 + G_{g_1 x_*} - G_{g_1 x_1} \\
          & G = G^\top \succeq 0 \\
          & \text{rank}(G) \leq n
      \end{aligned}
    ```
    with variables
    ```math
      G = \begin{bmatrix}
        G_{x_0 x_0} & G_{x_0 x_1} & G_{x_0 x_*} & G_{x_0 g_0} G_{x_0 g_1} & G_{x_0 g_*} \\
        G_{x_1 x_0} & G_{x_1 x_1} & G_{x_1 x_*} & G_{x_1 g_0} G_{x_1 g_1} & G_{x_1 g_*} \\
        G_{x_* x_0} & G_{x_* x_1} & G_{x_* x_*} & G_{x_* g_0} G_{x_* g_1} & G_{x_* g_*} \\
        G_{g_0 x_0} & G_{g_0 x_1} & G_{g_0 x_*} & G_{g_0 g_0} G_{g_0 g_1} & G_{g_0 g_*} \\
        G_{g_1 x_0} & G_{g_1 x_1} & G_{g_1 x_*} & G_{g_1 g_0} G_{g_1 g_1} & G_{g_1 g_*} \\
        G_{g_* x_0} & G_{g_* x_1} & G_{g_* x_*} & G_{g_* g_0} G_{g_* g_1} & G_{g_* g_*}
      \end{bmatrix} \in \mathbb{R}^{6\times 6}
    ```
    and
    ```math
      F = \begin{bmatrix} f_0 \\ f_1 \\ f_* \end{bmatrix} \in \mathbb{R}^3.
    ```
    This is a semidefinite program when $n \geq 6$, as the rank constraint is vacuous in that case. Also, the problem can be simplified since the constraint $G_{x_* x_*} = 0$ along with $G\succeq 0$ imply that the corresponding row and column of the Gram matrix must be zero and therefore could be removed from the optimization problem. The Gram matrix is then in $\mathbb{R}^{5\times 5}$, in which case the rank constraint is vacuous if $n\geq 5$.

As the previous example illustrates, the ideas used to transform the PEP into a convex program are quite simple, while the details of doing so can be quite tedious. This is precisely what AlgorithmAnalysis does: it allows users to easily construct the performance estimation problem and then uses these techniques behind the scenes to do the analysis and return the result.

!!! tip "Performance estimation as optimization equivalence"
    The fundamental idea behind performance estimation is the equivalence of two optimization problems involving an oracle and its interpolation conditions. Let $X$ and $Y$ be sets, and consider an oracle class $\mathcal{O}$ with domain $X$ and codomain $Y$, a function $f : X^n\times Y^n\to\mathbb{R}$, and a predicate $c : X^n\times Y^n\to\text{Prop}$, where $\text{Prop}$ is the set of propositions. Consider the following optimization problem
    ```math
      \begin{aligned}
        &\text{maximize} && f(x_1,\ldots,x_n,o(x_1),\ldots,o(x_n)) \\
        &\text{subject to} && c(x_1,\ldots,x_n,o(x_1),\ldots,o(x_n)) \\
        &&& o \in \mathcal{O}
      \end{aligned}
    ```
    with variables $x_1,\ldots,x_n\in X$ and oracle $o\in\mathcal{O}$. By replacing the oracle with its interpolation conditions, this problem is equivalent to
    ```math
      \begin{aligned}
        &\text{maximize} && f(x_1,\ldots,x_n,y_1,\ldots,y_n) \\
        &\text{subject to} && c(x_1,\ldots,x_n,y_1,\ldots,y_n) \\
        &&& \text{$\{(x_1,y_1),\ldots,(x_n,y_n)\}$ is $\mathcal{O}$-interpolable}
      \end{aligned}
    ```
    with variables $x_1,\ldots,x_n\in X$ and $y_1,\ldots,y_n\in Y$. The optimal solutions to each problem are related through the interpolation conditions. The equivalence also holds if the objective function and predicate also depend on additional variables.

## Control Analysis

In the control analysis, we intepret an iterative algorithm as a *dynamical system*. As a system, the iteration $k$ of the algorithm corresponds to (discrete) time. The *state* completely describes the system, or algorithm, at each point in time, and the *dynamics* of the system describe how the state evolves over time.
One of the key differences between the PEP approach and the control approach to algorithm analysis is that, in the control approach, the algorithm has a *state*. The algorithm then describes how this state is updated. For an algorithm $A$ with state $x_k$ at iteration $k$ and oracle $o$, the state is updated according to
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