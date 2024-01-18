############################################################################################
# Wrappers

function show(io::IO, x::LinearDecomposition)
    isempty(x) && return print(io, "  "^get(io, :indent, 0), "(empty)")
    first = true
    for (key, value) ∈ weights(x)
        if first
            first = false
            if value == 1
            print(io, key)
            elseif value == -1
            print(io, "-", key)
            else
            print(io, value, " ", key)
            end
        else
            if value == 1
            print(io, " + ", key)
            elseif value == -1
            print(io, " - ", key)
            elseif value ≥ 0
            print(io, " + ", value, " ", key)
            else
            print(io, " - ", -value, " ", key)
            end
        end
    end
end
  
# function show(io::IO, mime::MIME"text/plain", x::LinearDecomposition)
#   isempty(x) && return println(io, "  "^get(io, :indent, 0), "(empty)")
#   map( p -> println(io, "  "^get(io, :indent, 0), p.first, " ↦  ", p.second), collect(x.weights))
# end

function show(io::IO, x::AffineDecomposition)
    print(io, linear(x))
    !iszero(constant(x)) && print(io, " + ", constant(x))
end

# function show(io::IO, mime::MIME"text/plain", x::AffineDecomposition)
#   show(io, mime, linear(x))
#   !iszero(constant(x)) && print(io, "  "^get(io, :indent, 0), constant(x))
# end


############################################################################################
# Expressions

function show(io::IO, e::Expression)
    if hasvalue(e)
        if iszero(e)
            print(io, 0)
        else
            print(io, value(e))
        end
    elseif !isempty(label(e))
        print(io, label(e))
    elseif !isempty(decomposition(e))
        print(io, decomposition(e))
    else
        print(io, "Variable{$(typeof(e))}")
    end
end

function show(io::IO, mime::MIME"text/plain", v::VectorSpace)
    print(io, "\nVector in $(typeof(v))")
    print(io, "\n  Value: ", iszero(v) ? "zero" : value(v))
    print(io, "\n  Decomposition: ", decomposition(v))
    # show(IOContext(io, :indent => get(io,:indent,0)+2), mime, decomposition(v))
end

function show(io::IO, mime::MIME"text/plain", v::InnerProductSpace)
    print(io, "\nVector in $(typeof(v))")
    print(io, "\n  Value: ", iszero(v) ? "zero" : value(v))
    print(io, "\n  Decomposition: ", decomposition(v))
    print(io, "\n  Dual: ")
    show(IOContext(io, :indent => get(io,:indent,0)+2), mime, v')
end

function show(io::IO, mime::MIME"text/plain", a::Field)
    print(io, "\nScalar in $(typeof(a))")
    print(io, "\n  Value: ", value(a))
    print(io, "\n  Decomposition: ", decomposition(a))
    # show(IOContext(io, :indent => get(io,:indent,0)+2), mime, decomposition(a))
end

show(io::IO, G::GramMatrix) = print(io, decomposition(G))

function show(io::IO, mime::MIME"text/plain", G::GramMatrix{V}) where {V<:InnerProductSpace}
    # println("Gram matrix in $(typeof(G))")
    # display(G.decomposition)
    println(io, "\nGram matrix of vectors in $V")
    println(io, "  Value: ", value(G))
    println(io, "  Decomposition:\n")
    show(IOContext(io, :indent => get(io,:indent,0)+2), mime, decomposition(G))
end


############################################################################################
# Constraints

show(io::IO, c::Equality) = print(io, "0 = $(c.x)")
show(io::IO, c::Positive) = print(io, "0 ≤ $(c.x)")
show(io::IO, c::Semidefinite) = print(io, "0 ⪯ $(c.x)")

function show(io::IO, mime::MIME"text/plain", C::Constraints)
    prune!(C)
    println(io, "Set of constraints with $(length(C)) elements:")
    for c ∈ C
        println(io, "  ", c)
    end
end


############################################################################################
# Oracles

show(io::IO, a::Wrapper{<:Oracle}) = show(io, oracle(a))

function show(io::IO, c::Properties)
    first = true
    for c ∈ collect(c)
        first ? (print(io, typeof(c)); first = false) : print(io, ", ", typeof(c))
    end
end

function show(io::IO, o::AbstractOperator{X,Y}) where {X,Y}
    println(io, "\nOperator from $X to $Y: $(allproperties(o))")
    map(p -> println(io, "  ", first(p), " ↦  ", last(p)), collect(samples(o)))
end

function show(io::IO, o::AbstractLinearMap{X,Y}) where {X,Y}
    println(io, "\nLinear map from $X to $Y: $(allproperties(o))")
    map(p -> println(io, "  ", first(p), " ↦  ", last(p)), collect(samples(o)))
    #   println(io, "\nAdjoint operator from $Y to $X: $(properties(o'))")
    #   map(p -> println(io, "  ", first(p), " ↦  ", last(p)), collect(samples(o')))
end

function show(io::IO, o::AbstractSymmetricLinearMap{X}) where {X}
    println(io, "\nSymmetric linear map on $X: $(allproperties(o))")
    map(p -> println(io, "  ", first(p), " ↦  ", last(p)), collect(samples(o)))
end

function show(io::IO, o::ConstantMap{X,Y}) where {X,Y}
    println(io, "\nConstant map from $X to $Y: $(allproperties(o))")
    map(p -> println(io, "  ", first(p), " ↦  ", last(p)), collect(samples(o)))
end

function show(io::IO, o::AbstractFunctional{X}) where {X}
    println(io, "\nFunctional on $X: $(allproperties(o))")
    map(p -> println(io, "  ", first(p), " ↦  ", last(p)), collect(samples(o)))
end

function show(io::IO, o::AbstractLinearFunctional{X}) where {X}
    print(io, label(o'), "'")
end

# function show(io::IO, o::AbstractLinearFunctional{X}) where {X}
#     println(io, "\nLinear functional on $X: $(allproperties(o))")
#     map(p -> println(io, "  ", first(p), " ↦  ", last(p)), collect(samples(o)))
# end

function show(io::IO, mime::MIME"text/plain", o::AbstractLinearFunctional{X}) where {X}
    println(io, "\nLinear functional on $X: $(allproperties(o))")
    map(p -> println(io, "  "^get(io, :indent, 0), first(p), " ↦  ", last(p)), collect(samples(o)))
end

function show(io::IO, o::QuadraticFunctional{X}) where {X}
    print(io, "\nQuadratic functional on $X: $(allproperties(o))")
    map(p -> print(io, "\n  ", first(p), " ↦  ", last(p)), collect(samples(o)))
    #   print(io, "\n\nGradient: $(properties(o'))")
    #   map(p -> print(io, "\n  ", first(p), " ↦  ", last(p)), collect(samples(o')))
    #   print(io, "\n\nHessian: $(properties(o''))")
    #   map(p -> print(io, "\n  ", first(p), " ↦  ", last(p)), collect(samples(o'')))
end

function show(io::IO, r::Relation)
    isempty(r.label) ? nothing : print(io, "\n", r.label, ": ")
    println(io, "\nRelation on $(domain(r)) x $(codomain(r)): $(properties(r))")
    map(p -> println(io, "  ", first(p), " ↦  ", last(p)), collect(samples(r)))
end
