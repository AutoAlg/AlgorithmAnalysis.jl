export algebra_simplify, pep_simplify, lyap_simplify, find_nodes, find_evaluation_points, replace_node

using SymbolicUtils
using SymbolicUtils.Rewriters: Chain, Postwalk, Fixpoint

is_vector(x) = symtype(x) <: VectorSpace
is_scalar(x) = symtype(x) <: Field
is_scalar_or_vector(x) = is_scalar(x) || is_vector(x)
is_scalar_and_vector(a, x) = is_scalar(a) && is_vector(x) && isequal(symtype(a), field(x))
are_scalars(a, b) = is_scalar(a) && isequal(symtype(a), symtype(b))
are_vectors(u, v) = is_vector(u) && isequal(symtype(u), symtype(v))

are_vectors(xs...) = all(map(is_vector, xs))
are_scalars(xs...) = all(map(is_scalar, xs))
are_scalars_or_vectors(xs...) = all(map(is_scalar_or_vector, xs))

function add_constraint(opt::BasicSymbolic{T}, con::BasicSymbolic{<:Constraint}) where {T<:Optimization}
    return Term{T}(operation(opt), [objective(opt), constraint(opt) ∧ con])
end

# ------------------------------------------------------
# CONVEX INTERPOLATION
# ------------------------------------------------------

convex_interpolation_is_applicable(::Any) = false

function convex_interpolation_is_applicable(opt::BasicSymbolic{Optimization})
    return !isempty(find_nodes(c -> isequal(symtype(c), Convex), opt))
end

function convex_interpolation(opt::BasicSymbolic{Optimization})

    cvx_cons = find_nodes(c -> isequal(symtype(c), Convex), opt)

    if isempty(cvx_cons)
        error("Optimization problem has no convexity constraints")
    end

    for con ∈ cvx_cons
        f = first(arguments(con))
        opt = convex_interpolation(opt, f)
    end

    return opt
end

