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

function show(io::IO, ::MIME"text/plain", x::LinearDecomposition{T}) where {T}
    print(io, "\nLinear decomposition over $T: ")
    isempty(x) && return print(io, "  "^get(io, :indent, 0), "(empty)")
    map( p -> print(io, "\n", "  "^get(io, :indent, 1), p.first, " ↦  ", p.second), collect(weights(x)))
end

function show(io::IO, x::AffineDecomposition)
    print(io, linear(x))
    !iszero(constant(x)) && print(io, " + ", constant(x))
end

function show(io::IO, ::MIME"text/plain", x::AffineDecomposition{T}) where {T}
    print(io, "\nAffine decomposition over $T: ")
    isempty(x) && return print(io, "  "^get(io, :indent, 0), "(empty)")
    map( p -> print(io, "\n", "  "^get(io, :indent, 1), p.first, " ↦  ", p.second), collect(weights(x)))
    !iszero(constant(x)) && print(io, "\n", "  "^get(io, :indent, 1), "constant: ", constant(x))
end


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
    print(io, "\n  Label: ", label(v))
    print(io, "\n  Value: ", iszero(v) ? "zero" : value(v))
    print(io, "\n  Decomposition: ", decomposition(v))
end

function show(io::IO, mime::MIME"text/plain", a::Field)
    print(io, "\nScalar in $(typeof(a))")
    print(io, "\n  Label: ", label(a))
    print(io, "\n  Value: ", value(a))
    print(io, "\n  Decomposition: ", decomposition(a))
end

show(io::IO, G::GramMatrix) = print(io, decomposition(G))

function show(io::IO, mime::MIME"text/plain", G::GramMatrix{V}) where {V<:InnerProductSpace}
    print(io, "\nGram matrix of vectors in $V")
    print(io, "\n  Label: ", label(G))
    print(io, "\n  Value: ", value(G))
    print(io, "\n  Decomposition:\n")
    show(IOContext(io, :indent => get(io,:indent,0)+2), mime, decomposition(G))
end


############################################################################################
# Constraints

show(io::IO, c::Equality) = print(io, "0 = $(c.x)")
show(io::IO, c::Positive) = print(io, "0 ≤ $(c.x)")
show(io::IO, c::Semidefinite) = print(io, "0 ⪯ $(c.x)")

function show(io::IO, mime::MIME"text/plain", C::Constraints)
    prune!(C)
    if isempty(C)
        print(io, "Empty set of constraints")
    else
        print(io, "Set of constraints with $(length(C)) elements:")
        for c ∈ C
            print(io, "\n  ", c)
        end
    end
end


############################################################################################
# Relation

function show(io::IO, r::Relation)
    if isempty(samples(r))
        print(io, "\nEmpty relation on $(domain(r)) x $(codomain(r))")
    else
        print(io, "\nRelation on $(domain(r)) x $(codomain(r))")
        map(p -> print(io, "\n  ", first(p), " ↦  ", last(p)), collect(samples(r)))
    end
end


############################################################################################
# Properties

function show(io::IO, P::Properties)
    if isempty(P)
        print(io, "Empty set of properties")
    else
        first = true
        for p ∈ P
            first ? (print(io, p); first = false) : print(io, ", ", p)
        end
    end
end

show(io::IO, p::SmoothStronglyConvex) = print(io, "$(p.b)-smooth, $(p.a)-strongly convex")


############################################################################################
# Oracles

show(io::IO, o::Oracle) = print(io, label(o))
show(io::IO, w::Wrapper{<:Oracle}) = show(io, unwrap(w))

function show(io::IO, mime::MIME"text/plain", o::Oracle, desc::String = "")
    print(io, "\nOracle")
    print(io, "\n  Description: $(description(o))")
    if !isempty(desc)
        print(io, ", ", desc)
    end
    print(io, "\n  Label: $(label(o))")
    print(io, "\n  Properties: $(allproperties(o))")
    print(io, "\n  Associations: ")
    if isempty(associations(o))
        print(io, "No associations")
    else
        for a ∈ associations(o)
            print(io, "\n    $(first(a)) => $(last(a))")
        end
    end
end

show(io::IO, mime::MIME"text/plain", w::Wrapper{<:Oracle}) = show(io, mime, unwrap(w), description(w))
