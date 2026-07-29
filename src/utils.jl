export find_nodes, replace_nodes, flatten_evaluations
export rewrite, find_evaluation_points
export with_verbose, postwalk_with_operators
export transitions, apply_transition, propagate_transition, propagate_transitions
export has_next, next, tostring
export add_constraint, remove_constraint, replace_constraint
export flatten_inner_product, linear_decomposition
export leaves, as_matrix, from_matrix, state

function postwalk_with_operators(f, x)
    if iscall(x)
        op = postwalk_with_operators(f, operation(x))
        args = map(arg -> postwalk_with_operators(f, arg), arguments(x))
        return f(maketerm(typeof(x), op, args, metadata(x)))
    else
        return f(x)
    end
end

"""
    rewrite(node, rules)
"""
rewrite(node::Node, rules) = postwalk_with_operators(Chain(rules), node)

"""
    find_nodes(predicate::Function, tree) -> Vector

Recursively scans a SymbolicUtils AST or algebraic expression. Returns a flat vector 
containing every sub-tree, terminal node, or variable that satisfies `predicate(node)`.
"""
function find_nodes(predicate::Function, node, results::Set = Set())
    if predicate(node)
        push!(results, node)
    end
    if !iscall(node)
        return
    end
    op = operation(node)
    args = arguments(node)

    find_nodes(predicate, op, results)
    for arg in args
        find_nodes(predicate, arg, results)
    end
    return results
end

"""
    replace_node(tree, old_node, new_node)

Walks the entire AST and swaps every instance that matches `old_node` 
with `new_node`.
"""
function replace_node(tree::Node, old_node::Node, new_node::Node)
    return postwalk_with_operators(tree) do node
        isequal(node, old_node) ? new_node : node
    end
end

function flatten_evaluations(tree::Node, f::Node)

    f₊ = next(f, tree)
    T = symtype(f).parameters[2]
    iseval(x) = iscall(x) && isequal(operation(x), f)
    newsym(x) = begin
        arg = tostring(arguments(x)[1])
        fstr = tostring(f)
        sym = Symbol(fstr, "(", arg, ")")
        x₊ = next(x, tree)
        if !isnothing(f₊) && !isnothing(x₊)
            return Sym{T}(sym)
        else
            return Sym{T}(sym)
        end
    end
    
    rule = @rule( ~x => newsym(~x) where iseval(~x) )
    return rewrite(tree, [rule])
end

function flatten_evaluations(tree::Node, fs::Vector{Node})
    for f ∈ fs
        tree = flatten_evaluations(tree, f)
    end
    return tree
end

function is_inner_product(v1::Node, v2::Node)
    V1, V2 = symtype(v1), symtype(v2)
    return isequal(V1, V2) && V1 <: VectorSpace
end

function flatten_inner_product(v1::Node{V}, v2::Node{V}) where {F, V<:VectorSpace{F}}

    if iszero(v1) || iszero(v2)
        return zero(F)
    end

    if issym(v1) && issym(v2)
        s1 = tostring(v1)
        s2 = tostring(v2)
        if isequal(v1, v2)
            sym = Symbol("‖", s1, "‖²")
        else
            first_str, second_str = s1 < s2 ? (s1, s2) : (s2, s1)
            sym = Symbol("⟨", first_str, ",", second_str, "⟩")
        end
        return Sym{F}(sym)
    end

    if iscall(v1)
        op, args = operation(v1), arguments(v1)
        if isequal(op, +)
            return mapreduce(v -> flatten_inner_product(v, v2), +, args)
        elseif isequal(op, -)
            if length(args) == 1
                return -flatten_inner_product(args[1], v2)
            else
                return flatten_inner_product(args[1], v2) - mapreduce(v -> flatten_inner_product(v, v2), +, args[2:end])
            end
        end
    end

    if iscall(v2)
        op, args = operation(v2), arguments(v2)
        if isequal(op, +)
            return mapreduce(v -> flatten_inner_product(v1, v), +, args)
        elseif isequal(op, -)
            if length(args) == 1
                return -flatten_inner_product(v1, args[1])
            else
                return flatten_inner_product(v1, args[1]) - mapreduce(v -> flatten_inner_product(v1, v), +, args[2:end])
            end
        end
    end

    if iscall(v1)
        op, args = operation(v1), arguments(v1)
        if isequal(op, *) && isequal(symtype(args[1]), F)
            return args[1] * mapreduce(v -> flatten_inner_product(v, v2), *, args[2:end])
        end
    end

    if iscall(v2)
        op, args = operation(v2), arguments(v2)
        if isequal(op, *) && isequal(symtype(args[1]), F)
            return args[1] * mapreduce(v -> flatten_inner_product(v1, v), *, args[2:end])
        end
    end

    error("Could not flatten inner product between vectors $v1 and $v2")
