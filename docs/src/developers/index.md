# Developer Guide

We encourage researchers that present novel algorithms, analysis, and/or design techniques to submit a pull request.


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
