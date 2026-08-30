# Documentation


## Building the documentation

In a terminal, navigate to the package's main directory and run:
```console
julia --project=docs/ docs/make.jl
```

To view the documentation in a browser, from the same directory run:
```console
julia --project=docs/ docs/serve.jl
```


## Creating new documentation and tests

Some documentation is written manually while some is automatically generated. All documentation under the Introduction, Manual, API, and Developer Guide sections is manually written. Meanwhile, documentation for Results is automatically generated based on an internal file format. This file format can be seen in full in the project's source under `src/results/gradient_descent.jl`. However, for completeness sake, it will be detailed here.

The purpose of these special julia files is to have a single source of truth from which consistent and readable tests and documentation are produced. This means these files must be interpretable by both Julia's unit testing framework and Julia's documentation framework. 

On the testing side, this means producing a list of function pointers which can be invoked in a standard `@testset` block and, on the documentation side, producing a file with a title, description (which may contain latex), a list of tests complete with their own title and code, and finally a list of references.

Now that one understands the purpose of these files, we can discuss their format. In Julia, when one executes the [`Base.include`](@extref JuliaBaseDocumentation Base.include) function, the value of the last expression in the file is returned from that expression. We use this such that each file produces a `TestFileDescriptor` object which internally is processed into a `ResultFile` which can be used by either the documentation or testing frameworks.

This `TestFileDescriptor` structure has a number of fields that must be filled out which represent the entire structure. Of note to developers is that each of these files are executed in a separate and isolated Julia module.
