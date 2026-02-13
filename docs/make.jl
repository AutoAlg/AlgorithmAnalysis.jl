push!(LOAD_PATH,"../src/")

using AlgorithmAnalysis, Documenter

makedocs(
    sitename = "AlgorithmAnalysis",
    format = Documenter.HTML(edit_link="master", prettyurls=false),
    modules = [AlgorithmAnalysis],
    checkdocs = :exports,
    pages = [
        "Introduction" => "index.md",
        "Manual" => [
            "manual/code.md",
            "manual/analysis.md"
        ],
        "Examples" => "examples/index.md",
        "API" => [
            "Analysis" => "api/analysis.md",
            "Expressions" => "api/expressions.md",
            "Oracles" => "api/oracles.md",
            "Label" => "api/label.md",
            "Relations" => "api/relation.md",
            "Constraints" => "api/constraints.md",
            "Wrappers" => "api/wrappers.md",
            "Properties" => "api/properties.md",
            "Performance Measures" => "api/performance.md",
            "Miscellaneous" => "api/miscellaneous.md",
        ],
        "Developer Guide" => "developers/index.md"
    ]
)


# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
#=deploydocs(
    repo = "<repository url>"
)=#
