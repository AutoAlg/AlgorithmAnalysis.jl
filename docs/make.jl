using Revise
Revise.revise()
using Pkg

push!(LOAD_PATH,"../src/")

# Ensure the docs environment is active
Pkg.activate(@__DIR__)

using AlgorithmAnalysis, Documenter, DocumenterCitations, DocumenterInterLinks, DocStringExtensions

bib = CitationBibliography(joinpath(@__DIR__, "src", "references.bib"))

links = InterLinks(
    "JuliaBaseDocumentation" => "https://docs.julialang.org/en/v1/"
)

# const directory_to_dump_generated_markdown_files = joinpath(@__DIR__, "src", "results")
# mkpath(directory_to_dump_generated_markdown_files)

# const paths_of_generated_pages::Vector{String} = let
#     local files::Vector{ResultFile} = getAllResult()

#     map(files) do f
#         local diskFilepath::String = joinpath(directory_to_dump_generated_markdown_files, "$(f.file_name).md")
#         local new_contents::String = f.contents
        
#         local should_write = true
#         if isfile(diskFilepath)
#             local old_contents = read(diskFilepath, String)
#             if old_contents == new_contents
#                 should_write = false
#             end
#         end
        
#         if should_write
#             open(diskFilepath, "w") do io
#                 write(io, new_contents)
#             end
#         end
        
#         "results/$(f.file_name).md"
#     end;
# end

makedocs(
    sitename = "AlgorithmAnalysis",
    format = Documenter.HTML(
        edit_link = "main",
        prettyurls = false,
        assets = ["assets/style.css"],
        collapselevel = 1,
        ansicolor = true,
    ),
    modules = [AlgorithmAnalysis],
    # checkdocs = :exports,
    plugins = [bib, links],
    pages = [
        "Introduction" => "index.md",
        "Manual" => [
            "manual/overview.md",
            "manual/pep.md",
            "manual/lyap.md",
        ],
        "API" => "api/index.md",
        # "Results" => paths_of_generated_pages,
        "Developer Guide" => [
            "developers/workflow.md",
            "developers/documentation.md",
            "developers/api.md",
        ]
    ]
)

deploydocs(
    repo = "github.com/AutoAlg/AlgorithmAnalysis.jl.git",
    devbranch = "main",
)
