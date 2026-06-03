export simplify, find_nodes, find_evaluation_points, replace_node

using SymbolicUtils
using SymbolicUtils.Rewriters: Chain, Postwalk, Fixpoint

is_vector(x) = symtype(x) <: VectorSpace
is_scalar(x) = symtype(x) <: Real
is_scalar_or_vector(x) = is_scalar(x) || is_vector(x)
is_scalar_and_vector(a,x) = is_scalar(a) && is_vector(x) && symtype(a) === field(x)
are_scalars(a,b) = is_scalar(a) && symtype(a) === symtype(b)
are_vectors(u,v) = is_vector(u) && symtype(u) === symtype(v)

# ------------------------------------------------------
# CONVEX INTERPOLATION
# ------------------------------------------------------

function is_cvx_opt(opt)
    return istree(opt) &&
        operation(opt) === maximize &&
        !isempty(find_nodes(c -> symtype(c) === Convex, opt))
end

function convex_interpolation(opt::BasicSymbolic)

    if !istree(opt) || operation(opt) ≠ maximize
        error("Expected a 'maximize' optimization term structure.")
    end

    objective, constraint = arguments(opt)

    cs = find_nodes(c -> symtype(c) === Convex, opt)

    if isempty(cs)
        error("Optimization problem has no convexity constraints")
    end

    new_opt = deepcopy(opt)
    
    c = first(cs)
    f = arguments(c)[1]

    points = find_evaluation_points(f, opt) ∪ find_evaluation_points(f', opt)

    for x ∈ points, y ∈ points
        interp = f(x) ≥ f(y) + f'(y)'(x-y)
        constraint = constraint ∧ interp
    end

    new_con = replace_node(constraint, f ∈ Convex, Term{Satisfied}(satisfied, []))

    new_opt = Term{Maximization}(maximize, [objective, new_con])
    new_opt = flatten_evaluations(new_opt, [f, f'])

    return new_opt
end

# ------------------------------------------------------
# THEORY
# ------------------------------------------------------
const theory = [
    # --------------------------------------------------
    # ADDITIVE IDENTITY
    # --------------------------------------------------
    @rule ~x + additive_identity() => ~x where is_scalar_or_vector(~x)
    @rule additive_identity() + ~x => ~x where is_scalar_or_vector(~x)

    # --------------------------------------------------
    # ADDITIVE INVERSES & INVOLUTION
    # --------------------------------------------------
    @rule +(~x, -(~x)) => zero(symtype(~x)) where is_scalar_or_vector(~x)
    @rule +(-(~x), ~x) => zero(symtype(~x)) where is_scalar_or_vector(~x)
    @rule -(-(~x))     => ~x                where is_scalar_or_vector(~x)

    # --------------------------------------------------
    # SCALAR MULTIPLICATION IDENTITIES
    # --------------------------------------------------
    @rule ~x * ~y => ~y where (is_scalar_and_vector(~x, ~y) && ~x === one(symtype(~x)))
    @rule ~x * ~y => ~y where (are_scalars(~x, ~y) && ~x === one(symtype(~x)))
    @rule ~x * ~y => zero(symtype(~y)) where (is_scalar_and_vector(~x, ~y) && ~x === zero(symtype(~x)))

    @rule ~x ∧ ~y => ~x where symtype(~y) === Satisfied
    @rule ~x ∧ ~y => ~y where symtype(~x) === Satisfied

    # --------------------------------------------------
    # CONVEX INTERPOLATION
    # --------------------------------------------------
    @rule ~opt => convex_interpolation(~opt) where is_cvx_opt(~opt)

    # --------------------------------------------------
    # GRAM TRANSFORMATION
    # --------------------------------------------------

]

simplify = Fixpoint(Postwalk(Chain(theory)))
