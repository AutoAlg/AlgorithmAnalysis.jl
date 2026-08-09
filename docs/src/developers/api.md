# Internal API

This page lists the internal API of OptimizationAlgorithmAnalysis.jl. This documentation exists to help developers. While these methods may be used by other users, they are considered internal and therefore subject to change at any time.

!!! note
    As these symbols are internal API, they are not exported. Therefore, to use them outside of the package you must prefix the name with `OptimizationAlgorithmAnalysis.<NAME>`.

## Symbols

```@docs
OptimizationAlgorithmAnalysis.extract_symbols
OptimizationAlgorithmAnalysis.get_safe_symbol
OptimizationAlgorithmAnalysis.is_safe
```

## AST

```@docs
OptimizationAlgorithmAnalysis.Node
OptimizationAlgorithmAnalysis.replace_node
OptimizationAlgorithmAnalysis.find_nodes
OptimizationAlgorithmAnalysis.rewrite
OptimizationAlgorithmAnalysis.find_evaluation_points
OptimizationAlgorithmAnalysis.postwalk_with_operators
OptimizationAlgorithmAnalysis.remove_transitions
OptimizationAlgorithmAnalysis.propagate_and_remove_transitions
```

## Transitions

```@docs
OptimizationAlgorithmAnalysis.transitions
OptimizationAlgorithmAnalysis.apply_transition
```

## Numerics

```@docs
OptimizationAlgorithmAnalysis.model
OptimizationAlgorithmAnalysis.instantiate_in_model
OptimizationAlgorithmAnalysis.hasvalue
OptimizationAlgorithmAnalysis.value
```

## Miscellaneous

```@docs
OptimizationAlgorithmAnalysis.from_matrix
OptimizationAlgorithmAnalysis.bsmin
OptimizationAlgorithmAnalysis.s_procedure
OptimizationAlgorithmAnalysis.multiplier
```
