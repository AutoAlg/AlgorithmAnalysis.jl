# AlgorithmAnalysis.jl Manual

The package implements 2 analysis frameworks: the Lyapunov-based approach developed by Van Scoy and Lessard, and the performance estimation approach, developed by Drori and Teboulle and implemented in the Pepit Python library.

# When to use AlgorithmAnalysis.jl

AlgorithmAnalysis.jl finds a worst-case performance guarantee for a first-order algorithm at optimizing a function class supported by the package.

# How to use AlgorithmAnalysis.jl

After installing AlgorithmAnalysis.jl, you should be able to run
```julia
using AlgorithmAnalysis
```
to use the package in Julia.

The package can automatically perform analysis when given the function class, the first-order algorithm, and the performance measure the worst-case convergence rate of which you are analyzing for. You can define the input inside the provided label macro which simplify using the package.

```julia
@algorithm begin
end
```

Every command between this point and when the analysis process is started is called inside the label macro.

You can provide the first input by declaring a function in a vector space and its class:
```julia
f = DifferentiableFunctional{Rⁿ}()
```

```julia
f ∈ SmoothStronglyConvex(m, L)
```

You can define the algorithm you wish to analyze by creating the global minimizer, the initial point(s), and the algorithm's update rule.

```julia
xs = first_order_stationary_point(f)
x0 = Rⁿ()
x1 = x0 - 0.2*f'(x0)
x0 => x1
```

You must define a performance measure:

```julia
performance = (x0-xs)^2
```

Finally, you can call the 'rate' function for Lyapunov-based analysis or 'certify' function for PEP analysis outside of the label macro, which automatically finds every input through the performance measure as the only argument:

```julia
@show rate(performance)
```

A worst-case convergence rate guarantee between 0 and 1 is returned once the analysis is completed.