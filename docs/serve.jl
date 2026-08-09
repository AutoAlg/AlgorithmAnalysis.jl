using Pkg
Pkg.activate(@__DIR__)

using Revise
using OptimizationAlgorithmAnalysis
using LiveServer

src_path = joinpath(@__DIR__, "..", "src")

servedocs(
    include_dirs = [src_path]
)