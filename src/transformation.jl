export simplify, find_nodes, find_evaluation_points, replace_node
export convex_interpolation, smooth_convex_interpolation, sector_bounded_interpolation

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

# ------------------------------------------------------
# CONVEX INTERPOLATION
# ------------------------------------------------------

convex_interpolation_is_applicable(::Any) = false

function convex_interpolation_is_applicable(opt::Node{<:Optimization})
    return !isempty(find_nodes(c -> isequal(symtype(c), Convex), opt))
end

function convex_interpolation(opt::Node{<:Optimization})
    
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

function convex_interpolation(opt::Node{<:Optimization}, f::Node)

    points = find_evaluation_points(f, opt) ∪ find_evaluation_points(f', opt)

    pts = join(tostring.(points), ", ")

    @info "Applying convex interpolation to function $f with evaluation points $pts"

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
# SMOOTH CONVEX INTERPOLATION
# ------------------------------------------------------

smooth_convex_interpolation_is_applicable(::Any) = false

function smooth_convex_interpolation_is_applicable(opt::Node{<:Optimization})
    predicate = function (c)
        isequal(symtype(c), Prop) && iscall(c) && isequal(operation(c), smooth_convex)
    end
    return !isempty(find_nodes(predicate, opt))
end

function smooth_convex_interpolation(opt::Node{<:Optimization})
    
    predicate = function (c)
        isequal(symtype(c), Prop) && iscall(c) && isequal(operation(c), smooth_convex)
    end
    cons = find_nodes(predicate, opt)

    if isempty(cons)
        error("Optimization problem has no smooth convexity constraints")
    end

    for con ∈ cons
        f, L = arguments(con)
        opt = smooth_convex_interpolation(opt, f, L)
    end

    return opt
end

function smooth_convex_interpolation(opt::Node{<:Optimization}, f::Node, L::Node)

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
        interp = interp ∧ ( f(x) ≥ f(y) + gy'(x-y) + 1/2L * (gx-gy)'(gx-gy) )
    end

    new_opt = replace_node(opt, smooth_convex(f, L), interp)
    new_opt = flatten_evaluations(new_opt, [f, f'])

    return new_opt
end

# ------------------------------------------------------
# SECTOR BOUNDED GRADIENT
# ------------------------------------------------------

sector_bound_is_applicable(::Any) = false

function sector_bound_is_applicable(opt::Node{<:Optimization})
    predicate = function (c)
        isequal(symtype(c), Prop) && iscall(c) && isequal(operation(c), sector_bounded)
    end
    return !isempty(find_nodes(predicate, opt))
end

function sector_bounded_interpolation(opt::Node{<:Optimization})
    
    predicate = function (c)
        isequal(symtype(c), Prop) && iscall(c) && isequal(operation(c), sector_bounded)
    end
    cons = find_nodes(predicate, opt)

    if isempty(cons)
        error("Optimization problem has no sector bound constraints")
    end

    for con ∈ cons
        f, μ, L = arguments(con)
        opt = sector_bounded_interpolation(opt, f, μ, L)
    end

    return opt
end

function sector_bounded_interpolation(opt::Node{<:Optimization}, f::Node, μ::Node, L::Node)

    points = find_evaluation_points(f, opt) ∪ find_evaluation_points(f', opt)

    pts = join(tostring.(points), ", ")

    @info "Applying [$μ,$L] sector bounded interpolation to function $f with evaluation points $pts"

    if isempty(points)
        @info "No points found!"
        return opt
    end

    interp = satisfied()

    for x ∈ points
        interp = interp ∧ ( (f'(x) - μ*x)'(f'(x) - L*x) ≤ zero(R) )
    end

    old = sector_bounded(f, μ, L)

    opt = replace_constraint(opt, old, interp)
    opt = propagate_transitions(opt, [f, f'])
    opt = flatten_evaluations(opt, [f, f'])

    return opt
end

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

function gram_transformation(opt::Node{<:Optimization})

    all_vecs = find_nodes(x -> symtype(x) <: VectorSpace, opt)
    vectorspaces = Set(symtype.(all_vecs))

    for vectorspace in vectorspaces
        vecs = [v for v in all_vecs if isequal(symtype(v), vectorspace) && issym(v)]
        vecs = unique!(vecs)

        G = Sⁿ([ x'(y) for x in vecs, y in vecs ])

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

        @show old

        opt = replace_constraint(opt, old, new)

        opt = add_constraint(opt, G ⪰ 0)

        rule = @rule adjoint(~v1)(~v2) => flatten_inner_product(~v1, ~v2)
        
        opt = rewrite(opt, [rule])
    end

    return opt
end

# ------------------------------------------------------
# LYAPUNOV ANALYSIS (forward declarations; full implementation in lyapunov.jl)
# ------------------------------------------------------

# Fallback — returns false until lyapunov.jl adds the LyapunovAnalysis method.
lyapunov_transformation_is_applicable(::Any) = false

# Stub — lyapunov.jl defines the LyapunovAnalysis method that does the real work.
function lyapunov_transformation end

# Fallback — returns false until lyapunov.jl adds Optimization-specific method.
lyapunov_certificate_transformation_is_applicable(::Any) = false

# Stub — lyapunov.jl defines the Optimization method that builds certificate constraints.
function lyapunov_certificate_transformation end

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
    # INTERPOLATION
    # --------------------------------------------------
    @rule ~opt => convex_interpolation(~opt) where convex_interpolation_is_applicable(~opt)
    @rule ~opt => smooth_convex_interpolation(~opt) where smooth_convex_interpolation_is_applicable(~opt)
    @rule ~opt => sector_bounded_interpolation(~opt) where sector_bound_is_applicable(~opt)

    # --------------------------------------------------
    # LYAPUNOV ANALYSIS
    # --------------------------------------------------
    # @rule ~opt => lyapunov_transformation(~opt) where lyapunov_transformation_is_applicable(~opt)

    # --------------------------------------------------
    # GRAM TRANSFORMATION
    # --------------------------------------------------
    @rule ~opt => gram_transformation(~opt) where gram_transformation_is_applicable(~opt)

    # --------------------------------------------------
    # LYAPUNOV CERTIFICATE TRANSFORMATION
    # --------------------------------------------------
    # @rule ~opt => lyapunov_certificate_transformation(~opt) where lyapunov_certificate_transformation_is_applicable(~opt)
]

simplify = Fixpoint(Postwalk(Chain(theory)))
