# Internal API

This page lists the internal API of AlgorithmAnalysis.jl. This documentation exists to help developers. While these methods may be used other users, they are considered internal and therefore subject to change at any time.

## Symbols

```@docs
AlgorithmAnalysis.extract_symbols
AlgorithmAnalysis.get_safe_symbol
AlgorithmAnalysis.is_safe
```

## AST

```@docs
AlgorithmAnalysis.Node
AlgorithmAnalysis.leaves
AlgorithmAnalysis.replace_node
AlgorithmAnalysis.find_nodes
AlgorithmAnalysis.rewrite
AlgorithmAnalysis.find_evaluation_points
AlgorithmAnalysis.postwalk_with_operators
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
