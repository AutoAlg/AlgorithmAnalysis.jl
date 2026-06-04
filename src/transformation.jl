export simplify, find_nodes, find_evaluation_points, replace_node

using SymbolicUtils
using SymbolicUtils.Rewriters: Chain, Postwalk, Fixpoint

is_vector(x) = symtype(x) <: VectorSpace
is_scalar(x) = symtype(x) <: Real
is_scalar_or_vector(x) = is_scalar(x) || is_vector(x)
is_scalar_and_vector(a,x) = is_scalar(a) && is_vector(x) && isequal(symtype(a), field(x))
are_scalars(a,b) = is_scalar(a) && isequal(symtype(a), symtype(b))
are_vectors(u,v) = is_vector(u) && isequal(symtype(u), symtype(v))

# ------------------------------------------------------
# CONVEX INTERPOLATION
# ------------------------------------------------------

convex_interpolation_is_applicable(::BasicSymbolic) = false

function convex_interpolation_is_applicable(opt::BasicSymbolic{<:Optimization})
    return !isempty(find_nodes(c -> isequal(symtype(c), Convex), opt))
end

function convex_interpolation(opt::BasicSymbolic{T}) where {T<:Optimization}

    @show symtype.(flatten_constraints(constraint(opt)))
    
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

function convex_interpolation(opt::BasicSymbolic{T}, f::BasicSymbolic) where {T<:Optimization}

    points = find_evaluation_points(f, opt) ∪ find_evaluation_points(f', opt)

    new_con = replace_node(constraint(opt), f ∈ Convex, satisfied())

    for x ∈ points, y ∈ points
        new_con = new_con ∧ ( f(x) ≥ f(y) + f'(y)'(x-y) )
    end

    new_opt = Term{T}(operation(opt), [objective(opt), new_con])
    new_opt = flatten_evaluations(new_opt, [f, f'])

    return new_opt
end

# ------------------------------------------------------
# GRAM TRANSFORMATION
# ------------------------------------------------------

# function gram_transformation_is_applicable(opt::BasicSymbolic)
#     return false
# end

# function gram_transformation(opt::BasicSymbolic)

#     if !istree(opt) || operation(opt) ≠ maximize
#         error("Expected a 'maximize' optimization term structure.")
#     end

#     objective, constraint = arguments(opt)

#     cs = find_nodes(c -> isequal(symtype(c), Convex), opt)

#     if isempty(cs)
#         error("Optimization problem has no convexity constraints")
#     end

#     new_opt = deepcopy(opt)
    
#     c = first(cs)
#     f = arguments(c)[1]

#     points = find_evaluation_points(f, opt) ∪ find_evaluation_points(f', opt)

#     for x ∈ points, y ∈ points
#         interp = f(x) ≥ f(y) + f'(y)'(x-y)
#         constraint = constraint ∧ interp
#     end

#     new_con = replace_node(constraint, f ∈ Convex, Term{Satisfied}(satisfied, []))

#     new_opt = Term{Maximization}(maximize, [objective, new_con])
#     new_opt = flatten_evaluations(new_opt, [f, f'])

#     return new_opt
# end

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
    @rule ~x * ~y => ~y where (is_scalar_and_vector(~x, ~y) && isequal(~x, one(symtype(~x))))
    @rule ~x * ~y => ~y where (are_scalars(~x, ~y) && isequal(~x, one(symtype(~x))))
    @rule ~x * ~y => zero(symtype(~y)) where (is_scalar_and_vector(~x, ~y) && isequal(~x, zero(symtype(~x))))

    @rule ~x ∧ ~y => ~x where isequal(symtype(~y), Satisfied)
    @rule ~x ∧ ~y => ~y where isequal(symtype(~x), Satisfied)
    @rule ~x ∧ ~y => Sym{Unsatisfied}() where isequal(symtype(~y), Unsatisfied)
    @rule ~x ∧ ~y => Sym{Unsatisfied}() where isequal(symtype(~x), Unsatisfied)

    # --------------------------------------------------
    # CONVEX INTERPOLATION
    # --------------------------------------------------
    @rule ~opt => convex_interpolation(~opt) where convex_interpolation_is_applicable(~opt)

    # --------------------------------------------------
    # GRAM TRANSFORMATION
    # --------------------------------------------------
    # @rule ~opt => gram_transformation(~opt) where gram_transformation_is_applicable(~opt)
]

simplify = Fixpoint(Postwalk(Chain(theory)))
