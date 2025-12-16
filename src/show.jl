############################################################################################
# OBJECT
############################################################################################

function show(io::IO, x::Object)
    if haslabel(x)
        print(io, label(x))
    elseif hasvalue(x)
        print(io, value(x))
    else
        print(io, typeof(x))
    end
end

function show(io::IO, ::MIME"text/plain", x::Object)
    print(io, "Object in ", space(x))
    haslabel(x) && print(io, "\n  Label: ", label(x))
    hasvalue(x) && print(io, "\n  Value: ", value(x))
    hasproperties(x) && print(io, "\n  Properties: ", join(properties(x), ", "))
    hasconstraints(x) && print(io, "\n  Constraints: ", join(constraints(x), ", "))
    hasnext(x) && print(io, "\n  Next: ", next(x))
end

function show(io::IO, ::MIME"text/plain", elements::Objects)
    if isempty(elements)
        print(io, "Empty set of objects")
    else
        print(io, "Set with $(length(elements)) " * (isone(length(elements)) ? "objects:" : "objects:"))
        foreach( v -> print(io, "\n  ", v), elements )
    end
end

show(io::IO, x::Object{<:CartesianProduct}) = print(io, "(", join(as_tuple(x), ", "), ")")


############################################################################################
# PROPERTY
############################################################################################
show(io::IO, ::Invertible) = print(io, "Invertible")
show(io::IO, ::Differentiable) = print(io, "Differentiable")
show(io::IO, ::LocallyLipschitz) = print(io, "Locally Lipschitz")
show(io::IO, ::Convex) = print(io, "Convex")
show(io::IO, p::StronglyConvex) = print(io, "$(p.parameter)-strongly convex")
show(io::IO, p::Ring) = print(io, "Ring($(zero(p)),$(one(p)),$(plus(p)),$(mult(p)))")

############################################################################################
# SPACE
############################################################################################

show(io::IO, x::Space) = print(io, label(x))

function show(io::IO, ::MIME"text/plain", x::Space)
    print(io, "Set")
    haslabel(x) && print(io, "\n  Label: ", label(x))
    !isempty(x) && print(io, "\n  Elements: ", join(elements(x), ", "))
    !isempty(properties(x)) && print(io, "\n  Properties: ", join(properties(x), ", "))
end

function show(io::IO, ::MIME"text/plain", x::Subset)
    print(io, "Subset of $(parent(x))")
    !isempty(x) && print(io, "\n  Elements: ", join(elements(x), ", "))
end

function show(io::IO, ::MIME"text/plain", ::Powerset{T}) where {T<:Space}
    print(io, "Powerset of $T")
end

function show(io::IO, ::MIME"text/plain", x::Type{<:SetValuedMap})
    print(io, "Set of operators from $(domain(x)) to $(codomain(x))")
    haslabel(x) && print(io, "\n  Label: ", label(x))
    !isempty(x) && print(io, "\n  Elements: ", join(elements(x), ", "))
end

function show(io::IO, ::MIME"text/plain", x::Type{<:SingleValuedMap})
    print(io, "Set of functions from $(domain(x)) to $(codomain(x))")
    haslabel(x) && print(io, "\n  Label: ", label(x))
    !isempty(x) && print(io, "\n  Elements: ", join(elements(x), ", "))
end

# function show(io::IO, ::MIME"text/plain", T::Type{<:SetUnion})
#     print(io, "Union ", join(spaces(T), " ∪ "))
# end

# function show(io::IO, ::MIME"text/plain", T::Type{<:SetIntersection})
#     print(io, "Intersection ", join(spaces(T), " ∩ "))
# end

show(io::IO, T::Type{<:CartesianProduct}) = print(io, join(spaces(T), " × "))
# # show(io::IO, T::CartesianPower) = print(io, space(T), superscript(power(T)))
show(io::IO, T::Type{<:SingleValuedMap}) = print(io, "$(domain(T)) → $(codomain(T))")
show(io::IO, T::Type{<:SetValuedMap}) = print(io, "$(domain(T)) ⇒ $(codomain(T))")
# show(io::IO, T::Powerset) = print(io, "𝒫($(base(T))")

function show(io::IO, ::MIME"text/plain", T::Type{<:CartesianProduct})
    print(io, "Cartesian product ", join(spaces(T), " × "))
    !isempty(T) && print(io, "\n  Elements: ", join(elements(T), ", "))
end

# # function show(io::IO, ::MIME"text/plain", T::CartesianPower)
# #     print(io, "Set of $(length(objects(T))) objects")
# #     if !isempty(objects(T))
# #         print(io, "\n  Objects: ", join(objects(T), ", "))
# #     end
# # end

# function show(io::IO, ::MIME"text/plain", T::BasicSet)
#     print(io, "Set $(label(T)) of $(length(objects(T))) objects")
#     if !isempty(objects(T))
#         print(io, "\n  Objects: ", join(objects(T), ", "))
#     end
# end

# function show(io::IO, ::MIME"text/plain", T::Subset)
#     print(io, "Subset of $(parent(T)) with $(length(objects(T))) objects")
#     if !isempty(objects(T))
#         print(io, "\n  Objects: ", join(objects(T), ", "))
#     end
# end

# function show(io::IO, ::MIME"text/plain", T::Powerset)
#     print(io, "Powerset of $(base(T)) with $(length(objects(T))) objects")
#     if !isempty(objects(T))
#         print(io, "\n  Objects: ", join(objects(T), ", "))
#     end
# end


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

# function children(x::Object)
#     if space(x) isa FunctionSpace
#         space(x).samples(x)
#     else
#         space(x)
#     end
# end

# children(s::Space) = objects(structures(s))
# children(s::FunctionSpace) = samples(s)

# struct TreeWrapper
#     name::String
#     children::Tuple
# end

# show(io::IO, x::TreeWrapper) = print(io, x.name)

# function children(x::Object)
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

# tree(x::Object; maxdepth=10) = print_tree(x; maxdepth=maxdepth)

# function tree(io::IO, x::Object; maxdepth=10)
#     print_tree(io, x; maxdepth=maxdepth)
# end