end

"""
    find_evaluation_points!(node, state::ExtendedProblemAnalysisState)

Recursively crawls your optimization tree. It safely matches standard function calls 
and looks inside applied adjoint operators to capture gradient evaluation points.
"""
function find_evaluation_points(f::Node, node::Node)
    evals = find_nodes(x -> iscall(x) && isequal(operation(x), f), node)
    map(x -> arguments(x)[1], collect(evals))
end

# iterate over conjunctions
iterate(prop::Node{Conjunction}) = iterate(prop, 1)
function iterate(prop::Node{Conjunction}, i::Int)
    args = arguments(prop)
    if i < 0 || i > length(args)
        return nothing
    else
        return args[i], i+1
    end
end
length(prop::Node{Conjunction}) = length(arguments(prop))

function tostring(node::Node)
    buf = IOBuffer()
    show(IOContext(buf, :compact => true), node)
    return String(take!(buf))
end


const VERBOSE = Base.ScopedValues.ScopedValue{Bool}(false)
verbose() = VERBOSE[]
with_verbose(code::Function, verbose::Bool = true) = Base.ScopedValues.with(code, VERBOSE => verbose)

"""
simple binary search
  f: function that evaluates to true or false
  a: lower bound
  b: upper bound
  tol: tolerance
Assumes f(a)==false and f(b)==true and f is monotone (only one cross-over point)
Returns the smallest x in [a,b] (within tol) such that f(x)==true.
"""
function bsmin(f, a::T, b::T; tol=T(1e-5), verbose=false) where T
    a, b = a > b ? (b, a) : (a, b)
    i = 0
    while (b - a) > tol
        i += 1
        c = (a + b) / T(2)
        f(c) ? (b = c) : (a = c)
        verbose && println("iteration $i: ($a, $b), gap = $(b-a)")
    end
    return b
end

"Extract all transitions from a proposition."
function transitions(con::Node{Conjunction})
    foldl(∧, filter(t -> symtype(t) <: Transition, arguments(con)), init=satisfied())
end
transitions(t::Node{<:Transition}) = t
transitions(::Node{<:Prop}) = satisfied()

has_next(::Node, ::Node{<:Prop}) = false
has_next(node::Node, opt::Node{<:Optimization}) = has_next(node, constraint(opt))
has_next(node::Node, t::Node{<:Transition}) = isequal(node, arguments(t)[1])
has_next(node::Node, ts::Node{Conjunction}) = any(t -> has_next(node, t), arguments(ts))

next(node::Node, t::Node{<:Transition}) = has_next(node, t) ? arguments(t)[2] : nothing
function next(node::Node, ts::Node{Conjunction})
    if has_next(node, ts)
        idx = findfirst(t -> has_next(node, t), arguments(ts))
        next(node, arguments(ts)[idx])
    else
        nothing
    end
end
next(node::Node, opt::Node{<:Optimization}) = next(node, constraint(opt))

"""
    apply_transition(trans::Node{Transition}, expr::Node) -> Node

Substitute state variables in `expr` with their next-step expressions defined by `trans`.

Each pair `(state_var => next_expr)` in `trans` is applied sequentially via a single-pass
`replace_node` rewrite, so the result is the performance measure evaluated at the
next-step state. Sequential application is correct for non-coupled transitions (e.g.
gradient descent with a single state variable).

# Example
```julia
@alg begin
    x, xs ∈ Rⁿ
    f ∈ F(Rⁿ)
    α ∈ R
    g = f'(x)
end
perf  = (x - xs)^2
trans = Transition([x => x - α*g, xs => xs])
perf_next = apply_transition(trans, perf)   # = ((x - α*g) - xs)^2
```
"""
function apply_transition(trans::Node{<:Transition}, expr::Node)
    result = expr
    x, x₊ = arguments(trans)
    return replace_node(result, x, x₊)
end

function apply_transitions(prop::Node{<:Prop}, expr::Node)
    trans = transitions(prop)
    result = expr
    for tran in trans
        result = apply_transition(tran, result)
    end
    return result
end


