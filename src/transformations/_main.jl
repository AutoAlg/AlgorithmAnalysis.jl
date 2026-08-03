export simplify

using SymbolicUtils
using SymbolicUtils.Rewriters: Chain, Postwalk, Fixpoint

include("convex_interpolation.jl")
include("smooth_convex_interpolation.jl")
include("sector_bounded_interpolation.jl")
include("gram_transformation.jl")
include("lyapunov_transformation.jl")

is_vector(x) = symtype(x) <: VectorSpace
is_scalar(x) = symtype(x) <: Field
is_scalar_or_vector(x) = is_scalar(x) || is_vector(x)
is_scalar_and_vector(a,x) = is_scalar(a) && is_vector(x) && isequal(symtype(a), field(x))
are_scalars(a,b) = is_scalar(a) && isequal(symtype(a), symtype(b))
are_vectors(u,v) = is_vector(u) && isequal(symtype(u), symtype(v))

are_vectors(xs...) = all(map(is_vector, xs))
are_scalars(xs...) = all(map(is_scalar, xs))
are_scalars_or_vectors(xs...) = all(map(is_scalar_or_vector, xs))

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
    # @rule ~x * ~y => ~y where isone(~x) # TODO: these produce Sym{Real}!!!
    # @rule ~x * ~y => ~x where isone(~y)
    @rule ~x * ~y => zero(symtype(~y)) where (is_scalar_and_vector(~x, ~y) && isequal(~x, zero(symtype(~x))))

    # --------------------------------------------------
    # TRANSFORMATIONS
    # --------------------------------------------------
    @rule ~x::convex_interpolation_is_applicable => convex_interpolation(~x)
    @rule ~x::smooth_convex_interpolation_is_applicable => smooth_convex_interpolation(~x)
    @rule ~x::sector_bound_is_applicable => sector_bounded_interpolation(~x)
    @rule ~x::gram_transformation_is_applicable => gram_transformation(~x)
    @rule ~x::lyapunov_transformation_is_applicable => lyapunov_transformation(~x)
]

"""
    simplify(expr)

Simplify an expression using any of the available transformations.
"""
simplify = Fixpoint(Postwalk(Chain(theory)))
