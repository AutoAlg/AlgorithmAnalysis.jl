# Internal API

This page lists the internal API of AlgorithmAnalysis.jl. This documentation exists to help developers. While these methods may be used by other users, they are considered internal and therefore subject to change at any time.

!!! note
    As these symbols are internal API, they are not exported. Therefore, to use them outside of the package you must prefix the name with `AlgorithmAnalysis.<NAME>`.

## Symbols

```@docs
AlgorithmAnalysis.extract_symbols
AlgorithmAnalysis.get_safe_symbol
AlgorithmAnalysis.is_safe
```

## AST

```@docs
AlgorithmAnalysis.Node
AlgorithmAnalysis.replace_node
AlgorithmAnalysis.find_nodes
AlgorithmAnalysis.rewrite
AlgorithmAnalysis.find_evaluation_points
AlgorithmAnalysis.postwalk_with_operators
AlgorithmAnalysis.remove_transitions
AlgorithmAnalysis.propagate_and_remove_transitions
```

## Transitions

```@docs
AlgorithmAnalysis.transitions
AlgorithmAnalysis.apply_transition
```

## Numerics

```@docs
AlgorithmAnalysis.model
AlgorithmAnalysis.instantiate_in_model
AlgorithmAnalysis.hasvalue
AlgorithmAnalysis.value
```

## Miscellaneous

```@docs
AlgorithmAnalysis.from_matrix
AlgorithmAnalysis.bsmin
AlgorithmAnalysis.s_procedure
AlgorithmAnalysis.multiplier
```