function propagate_transitions(ctx::Node, f::Node)
    points = find_evaluation_points(f, ctx)
    old, new = satisfied(), satisfied()
    if has_next(f, ctx)
        f₊ = next(f, ctx)
        for x ∈ points
            if has_next(x, ctx)
                x₊ = next(x, ctx)
                new = new ∧ ( f(x) → f₊(x₊) )
            end
        end
        old = old ∧ ( f → f₊ )
    end
    ctx = replace_constraint(ctx, old, new)
    return ctx
end

function propagate_transitions(ctx::Node, fs::Vector{<:Node})
    for f ∈ fs
        ctx = propagate_transitions(ctx, f)
    end
    return ctx
end


function add_constraint(con::Node{<:Prop}, new::Node{<:Prop})
    return con ∧ new
end

function remove_constraint(con::Node{<:Prop}, old::Node{<:Prop})
    isequal(con, old) ? satisfied() : con
end

function remove_constraint(con::Node{Conjunction}, old::Node{<:Prop})
    cons = collect(arguments(con))
    filter!(c -> !isequal(old, c), cons)
    cons = foldl(∧, cons)
end

function add_constraint(opt::Node{T}, con::Node{<:Prop}) where {T<:Optimization}
    Term{T}(operation(opt), [objective(opt), constraint(opt) ∧ con])
end

function add_constraint(opt::Node{T}, con::Node{<:Prop}) where {T<:Feasibility}
    Term{T}(operation(opt), [constraint(opt) ∧ con])
end

function add_constraint(opt::Node{LyapunovCertificate}, new_con::Node{<:Prop})
    con, perf, rate = arguments(opt)
    op = operation(opt)
    Term{LyapunovCertificate}(op, [con ∧ new_con, perf, rate])
end


function remove_constraint(opt::Node{LyapunovCertificate}, old_con::Node{<:Prop})
    con, perf, rate = arguments(opt)
    op = operation(opt)
    Term{LyapunovCertificate}(op, [remove_constraint(con, old_con), perf, rate])
end

function remove_constraint(opt::Node{LyapunovCertificate}, old_con::Node{Conjunction})
    for con ∈ arguments(old_con)
        opt = remove_constraint(opt, con)
    end
    return opt
end

function replace_constraint(opt::Node{LyapunovCertificate}, old::Node{<:Prop}, new::Node{<:Prop})
    add_constraint(remove_constraint(opt, old), new)
end



function linear_decomposition(v::Node{T}) where {T<:Union{VectorSpace, Field, MatrixSpace}}
    
    F = field(T)
    terms = Dict{Node, Node}()

    function add_term!(terms::Dict, leaf::Node, coeff::Node)
        if iszero(coeff)
            return
        end
        if iscall(leaf)
            error("Cannot add non-leaf term: $leaf")
        end
        if haskey(terms, leaf)
            updated = simplify(terms[leaf] + coeff)
            if iszero(updated)
                delete!(terms, leaf)
            else
                terms[leaf] = updated
            end
        else
            terms[leaf] = coeff
        end
    end

    function _decompose!(terms::Dict, v::Node, scale::Node)
        if iszero(v) || iszero(scale)
            return
        end

        scale = simplify(scale)

        F = field(v)

        if !iscall(v)
            if isconstant(v) || isparameter(v)
                add_term!(terms, one(F), simplify(scale * v))
            else
                add_term!(terms, v, scale)
            end
            return
        end

        op, args = operation(v), arguments(v)

        if isequal(op, +)
            for arg in args
                _decompose!(terms, arg, scale)
            end
        elseif isequal(op, -)
            if length(args) == 1
                _decompose!(terms, args[1], simplify(-scale))
            else
                _decompose!(terms, args[1], scale)
                for arg in args[2:end]
                    _decompose!(terms, arg, simplify(-scale))
                end
            end
        elseif isequal(op, *)
            const_scalars = filter(a -> (symtype(a) == F) && isconstant(a) || isparameter(a), args)
            other_args = setdiff(args, const_scalars)

            c_const = isempty(const_scalars) ? one(F) : prod(const_scalars)
            new_scale = simplify(scale * c_const)

            if isempty(other_args)
                add_term!(terms, one(F), new_scale)
            elseif length(other_args) == 1
                _decompose!(terms, other_args[1], new_scale)
            else
                error("Composite leaf: $terms, $v, $scale")
            end
        end
    end
    
    # Run in-place recursive decomposition starting with scale = 1
    _decompose!(terms, v, one(F))
    
    return terms
