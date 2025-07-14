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


## Building the documentation

In a terminal, navigate to the package's main directory and run:
```console
julia --project=docs/ docs/make.jl
```

To view the documentation in a browser, from the same directory run:
```console
julia --project=docs/ docs/serve.jl
```