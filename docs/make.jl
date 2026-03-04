push!(LOAD_PATH,"../src/")

using AlgorithmAnalysis, Documenter, DocumenterCitations

bib = CitationBibliography(joinpath(@__DIR__, "src", "references.bib"))

const directory_to_dump_generated_markdown_files = joinpath(@__DIR__, "src", "results")
mkpath(directory_to_dump_generated_markdown_files)

const paths_of_generated_pages::Vector{String} = let
    local files::Vector{ResultFile} = getAllResult()

    map(files) do f
        local diskFilepath::String = joinpath(directory_to_dump_generated_markdown_files, "$(f.file_name).md")
        local new_contents::String = f.contents
        
        local should_write = true
        if isfile(diskFilepath)
            local old_contents = read(diskFilepath, String)
            if old_contents == new_contents
                should_write = false
            end
        end
        
        if should_write
            open(diskFilepath, "w") do io
                write(io, new_contents)
            end
        end
        
        "results/$(f.file_name).md"
    end;
end

makedocs(
    sitename = "AlgorithmAnalysis",
    format = Documenter.HTML(
        edit_link = "master",
        prettyurls = false,
        assets = ["assets/style.css"],
    ),
    modules = [AlgorithmAnalysis],
    checkdocs = :exports,
    plugins = [bib],
    pages = [
        "Introduction" => "index.md",
        "Manual" => [
            "manual/code.md",
            "manual/analysis.md"
        ],
        "Results" => paths_of_generated_pages,
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
