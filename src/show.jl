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
    foreach( p -> print(io, "\n", "  "^get(io, :indent, 1), p.first, " → ", p.second), collect(weights(x)))
end


############################################################################################
# Expressions

show(io::IO, e::Variable) = print(io, label(e))

function show(io::IO, mime::MIME"text/plain", e::Variable)
    if hasvalue(e)
        print(io, value(e))
    elseif !isempty(label(e))
        print(io, label(e))
    else
        print(io, "Variable{$(typeof(e))}")
    end
end

function show(io::IO, mime::MIME"text/plain", v::VectorSpace)
    if iszero(v)
        print(io, "\nZero vector in $(typeof(v))")
    else
        print(io, "\nVector in $(typeof(v))")
        print(io, "\n  Label: ", label(v))
        print(io, "\n  Value: ", value(v))
    end
end

function show(io::IO, mime::MIME"text/plain", a::Field)
    if iszero(a)
        print(io, "\nZero scalar in $(typeof(a))")
    else
        print(io, "\nScalar in $(typeof(a))")
        print(io, "\n  Label: ", label(a))
        print(io, "\n  Value: ", evaluate(a))
    end
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
        foreach(p -> print(io, "\n  ", first(p), " ↦  ", last(p)), collect(samples(r)))
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
show(io::IO, w::Wrapper) = show(io, unwrap(w))

function show(io::IO, mime::MIME"text/plain", o::Oracle)
    print(io, "\nOracle")
    print(io, "\n  Description: $(description(o))")
    print(io, "\n  Label: $(label(o))")
    print(io, "\n  Properties: $(properties(o))")
    print(io, "\n  Associations: ")
    if isempty(associations(o))
        print(io, "No associations")
    else
        for a ∈ associations(o)
            print(io, "\n    $(first(a)) => $(last(a))")
        end
    end
end

function show(io::IO, mime::MIME"text/plain", w::Wrapper)
    show(io, mime, unwrap(w))
end
