# Developer Guide

We encourage researchers that present novel algorithms, analysis, and/or design techniques to submit a pull request.


## Workflow

To develop the package, it is recommended to put the following code in the file `~/.julia/config/startup.jl`:
```julia
cd("/path_to_package_directory/")
using Pkg
Pkg.activate(".")
using Revise
using BlackBoxOptimization
```

## Building the documentation

In a terminal, navigate to the module's main directory (for example, `~/.julia/dev/BlackBoxOptimization/`) and run:
```console
julia --startup-file=no --project=docs/ -e "using Pkg; Pkg.develop(PackageSpec(path=pwd())); Pkg.instantiate()"
julia --startup-file=no --project=docs/ docs/make.jl
```

To view the documentation in a browser, from the same directory run:
```console
julia -e "using LiveServer; serve(dir=\"docs/build\")"
```


## Precompilation

For faster compilation times, you can build a custom system image as follows.

```julia
using PackageCompiler
PackageCompiler.create_sysimage(
    [
        :Convex,
        :SCS,
        :LinearAlgebra,
    ];
    sysimage_path = "image.so",
)
```

Then start Julia with the -J flag pointing to the system image that was created, [see here for details](https://julialang.github.io/PackageCompiler.jl/dev/sysimages.html#Creating-a-sysimage-using-PackageCompiler). To have VSCode automatically load this system image, add the following to `settings.json`:

```json
"julia.additionalArgs": [
    "-Jpath_to_image.so"
],
"editor.rulers": [92]
```
