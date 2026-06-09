export simplify, find_nodes, find_evaluation_points, replace_node

using SymbolicUtils
using SymbolicUtils.Rewriters: Chain, Postwalk, Fixpoint

is_vector(x) = symtype(x) <: VectorSpace
is_scalar(x) = symtype(x) <: Field
is_scalar_or_vector(x) = is_scalar(x) || is_vector(x)
is_scalar_and_vector(a,x) = is_scalar(a) && is_vector(x) && isequal(symtype(a), field(x))
are_scalars(a,b) = is_scalar(a) && isequal(symtype(a), symtype(b))
are_vectors(u,v) = is_vector(u) && isequal(symtype(u), symtype(v))

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

    @info "Applying convex interpolation to function $f"

    points = find_evaluation_points(f, opt) ∪ find_evaluation_points(f', opt)

    if isempty(points)
        @info "No points found!"
        return opt
    end

    interp = satisfied()

    for x ∈ points, y ∈ points
        interp = interp ∧ ( f(x) ≥ f(y) + f'(y)'(x-y) )
    end

    new_opt = replace_node(opt, convex(f), interp)
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

        G = Sⁿ([ x'(y) for x in vecs, y in vecs ])

        vec_str = join(vecs, ", ")

        @info "Applying Gram transformation to vector space $vectorspace with vectors $vec_str"

        opt = add_constraint(opt, G ⪰ 0)

        rule = @rule adjoint(~v1)(~v2) => flatten_inner_product(~v1, ~v2)
        
        opt = rewrite(opt, [rule])
    end

    return opt
end

# ------------------------------------------------------
# THEORY
# ------------------------------------------------------
const theory = [
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
    @rule -(-(~x))     => ~x                where is_scalar_or_vector(~x)

    # --------------------------------------------------
    # SCALAR MULTIPLICATION IDENTITIES
    # --------------------------------------------------
    @rule ~x * ~y => ~y where (is_scalar_and_vector(~x, ~y) && isequal(~x, one(symtype(~x))))
    @rule ~x * ~y => ~y where (are_scalars(~x, ~y) && isequal(~x, one(symtype(~x))))
    @rule ~x * ~y => zero(symtype(~y)) where (is_scalar_and_vector(~x, ~y) && isequal(~x, zero(symtype(~x))))

    # @rule ~~x ∧ ~y => ~x where isequal(symtype(~y), Satisfied)
    # @rule ~x ∧ ~~y => ~y where isequal(symtype(~x), Satisfied)
    # @rule ~~x ∧ ~y => unsatisfied() where isequal(symtype(~y), Unsatisfied)
    # @rule ~x ∧ ~~y => unsatisfied() where isequal(symtype(~x), Unsatisfied)

    # --------------------------------------------------
    # CONVEX INTERPOLATION
    # --------------------------------------------------
    @rule ~opt => convex_interpolation(~opt) where convex_interpolation_is_applicable(~opt)

    # --------------------------------------------------
    # GRAM TRANSFORMATION
    # --------------------------------------------------
    @rule ~opt => gram_transformation(~opt) where gram_transformation_is_applicable(~opt)
]

simplify = Fixpoint(Postwalk(Chain(theory)))
