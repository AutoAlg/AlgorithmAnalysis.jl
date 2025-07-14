push!(LOAD_PATH,"../src/")

using Documenter
using AlgorithmAnalysis

makedocs(
    sitename = "AlgorithmAnalysis",
    format = Documenter.HTML(edit_link="master", prettyurls=false),
    modules = [AlgorithmAnalysis],
    checkdocs = :exports,
    pages = [
        "Introduction" => "index.md",
        "Manual" => "manual/index.md",
        "Examples" => "examples/index.md",
        "API" => "api/index.md",
        "Developer Guide" => "developers/index.md"
    ]
)


# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
#=deploydocs(
    repo = "<repository url>"
)=#
