########################################################
# CARTESIAN PRODUCT
########################################################

export Product, spaces, as_product, as_tuple, ×

struct Product <: Trait
    spaces::Tuple{Vararg{Space}}
    elements::Bijection{Tuple{Vararg{Object}}, Object}
    Product(ss::Vararg{Space}) = new(ss, Bijection{Tuple{Vararg{Object}}, Object}())
end

spaces(s::Space) = spaces(get(s, Product), s)
spaces(t::Product, ::Space) = t.spaces

×(ss::Vararg{Space}) = Space(Symbol(join(label.(ss), " × ")), trait = Product(ss...))

^(s::Space, n::Int) = ×(fill(s,n)...)

getindex(s::Space, ind::Int) = getindex(get(s, Product), s, ind)
getindex(t::Product, ::Space, ind::Int) = t.spaces[ind]

iterate(t::Product) = iterate(t.spaces)
length(t::Product) = length(t.spaces)
isempty(t::Product) = isempty(t.spaces)

iterate(x::Object) = iterate(get(x, Product))
length(x::Object) = length(get(x, Product))
isempty(x::Object) = isempty(get(x, Product))

function as_product(xs::Vararg{Object})
    s = ×(space.(xs)...)
    t = get(s, Product)
    if isnothing(t)
        error("Object $xs is not a product.")
    end
    get!(t.elements, xs) do
        Object(s, Symbol("(", join(label.(xs), ","), ")"))
    end
end

as_tuple(x::Object) = as_tuple(get(x, Product), x)
as_tuple(t::Product, x::Object) = t.elements(x)

getindex(x::Object, ind::Int) = getindex(get(x, Product), x, ind)
getindex(::Product, x::Object, ind::Int) = as_tuple(x)[ind]
getindex(::Nothing, x::Object, ind::Int) = as_array(x)[ind]

elements(s::Space, ind::Int) = elements(get(s, Product), get(s, Subset), s, ind)
elements(::Product, ::Nothing, s::Space, ind::Int) = Objects( x[ind] for x ∈ elements(s) )
elements(::Nothing, t::Subset, s::Space, ind::Int) = Objects( x[ind] for x ∈ elements(s) )

sample(s::Space, label::Symbol) = sample(get(s, Product), get(s, Subset), s, label)
sample(::Nothing, ::Nothing, s::Space, label::Symbol) = Object(s, label)

function sample(t::Product, ::Nothing, s::Space, label::Symbol)
    if ismissing(label)
        xs = sample.(t.spaces)
    else
        xs = Tuple( sample(y, Symbol(label, subscript(i))) for (i,y) ∈ enumerate(t.spaces) )
    end
    x = Object(s, label)
    t.elements[xs] = x
    x
end

function sample(::Any, t::Subset, s::Space, label::Symbol)
    x = sample(t.parent, label)
    push!(elements(s), x)
    x
end

show(io::IO, t::Product) = print(io, "Cartesian product ", join(t.spaces, " × "))

function show(io::IO, ::MIME"text/plain", t::Product)
    println(io, "Cartesian product ", join(t.spaces, " × "), " with elements:")
    for p ∈ t.elements
        println(io, "  ", first(p), " ⟷ ", last(p))
    end
end

promote_rule(::Type{NTuple{N, Object}}, ::Type{Space}) where N = Space

convert(::Type{Space}, t::NTuple{N, Object}) where N = as_product(t...)

∈(x::NTuple{N, Object}, s::Space) where N = ∈(promote(x,s)...)
