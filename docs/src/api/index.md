# API

This page lists the public API of AlgorithmAnalysis.jl. For an introduction to the package, please see the [Manual](./../manual/overview.md).

## Spaces

### Propositions

```@docs
Prop
∧
```

### Reals

```@docs
R
```

### Vector spaces

```@docs
Rⁿ
Sⁿ
⪯
⪰
```

### Function spaces

```@docs
functional
differentiable_functional
```

## Algorithms

```@docs
@alg
```

## Symbolics

```@docs
simplify
→
```

## Numerics

```@docs
evaluate
with_numerics
with_parameters
with_additional_parameters
```

## Optimization

```@docs
minimize
maximize
feasible
```

## Lyapunov certificates

```@docs
certify
rate
```

## Transformations

```@docs
convex_interpolation
smooth_convex_interpolation
sector_bounded_interpolation
gram_transformation
lyapunov_transformation
```

## Miscellaneous

```@docs
with_verbose
```
