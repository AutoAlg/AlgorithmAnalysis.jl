############################################################################################
# ELEMENT
############################################################################################

function show(io::IO, e::Element)
    if haslabel(e)
        print(io, label(e))
    elseif hasvalue(e)
        print(io, value(e))
    else
        print(io, typeof(e))
    end
end

function show(io::IO, ::MIME"text/plain", a::Element)
    print(io, "Element of $(space(a))")
    haslabel(a) && print(io, "\n  Label: ", label(a))
    hasvalue(a) && print(io, "\n  Value: ", value(a))
    hasconstraints(a) && print(io, "\n  Constraints: ", join(constraints(a), ", "))
    hasoperators(a) && print(io, "\n  Operators: ", join(operators(a), ", "))
    hasnext(a) && print(io, "\n  Next: ", next(a))
    hasproperties(a) && print(io, "\n  Properties: ", join(properties(a), ", "))
end

function show(io::IO, ::MIME"text/plain", elements::Elements)
    if isempty(elements)
        print(io, "Empty set of elements")
    else
        print(io, "Set with $(length(elements)) " * (isone(length(elements)) ? "element:" : "elements:"))
        foreach( v -> print(io, "\n  ", v), elements )
    end
end

function show(io::IO, ::MIME"text/plain", objs::Objects)
    print(io, "Set of objects with $(length(objs)) elements:")
    foreach( x -> print(io, "\n  ", x), objs )
end

############################################################################################
# PRODUCT SPACE
############################################################################################

function subscript(i::Integer)
    i<0 ? error("$i is negative") : join('₀'+d for d in reverse(digits(i)))
end

function superscript(i::Integer)
    if i<0
        error("$i is negative")
    end
    join(
        if d == 1
            '\u00B9'
        elseif d == 2
            '\u00B2'
        elseif d == 3
            '\u00B3'
        else
            '⁰'+d
        end
        for d in reverse(digits(i))
    )
end

function show(io::IO, ::Type{CartesianProduct{T}}) where T
    print(io, join(fieldtypes(T), " × "))
end

show(io::IO, ::Type{<:Element{<:Addition}}) = print(io, "+")
show(io::IO, ::Type{<:Element{<:Multiplication}}) = print(io, "*")

show(io::IO, ::Type{CartesianPower{T, N}}) where {N, T} = print(io, T, superscript(N))
show(io::IO, ::Type{CartesianPower{T}}) where {T} = print(io, T, "ᴺ")
show(io::IO, e::Element{<:CartesianPower}) = print(io, "(", join(value(e), ","), ")")


############################################################################################
# Constraints

# show(io::IO, c::Equality) = print(io, "0 = ", expression(c))
# show(io::IO, c::Positive) = print(io, "0 ≤ ", expression(c))
# show(io::IO, c::Semidefinite) = print(io, "0 ⪯ ", expression(c))

# function show(io::IO, ::MIME"text/plain", cons::Constraints)
#     prune!(cons)
#     if isempty(cons)
#         print(io, "Empty set of constraints")
#     else
#         print(io, "Set of constraints with $(length(cons)) " * (isone(length(cons)) ? "element:" : "elements:"))
#         foreach( c -> print(io, "\n  ", c), cons )
#     end
# end


############################################################################################
# RELATION
############################################################################################

description(::SingleValuedRelation) = "Single-valued relation"
description(::MultiValuedRelation) = "Multi-valued relation"
description(::ConstantRelation) = "Constant relation"

function show(io::IO, r::Relation)
    print(io, "$(description(r)) on $(domain(r)) x $(codomain(r))")
    foreach(p -> print(io, "\n  ", first(p), " → ", last(p)), collect(samples(r)))
end

show(io::IO, ::EmptyRelation) = print(io, "Empty relation")


############################################################################################
# PROPERTIES
############################################################################################

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

############################################################################################
# COMPUTATIONAL TREE
############################################################################################

# struct TreeWrapper
#     name::String
#     children::Tuple
# end

# show(io::IO, x::TreeWrapper) = print(io, x.name)

# function children(x::Element)
#     # ops = operators(space(x))
#     if hasoperators(x) && x ∈ outputs(first(operators(x)))
#         f = first(operators(x))
#         ( TreeWrapper(string(f), value(inv(f,x))), )
#     elseif space(x) <: Operator
#         inputs(x)
#     else
#         ()
#     end
# end

# children(x::TreeWrapper) = x.children

# tree(x::Expression; maxdepth=10) = print_tree(x; maxdepth=maxdepth)

# function tree(io::IO, x::Expression; maxdepth=10)
#     print_tree(io, x; maxdepth=maxdepth)
# end