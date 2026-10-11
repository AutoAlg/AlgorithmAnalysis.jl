# ------------------------------------------------------
# GRAM TRANSFORMATION
# ------------------------------------------------------

export gram_transformation

gram_transformation_is_applicable(::Any) = false

function gram_transformation_is_applicable(opt::Node{<:Optimization})
    if convex_interpolation_is_applicable(opt)
        return false
    elseif smooth_convex_interpolation_is_applicable(opt)
        return false
    elseif sector_bound_is_applicable(opt)
        return false
    elseif isempty(find_nodes(x -> symtype(x) <: VectorSpace, opt))
        return false
    end
    return true
end

"""
    gram_transformation(opt)

Given an optimization node, for each vector space, replaces all vectors in the space with the condition that their Gram matrix is positive semidefinite. All inner products are flattened into new symbolic variables.
"""
function gram_transformation(opt::Node{<:Optimization})

    all_vecs = find_nodes(x -> symtype(x) <: VectorSpace, opt)
    vectorspaces = Set(symtype.(all_vecs))

    for vectorspace in vectorspaces
        vecs = [v for v in all_vecs if isequal(symtype(v), vectorspace) && issym(v)]
        vecs = unique!(vecs)

        G = Sⁿ([ x ⋅ y for x in vecs, y in vecs ])

        vec_str = join(tostring.(vecs), ", ")

        @info "Applying Gram transformation to vector space $vectorspace with vectors $vec_str"

        new, old = satisfied(), satisfied()

        for (i,v1) ∈ enumerate(vecs), (j,v2) ∈ enumerate(vecs)
            if i ≤ j && has_next(v1, opt) && has_next(v2, opt)
                new = new ∧ ( v1'(v2) → next(v1, opt)'( next(v2, opt) ) )
            end
        end
        for v ∈ vecs
            if has_next(v, opt)
                old = old ∧ ( v → next(v, opt) )
            end
        end

        opt = replace_constraint(opt, old, new)

        opt = add_constraint(opt, G ⪰ 0)

        rule = @rule adjoint(~v1)(~v2) => flatten_inner_product(~v1, ~v2) where is_inner_product(~v1,~v2)
        
        opt = rewrite(opt, [rule])
    end

    return opt
end