function convex_interpolation(opt::BasicSymbolic{Optimization}, f::BasicSymbolic)

    points = find_evaluation_points(f, opt) ∪ find_evaluation_points(f', opt)

    pts = join(tostring.(points), ", ")

    @info "Applying convex interpolation to function $f with evaluation points $pts"

    if isempty(points)
        @info "No points found!"
        return opt
    end

    interp = satisfied()

    for x ∈ points, y ∈ points
        interp = interp ∧ (f(x) ≥ f(y) + f'(y)'(x-y))
    end

    new_opt = replace_node(opt, convex(f), interp)
    new_opt = flatten_evaluations(new_opt, [f, f'])

    return new_opt
end

# ------------------------------------------------------
# SMOOTH CONVEX INTERPOLATION
# ------------------------------------------------------

smooth_convex_interpolation_is_applicable(::Any) = false

function smooth_convex_interpolation_is_applicable(opt::BasicSymbolic{Optimization})
    predicate = function (c)
        isequal(symtype(c), Constraint) && iscall(c) && isequal(operation(c), smooth_convex)
    end
    return !isempty(find_nodes(predicate, opt))
end

function smooth_convex_interpolation(opt::BasicSymbolic{Optimization})

    predicate = function (c)
        isequal(symtype(c), Constraint) && iscall(c) && isequal(operation(c), smooth_convex)
    end
    cons = find_nodes(predicate, opt)

    if isempty(cons)
        error("Optimization problem has no smooth convexity constraints")
    end

    for con ∈ cons
        f, L = arguments(con)
        opt = smooth_convex_interpolation(opt, f, L) # why is this named the same
    end

    return opt
end

# TODO: all of this is smelly as hell, the fact there *isnt* an assert here isnt great
function smooth_convex_interpolation(opt::BasicSymbolic{Optimization}, f::BasicSymbolic, L::BasicSymbolic)

    points = find_evaluation_points(f, opt) ∪ find_evaluation_points(f', opt)

    pts = join(tostring.(points), ", ")

    @info "Applying $L-smooth convex interpolation to function $f with evaluation points $pts"

    if isempty(points)
        @info "No points found!"
        return opt
    end

    interp = satisfied()

    for x ∈ points, y ∈ points
        gx = f'(x)
        gy = f'(y)
        interp = interp ∧ (f(x) ≥ f(y) + gy'(x-y) + 1/2L * (gx-gy)'(gx-gy))
    end

    new_opt = replace_node(opt, smooth_convex(f, L), interp)
    new_opt = flatten_evaluations(new_opt, [f, f'])

    return new_opt
end

# ------------------------------------------------------
# GRAM TRANSFORMATION
# ------------------------------------------------------

export gram_transformation

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


const algebra_theory = [
    # --------------------------------------------------
    # ADDITIVE IDENTITY
    # --------------------------------------------------
    @rule ~x::is_scalar + ~y => ~x where (iscall(~y) && isequal(operation(~y), zero))
    @rule ~x + ~y::is_scalar => ~y where (iscall(~x) && isequal(operation(~x), zero))

    # --------------------------------------------------
    # ADDITIVE INVERSES & INVOLUTION
    # --------------------------------------------------
    @rule +(~x, -(~x)) => zero(symtype(~x)) where is_scalar_or_vector(~x)
    @rule +(-(~x), ~x) => zero(symtype(~x)) where is_scalar_or_vector(~x)
    @rule -(-(~x)) => ~x where is_scalar_or_vector(~x)

    # --------------------------------------------------
    # SCALAR MULTIPLICATION IDENTITIES
    # --------------------------------------------------
    @rule ~x * ~y => ~y where (is_scalar_and_vector(~x, ~y) && isequal(~x, one(symtype(~x))))
    @rule ~x * ~y => ~y where (are_scalars(~x, ~y) && isequal(~x, one(symtype(~x))))
    @rule ~x * ~y => zero(symtype(~y)) where (is_scalar_and_vector(~x, ~y) && isequal(~x, zero(symtype(~x))))];

const pep_theory = [

    # --------------------------------------------------
    # CONVEX INTERPOLATION
    # --------------------------------------------------
    @rule ~opt => convex_interpolation(~opt) where convex_interpolation_is_applicable(~opt)
    @rule ~opt => smooth_convex_interpolation(~opt) where smooth_convex_interpolation_is_applicable(~opt)


    # --------------------------------------------------
    # GRAM TRANSFORMATION
    # --------------------------------------------------
    @rule ~opt => gram_transformation(~opt) where gram_transformation_is_applicable(~opt)
];

# gram_transformation_is_applicable iff !ssc & convex

const lyap_theory = [
    # TODO: verify that this is applicable, I think it might need to be changed a little
    # @rule ~opt => smooth_convex_interpolation(~opt) where smooth_convex_interpolation_is_applicable(~opt)

    # @rule ~opt => propagate_x_into_xn, litterally rewrite the xns into their coresponding x because of that relational constraint
    # @rule ~opt => s_procedure, collect everything into a single large inequality

    #
    @rule ~opt => gram_transformation(~opt) where gram_transformation_is_applicable(~opt)];

# TODO: maybe split into a seperated pass of [algebra, expand, algebra, gram]?

algebra_simplify = Fixpoint(Postwalk(Chain(algebra_theory)))
pep_simplify = Fixpoint(Postwalk(Chain(vcat(algebra_theory, pep_theory))))

function lyap_simplify(opt::BasicSymbolic{Optimization})
    interop1 = Fixpoint(Postwalk(Chain(algebra_theory)))
    interop2 = Fixpoint(Postwalk(Chain(lyap_theory)))

    interop2(interop1())
end

# TODO: just apply the simplifcations directly, get something that works and then try and pass it into the automatic solver 
# TODO: check whether or not the algebra passes are actually doing anything
# eliminate the algebra stuff?

# ask
# í remove algebra, clean up rest? ffe
# other codebase cleanups