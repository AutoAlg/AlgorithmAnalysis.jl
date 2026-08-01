# Developer Guide

We encourage researchers that present novel algorithms, analyses, and/or design techniques to submit a pull request.


## Workflow

To develop the package, it is recommended to put the following code in the file `~/.julia/config/startup.jl`:
```julia
using Revise
startup_jl = joinpath(dirname(Base.active_project()), "startup.jl")
if isfile(startup_jl)
    includet(startup_jl)
end
```

Then in the package's main directory, create the file `startup.jl` with the following:
```julia
using Pkg
Pkg.activate(".")
using Revise
```

After this, you can put any code that you would like to run each time that Julia starts from within the package directory. When you edit a file in the package, Revise will attempt to recompile the relevant code automatically. If Revise fails, you will need to restart Julia for the changes to take effect (which is why it is helpful to have certain code run whenever Julia is restarted).

This startup file can now be easily executed with the following command (in the AlgorithmAnalysis.jl directory):
```zsh
julia --project=.
``` 

## Building the documentation

In a terminal, navigate to the package's main directory and run:
```console
julia --project=docs/ docs/make.jl
```

To view the documentation in a browser, from the same directory run:
```console
julia --project=docs/ docs/serve.jl
```
or just run
```julia
using AlgorithmAnalysis, LiveServer
servedocs()
```
in Julia from the project's main folder.

## Creating new documentation and tests

In Installation some documentation is written manually while some is automatically generated. All documentation under the Installation, Developer Guide, Manual, and API sections is manually written.

Meanwhile, documentation for Results is automatically generated based off of an internal file format. This file format can be seen in full in the project's source under `src/results/gradient_descent.jl`. However, for completeness sake, it will be detailed here.

The purpose of these special julia files is to have a single source of truth from which consistent and readable tests and documentation are produced. This means these files must be interpretable by both julia's unit testing framework and julia's documentation framework. 

On the testing side, this means producing a list of function pointers which can be invoked in a standard `@testset` block and, on the documentation side, producing a file with a title, description (which may contain latex), a list of tests complete with their own title and code, and finally a list of references.

Now that one understands the purpose of these files, we can discuss their format. In julia, when one executes the [`Base.include`](@extref JuliaBaseDocumentation Base.include) function, the value of the last expression in the file is returned from that expression. We use this such that each file produces a TestFileDescriptor object which internally is processed into a ResultFile which can be used by either the documentation or testing frameworks.

This TestFileDescriptor structure has a number of fields that must be filled out which represent the entire structure. Of note to developers is that each of these files are executed in a separate and isolated julia module.
