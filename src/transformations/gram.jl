
export gram_transformation, gram_transformation_is_applicable

gram_transformation_is_applicable(::Any) = false

function gram_transformation_is_applicable(opt::BasicSymbolic{Optimization})
    if convex_interpolation_is_applicable(opt)
        return false
    elseif smooth_convex_interpolation_is_applicable(opt)
        return false
    elseif isempty(find_nodes(x -> symtype(x) <: VectorSpace, opt))
        return false
    end
    return true
end

function gram_transformation(opt::BasicSymbolic{Optimization})

    all_vecs = find_nodes(x -> symtype(x) <: VectorSpace, opt)
    vectorspaces = Set(symtype.(all_vecs))

    for vectorspace in vectorspaces
        vecs = [v for v in all_vecs if isequal(symtype(v), vectorspace) && issym(v)]
        vecs = unique!(vecs)

        G = Sⁿ([x'(y) for x in vecs, y in vecs])

        vec_str = join(tostring.(vecs), ", ")

        @info "Applying Gram transformation to vector space $vectorspace with vectors $vec_str"

        opt = add_constraint(opt, G ⪰ 0)

        rule = @rule adjoint(~v1)(~v2) => flatten_inner_product(~v1, ~v2)

        opt = rewrite(opt, [rule])
    end

    return opt
end
