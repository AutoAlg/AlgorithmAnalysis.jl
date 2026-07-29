export algebra_simplify, pep_simplify, lyap_simplify, find_nodes, find_evaluation_points, replace_node, smooth_convex_interpolation, apply_s_procedure, propagate_constants, extract_lmi_coefficients
export smooth_strongly_convex_interpolation_is_applicable, smooth_strongly_convex_interpolation

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

const algebra_theory = [
    # TODO: are these needed?
    @rule ~x + ~y => ~x where (iscall(~y) && isequal(operation(~y), zero))
    @rule ~x + ~y => ~y where (iscall(~x) && isequal(operation(~x), zero))
    @rule ~x - ~y => ~x where (iscall(~y) && isequal(operation(~y), zero))
    @rule ~x - ~y => -(~y) where (iscall(~x) && isequal(operation(~x), zero))

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


algebra_simplify = Fixpoint(Postwalk(Chain(algebra_theory)))
pep_simplify = Fixpoint(Postwalk(Chain(vcat(algebra_theory, pep_theory))))

