# Workflow

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
using AlgorithmAnalysis
```

After this, you can put any code that you would like to run each time that Julia starts from within the package directory. When you edit a file in the package, Revise will attempt to recompile the relevant code automatically. If Revise fails, you will need to restart Julia for the changes to take effect (which is why it is helpful to have certain code run whenever Julia is restarted).

This startup file can now be easily executed with the following command (in the main project directory):
```zsh
julia --project=.
``` 
