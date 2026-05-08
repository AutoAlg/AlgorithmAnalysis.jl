#########################################################
# CARTESIAN PRODUCT
#########################################################

export Product, spaces, as_product, as_tuple, ×

struct Product <: Trait
    spaces::Tuple{Vararg{Space}}
    dict::Dict{Tuple{Vararg{Object}}, Object}
    Product(ss::Vararg{Space}) = new(ss, Dict{Tuple{Vararg{Object}}, Object}())
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
    get!(t.dict, xs) do
        x = Object(s)
        t.dict[xs] = x
        x
    end
end

as_tuple(x::Object) = as_tuple(get(x, Product), x)

function as_tuple(t::Product, x::Object)
    xs = [k for (k, v) in t.dict if v === x]
    if length(xs) > 1
        error("Product space $t contains multiple tuples for object $x: $xs")
    end
    if isempty(xs)
        error("Product space $t contains no tuples for object $x")
    end
    first(xs)
end

getindex(x::Object, ind::Int) = getindex(get(x, Product), x, ind)
getindex(::Product, x::Object, ind::Int) = as_tuple(x)[ind]

elements(s::Space, ind::Int) = elements(get(s, Product), get(s, Subset), s, ind)
elements(::Product, ::Nothing, s::Space, ind::Int) = Objects( x[ind] for x ∈ elements(s) )
elements(::Nothing, t::Subset, s::Space, ind::Int) = Objects( x[ind] for x ∈ elements(s) )

sample(s::Space, label::Label = missing) = sample(get(s, Product), get(s, Subset), s, label)
sample(::Nothing, ::Nothing, s::Space, label::Label) = Object(s, label = label)

function sample(t::Product, ::Nothing, s::Space, label::Symbol)
    if ismissing(label)
        xs = sample.(t.spaces)
    else
        xs = Tuple( sample(y, Symbol(label, subscript(i))) for (i,y) ∈ enumerate(t.spaces) )
    end
    x = Object(s, label = label)
    t.dict[xs] = x
    x
end

function sample(::Any, t::Subset, s::Space, label::Label)
    x = sample(t.parent, label)
    push!(elements(s), x)
    x
end

show(io::IO, t::Product) = print(io, "Cartesian product ", join(t.spaces, " × "))

function show(io::IO, ::MIME"text/plain", t::Product)
    println(io, "Cartesian product ", join(t.spaces, " × "), " with elements:")
    for p ∈ t.dict
        println(io, "  ", first(p), " ⟷ ", last(p))
    end
end

promote_rule(::Type{NTuple{N, Object}}, ::Type{Space}) where N = Space

convert(::Type{Space}, t::NTuple{N, Object}) where N = as_product(t...)

∈(x::NTuple{N, Object}, s::Space) where N = ∈(promote(x,s)...)
