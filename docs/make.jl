push!(LOAD_PATH,"../src/")

using Documenter
using BlackBoxOptimization

makedocs(
    sitename = "BlackBoxOptimization",
    format = Documenter.HTML(edit_link="master"),
    modules = [BlackBoxOptimization],
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
