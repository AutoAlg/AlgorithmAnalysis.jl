using Pkg
Pkg.activate(@__DIR__)

using Revise
using AlgorithmAnalysis # Must be loaded AFTER Revise so Revise can track docstring changes

using LiveServer

# Point include_dirs to the src directory relative to docs/
src_path = joinpath(@__DIR__, "..", "src")

servedocs(
    include_dirs = [src_path]
)