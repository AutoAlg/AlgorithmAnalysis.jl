############################################################################################
# Decompositions

show(io::IO, ::EmptyDecomposition{T}) where {T} = print(io, "Empty decomposition in $(T)")

function show(io::IO, x::LinearDecomposition)
    isempty(x) && return print(io, "  "^get(io, :indent, 0), "(empty)")
    if !all(v isa Number for v ∈ values(weights(x)))
        return print(io, "Linear decomposition with non-Number weights")
    end
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

function show(io::IO, e::Expression)
    if iszero(e)
        print(io, "𝟎")
    elseif e isa Gram
        if e.vecs1 === e.vecs2
            print(io, "Gram matrix of vectors $(e.vecs1)")
        else
             print(io, "Gram matrix of vectors $(e.vecs1) and $(e.vecs2)")
        end
    elseif hasvalue(e)
        print(io, value(e))
    elseif !isempty(label(e))
        print(io, label(e))
    else
        print(io, decomposition(e))
    end
end

elementname(::Type{<:VectorSpace}) = "vector"
elementname(::Type{<:Field}) = "scalar"
elementname(::Type{<:Gram}) = "gram matrix"

function show(io::IO, ::MIME"text/plain", e::T) where {T<:Expression}
    if iszero(e)
        print(io, "\nZero $(lowercase(elementname(T))) in $(typeof(e))")
    # elseif hasvalue(e)
    #     print(io, value(e))
    else
        if e isa Gram
            if e.vecs1 === e.vecs2
                print(io, "Gram matrix of vectors $(e.vecs1)")
            else
                print(io, "Gram matrix of vectors $(e.vecs1) and $(e.vecs2)")
            end
        else
            print(io, "\n$(uppercasefirst(elementname(T))) in $(typeof(e))")
        end
        # isdefined(e, :vecs) && print(io, "\n Value: $(e.vecs) ⊗ $(e.vecs)")
        !isempty(label(e)) && print(io, "\n  Label: ", label(e))
        hasvalue(e) && print(io, "\n  Value: ", value(e))
        # hasdecomposition(e) && print(io, "\n  Decomposition: ", decomposition(e))
        !isempty(constraints(e)) && print(io, "\n  Constraints: ", join(constraints(e), ", "))
        !isempty(oracles(e)) && print(io, "\n  Oracles: ", join(oracles(e), ", "))
        !ismissing(next(e)) && print(io, "\n  Next: ", next(e))
        !isempty(associations(e)) && print(io, "\n  Associations: ", join(associations(e),", "))
    end
end

show(io::IO, p::Pair{Type{<:Association}, Expression}) = print(io, first(p), " => ", last(p))

# Associations
# show(io::IO, a::Associations) = print(io, a...)


############################################################################################
# Constraints

# show(io::IO, c::Constraint) = print(io, expression(c), " ∈ ", set(c))

function show(io::IO, c::Constraint)
    x = expression(c)
    K = cone(c)
    if K == UnrestrictedCone()
        print(io, x, " unrestricted")
    elseif K == ZeroSet()
        print(io, "0 = ", x)
    elseif K == PositiveOrthant()
        print(io, "0 ≤ ", x)
    elseif K == PositiveSemidefiniteCone()
        print(io, "0 ⪯ ", x)
    else
        print(io, x, " ∈ ", K)
    end
end
# show(io::IO, c::Equality) = print(io, "0 = ", expression(c))
# show(io::IO, c::Positive) = print(io, "0 ≤ ", expression(c))
# show(io::IO, c::Semidefinite) = print(io, "0 ⪯ ", expression(c))

function show(io::IO, ::MIME"text/plain", C::Constraints)
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

description(::SingleValuedRelation) = "Single-valued relation"
description(::MultiValuedRelation) = "Multi-valued relation"
description(::ConstantRelation) = "Constant relation"
description(::SmoothStronglyConvexFunction) = "Smooth strongly convex function"

function show(io::IO, r::Relation)
    print(io, "\n$(description(r)) on $(domain(r)) x $(codomain(r))")
    foreach(p -> print(io, "\n  ", first(p), " → ", last(p)), collect(samples(r)))
end


############################################################################################
# Oracles

# show(io::IO, o::Oracle) = print(io, label(o))

function show(io::IO, ::MIME"text/plain", o::Oracle)
    print(io, "\nOracle")
    print(io, "\n  Description: $(description(o))")
    !isempty(label(o)) && print(io, "\n  Label: $(label(o))")
    !isempty(constraints(o)) && print(io, "\n  Constraints: $(constraints(o)...)")
    !isempty(associations(o)) && print(io, "\n  Associations: ", join(associations(o),", "))
    isdefined(o, :value) && !ismissing(o.value) && print(io, "\n  Value: ", o.value)
end
