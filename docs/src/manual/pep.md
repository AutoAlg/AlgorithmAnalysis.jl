# Performance Estimation

We now provide an overview of the performance estimation problem (PEP) approach to algorithm analysis. The PEP approach formulates the problem of finding the sequence of iterates and the problem instance for which a given algorithm attains its worst-case behavior in terms of a specified measure of performance over some finite number of iterations [drori-teboulle,pep](@cite).

!!! info "Implementation in AlgorithmAnalysis.jl"
    This section provides a mathematical description of the PEP approach to algorithm analysis. To see how this approach is implemented in the package, please see the [overview](./../manual/overview.md) section of the manual.


## Oracles

The automated analysis methodology applies to *black-box* algorithms, which are algorithms that gain information about the problem only through queries to an oracle that returns information about the queried point [nemirovski-yudin,nesterov-book](@cite). The domain $X$ of the oracle is the space of points at which it can be queried, and the codomain $Y$ is the space of the returned information. When sampled at the same point multiple times, the oracle may return the same value or it may return a different value.

!!! example "Example: First-order oracle"
    A first-order oracle for a differentiable function $f$ has the form $o(x) = (f(x), \nabla f(x))$, where $\nabla f$ is the gradient of $f$.


## Interpolation

The main idea behind both the analysis is to replace all oracles with their *interpolation conditions* [pep](@cite). Consider a class $\mathcal{O}$ of oracles, where each oracle in $\mathcal{O}$ is a set-valued function from $X$ to $Y$. Consider also a set of points $S \subset X\times Y$, where each element of $S$ has the form $(x,y)$ with $x\in X$ and $y\in Y$. The interpolation conditions are necessary and sufficient conditions on the set $S$ for there to exist an oracle $o\in\mathcal{O}$ that interpolates the data:
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


## References

```@bibliography
Pages = ["pep.md"]
```
