cd("S:\\Research Material\\CSE\\MU\\Project\\AlgorithmAnalysis.jl\\src\\precompilation\\")

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