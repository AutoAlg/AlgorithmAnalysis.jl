# Documentation

To construct the documentation, run:

```sh
julia --project=docs/ -e 'using Pkg; Pkg.instantiate(); include("docs/make.jl")'
```