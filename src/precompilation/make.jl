cd("C:\\Users\\vanscob\\.julia\\dev\\BlackBoxOptimization")

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