end

function linear_decomposition(
    v::Node{T}, 
    basis::AbstractVector{<:Node}
) where {T<:Union{VectorSpace, Field, MatrixSpace}}
    
    F = field(T)
    basis_set = Set(basis)
    terms = Dict{Node, Node}()

    function add_term!(terms::Dict, leaf::Node, coeff::Node)
        coeff = simplify(coeff)
        if iszero(coeff)
            return
        end
        if haskey(terms, leaf)
            updated = simplify(terms[leaf] + coeff)
            if iszero(updated)
                delete!(terms, leaf)
            else
                terms[leaf] = updated
            end
        else
            terms[leaf] = coeff
        end
    end

    in_basis(a) = a ∈ basis_set

    function _decompose!(terms::Dict, v::Node, scale::Node)
        if iszero(v) || iszero(scale)
            return
        end

        scale = simplify(scale)
        F = field(v)

        if in_basis(v)
            add_term!(terms, v, scale)
            return
        end

        if isconstant(v) || isparameter(v)
            c_val = simplify(scale * v)
            one_node = one(F)
            if one_node ∈ basis_set
                add_term!(terms, one_node, c_val)
            elseif !iszero(c_val)
                error("Scalar term $c_val present in expression, but unit 1 ($one_node) is not in the provided basis.")
            end
            return
        end

        if !iscall(v)
            error("Variable leaf $v is not in the provided basis.")
        end

        op, args = operation(v), arguments(v)

        if isequal(op, +)
            for arg in args
                _decompose!(terms, arg, scale)
            end
        elseif isequal(op, -)
            if length(args) == 1
                _decompose!(terms, args[1], simplify(-scale))
            else
                _decompose!(terms, args[1], scale)
                for arg in args[2:end]
                    _decompose!(terms, arg, simplify(-scale))
                end
            end
        elseif isequal(op, *)
            # A. Check if any non-basis factor is a sum/difference requiring distribution: c * (A + B)
            sum_idx = findfirst(a -> iscall(a) && (isequal(+, operation(a)) || isequal(-, operation(a))) && a ∉ basis_set, args)

            if sum_idx !== nothing
                sum_arg = args[sum_idx]
                other_args = deleteat!(copy(args), sum_idx)
                other_factor = isempty(other_args) ? one(F) : (length(other_args) == 1 ? other_args[1] : foldl(*, other_args))

                sum_op = operation(sum_arg)
                sum_children = arguments(sum_arg)

                if isequal(+, sum_op)
                    for child in sum_children
                        _decompose!(terms, child * other_factor, scale)
                    end
                elseif isequal(-, sum_op)
                    if length(sum_children) == 1
                        _decompose!(terms, sum_children[1] * other_factor, simplify(-scale))
                    else
                        _decompose!(terms, sum_children[1] * other_factor, scale)
                        for child in sum_children[2:end]
                            _decompose!(terms, child * other_factor, simplify(-scale))
                        end
                    end
                end
                return
            end

            # B. Partition factors into basis vs non-basis
            basis_args = filter(a -> a ∈ basis_set, args)
            non_basis_args = filter(a -> a ∉ basis_set, args)

            # Multiply all non-basis factors together into the scale factor
            non_basis_factor = isempty(non_basis_args) ? one(F) : (length(non_basis_args) == 1 ? non_basis_args[1] : foldl(*, non_basis_args))
            new_scale = simplify(scale * non_basis_factor)

            if length(basis_args) == 1
                # Exactly one basis element found in product
                basis_term = basis_args[1]
                add_term!(terms, basis_term, new_scale)
                return

            elseif length(basis_args) == 0
                # No individual factor is in basis. If unit 1 is in basis, map the whole product as a scalar
                one_node = one(F)
                if one_node ∈ basis_set
                    add_term!(terms, one_node, new_scale)
                    return
                else
                    error("Composite term $v is not in the provided basis, and unit 1 ($one_node) is not in the basis.")
                end

            else
                # Multiple basis terms multiplied together: e.g. x * y when both x and y are basis elements
                error("Non-linear product of basis elements in $v: $basis_args")
            end
        else
            error("Term $v is not in the provided basis and cannot be decomposed further.")
        end
    end

    # Run in-place recursive decomposition starting with scale = 1
    _decompose!(terms, v, one(F))

    return terms
end

