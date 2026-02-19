export Reference, References, Result, Results, KNOWN_RESULTS, markdown, verify

struct Reference
    doi::String
    loc::Union{Nothing, String}
end

Reference(doi::String) = Reference(doi, nothing)

const References = Set{Reference}

AutoHashEquals.@auto_hash_equals struct Result
    title::String
    statement::String
    references::References
    verification::String
end

const Results = Vector{Result}

function verify(result::Result)
    func = eval(Meta.parse("function ()\n$(result.verification)\nend"))
    return Base.invokelatest(func)
end

function metadata(ref::Reference)
    url = "https://api.crossref.org/works/$(ref.doi)"
    resp = HTTP.get(url)
    if resp.status ≠ 200
        error("DOI lookup failed with status $(resp.status)")
    end
    data = JSON.parse(String(resp.body))["message"]
    title = get(data, "title", [""])[1]
    authors = get(data, "author", [])
    author_names = [ string(a["given"], " ", a["family"]) for a in authors ]
    year = get(data, "issued", Dict())["date-parts"][1][1]
    return (authors=author_names, title=title, year=year, doi=ref.doi)
end

function get_function_source(f::Function)
    mi = first(methods(f))  # get the first method instance
    src = CodeTracking.definition(mi)
    return src === nothing ? "Source not available." : src
end

function show(io::IO, ::MIME"text/markdown", ref::Reference)
    info = metadata(ref)
    println(io, join(info.authors, ", ", " and "), ". *", info.title, "*. ", info.year, ". [doi:", info.doi, "](https://doi.org/$(info.doi))")
end

function show(io::IO, ::MIME"text/plain", references::References)
    if !isempty(references)
        println(io, "\nReferences:")
        for reference in references
            println(io, "- ", reference)
        end
    end
end

function show(io::IO, ::MIME"text/markdown", references::References)
    if !isempty(references)
        println(io, "\n**References:**")
        for reference in references
            print(io, "- ")
            show(io, MIME"text/markdown"(), reference)
        end
    end
end

function show(io::IO, ref::Reference)
    info = metadata(ref)
    print(io, join(info.authors, ", ", " and "), ". ", info.title, ". ", info.year, ".")
end

show(io::IO, result::Result) = println(io, "", result.title)

function show(io::IO, ::MIME"text/markdown", result::Result)
    println(io, "## ", result.title)
    println(io, result.statement)
    show(io, MIME"text/markdown"(), result.references)
    println(io, """\n
**Verification:**
```julia
$(result.verification)
```
""")
end

function show(io::IO, ::MIME"text/plain", result::Result)
    println(io, result.title, "\n\n", result.statement, result.references)
end

function show(io::IO, ::MIME"text/markdown", results::Results)
    for result in results
        show(io, MIME"text/markdown"(), result)
    end
end

function markdown(results::Results)
    io = IOBuffer()
    show(io, MIME"text/markdown"(), results)
    return String(take!(io))
end

const KNOWN_RESULTS = Results()

push!(KNOWN_RESULTS,
    Result(
        "Gradient descent",
        raw"""
For gradient descent with stepsize ``\alpha`` applied to ``m``-strongly convex and ``L``-smooth functions, the distance to optimality converges at a rate of
```math
    \rho = 1-2\alpha mL/(L+m) \quad \text{if} \quad 0 < \alpha \leq \frac{2}{L+m}.
```
In particular, if ``\alpha = 2/(L+m)``, the rate is ``(\kappa-1)/(\kappa+1)`` where ``\kappa = L/m``.""",
        References([
            Reference("10.1007/978-3-319-91578-4", "Theorem 2.1.15")
        ]),
        """
m = 1
L = 10
α = 2/(L+m)
ρ = 1-2α*m*L/(L+m)
@algorithm begin
    f = DifferentiableFunctional{Rⁿ}()
    xs = first_order_stationary_point(f)
    f' ∈ SmoothStronglyConvex(m, L)
    
    x0 = Rⁿ()
    x0 => x0 - α * f'(x0)

    performance = (x0 - xs)^2
end

certify(performance, ρ)

# gradient_descent(m, L, α=α, ρ=ρ, measure=DistanceToOptimality, n=1) &&
# gradient_descent(m, L, α=α, ρ=ρ, measure=DistanceToStationarity, n=2) &&
# abs( gradient_descent(m, L, α=α, measure=DistanceToStationarity, n=2) - ρ ) < 1e-3
"""
    ),
    Result(
        "Triple momentum",
        "For the triple momentum method applied to L-smooth and m-strongly convex functions, the distance to optimality converges at a rate of 1-1/√κ where κ = L/m.",
        References([
            Reference("10.1109/LCSYS.2017.2722406")
        ]),
        """
triple_momentum()
"""
    )
)