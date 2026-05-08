cd("C:\\Users\\nlam1\\.julia\\dev\\BlackBoxOptimization.jl")

using PackageCompiler

PackageCompiler.create_sysimage(
    [
        :Convex,
        :SCS,
        :LinearAlgebra,
        # :InteractiveUtils,
        :AbstractTrees,
        :Zeros,
        :Revise,
    ];
    sysimage_path = "image.so",
)