function as_matrix(p::Pair{<:Vector{<:Node}, <:Node})
    basis, term = p

    F = field(term)

    dict = linear_decomposition(term, basis)

    [ get(dict, v, zero(F)) for _ in 1:1, v ∈ basis ]
end

function as_matrix(p::Pair{<:Vector{<:Node}, <:Vector{<:Node}})
    basis, terms = p

    [ get(linear_decomposition(term), v, zero(field(term))) for term ∈ terms, v ∈ basis ]
end

function as_matrix(p::Pair{<:Vector{<:Node}, Node{Sⁿ}})
    basis, term = p
    n = size(term, 1)
    A = reshape(arguments(term), n, n)

    F = field(A[1,1])

    [ get(linear_decomposition(A[i,j]), v, zero(F)) for i ∈ 1:n, j ∈ 1:n, v ∈ basis ]
end

"""
    from_matrix(basis::Vector{<:Node}, coords::AbstractVector)

Reconstructs a symbolic Node expression from a coordinate vector and a basis.
"""
function from_matrix(basis::Vector{<:Node}, coords::AbstractVector)
    return sum(c * b for (c, b) in zip(coords, basis))
end



struct SymbolicOperator{F, BIn<:Vector{<:Node}, BOut<:Vector{<:Node}}
    apply::F               # Transformation function (e.g., u -> A*u or diff(u))
    in_basis::BIn          # Input basis elements
    out_basis::BOut        # Output basis elements
end

# Convenience constructor when input and output bases are the same (V -> V)
SymbolicOperator(apply, basis::Vector{<:Node}) = SymbolicOperator(apply, basis, basis)

# Forward call: A(v)
(op::SymbolicOperator)(v::Node) = op.apply(v)

"""
    as_matrix(op::SymbolicOperator)

Constructs the explicit matrix representation M of the operator relative to
op.in_basis and op.out_basis.
"""
function as_matrix(op::SymbolicOperator)
    # Each column j is op(u_j) expanded in out_basis
    rows = [ as_matrix(op.out_basis => op.apply(u)) for u in op.in_basis ]
    return vcat(rows...) # Matrix of size (length(out_basis) × length(in_basis))
end

export SymbolicOperator, AdjointSymbolicOperator

struct AdjointSymbolicOperator{Op<:SymbolicOperator}
    op::Op
end

# Hook into Julia's syntax (op')
la.adjoint(op::SymbolicOperator) = AdjointSymbolicOperator(op)
la.adjoint(adj::AdjointSymbolicOperator) = adj.op
la.adjoint(x::Node{R}) = x

# Evaluate Adjoint: A'(w)
function (adj::AdjointSymbolicOperator)(w::Node)
    # 1. Get forward matrix representation M
    M_basis = as_matrix(adj.op)
    
    M_adj = M_basis'

    # 2. Extract coordinates of w in out_basis (N_out × 1)
    w_coords = as_matrix(adj.op.out_basis => w)
    
    # 3. Compute adjoint coordinates in in_basis: M' * w_coords
    v_coords = w_coords * M_adj
    
    # 4. Reconstruct symbolic Node in in_basis
    return from_matrix(adj.op.in_basis, vec(v_coords))
end


"""
    leaves(v::Node)

Recursively collects all AST leaf nodes (nodes where `iscall(v)` is false) from an expression tree.
Returns a `Set` of unique leaf nodes.
"""
function leaves(v::Node)

    # In-place helper for tree traversal
    function collect_leaves!(leaves::Set, v::Node)
        if !iscall(v)
            push!(leaves, v)
            return leaves
        end

        for arg in arguments(v)
            collect_leaves!(leaves, arg)
        end

        return leaves
    end

    leaves = Set{Node}()
    collect_leaves!(leaves, v)
    return leaves
end

function state(prob::Node{LyapunovCertificate})
    con = arguments(prob)[1]
    ts = transitions(con)
    if isnothing(ts)
        return nothing, nothing
    end
    states = [ arguments(t)[1] for t ∈ ts ]
    next_states = [ next(state, prob) for state ∈ states ]

    return states, next_states
end

export subscript, superscript

function subscript(i::Integer)
    i<0 ? error("$i is negative") : join('₀'+d for d in reverse(digits(i)))
end

function superscript(i::Integer)
    if i<0
        error("$i is negative")
    end
    join(
        if d == 1
            '\u00B9'
        elseif d == 2
            '\u00B2'
        elseif d == 3
            '\u00B3'
        else
            '⁰'+d
        end
        for d in reverse(digits(i))
    )
end
