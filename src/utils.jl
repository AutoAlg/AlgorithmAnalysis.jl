export find_nodes, replace_nodes, flatten_evaluations
export rewrite, find_evaluation_points, flatten_constraints
export with_verbose, postwalk_with_operators
export Node

const Node{T} = SymbolicUtils.BasicSymbolic{T}

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
    rewrite(tree, rules)
"""
rewrite(tree, rules) = postwalk_with_operators(Chain(rules), tree)

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
function replace_node(tree, old_node, new_node)
    swap_rule = @rule( ~x => new_node where isequal(~x, old_node) )
    return rewrite(tree, [swap_rule])
end

function flatten_evaluations(tree, f::Node)

    T = symtype(f).parameters[2]
    iseval(x) = iscall(x) && isequal(operation(x), f)
    newsym(x) = begin
        arg = tostring(arguments(x)[1])
        fstr = tostring(f)
        sym = Symbol(fstr, "(", arg, ")")
        Sym{T}(sym)
    end
    
    rule = @rule( ~x => newsym(~x) where iseval(~x) )
    return rewrite(tree, [rule])
end

function flatten_evaluations(tree, fs::Vector{Node})
    new_tree = deepcopy(tree)
    for f ∈ fs
        new_tree = flatten_evaluations(new_tree, f)
    end
    return new_tree
end

function flatten_inner_product(v1, v2)

    if symtype(v1) ≠ symtype(v2)
        error("Inner product of $v1 and $v2 cannot be flattened since they are in different spaces")
    end

    if iszero(v1) || iszero(v2)
        return zero(field(v1))
    end

    if iscall(v1) && isequal(operation(v1), -) && length(arguments(v1)) == 1
        return -flatten_inner_product(arguments(v1)[1], v2)
    end
    if iscall(v2) && isequal(operation(v2), -) && length(arguments(v2)) == 1
        return -flatten_inner_product(v1, arguments(v2)[1])
    end

    if issym(v1) && issym(v2)
        T = field(v1)
        s1 = tostring(v1)
        s2 = tostring(v2)
        if isequal(v1, v2)
            sym = Symbol("‖", s1, "‖²")
        else
            first_str, second_str = s1 < s2 ? (s1, s2) : (s2, s1)
            sym = Symbol("⟨", first_str, ",", second_str, "⟩")
        end
        return Sym{T}(sym)
    end

    if iscall(v1)
        op = operation(v1)
        args = arguments(v1)
        if isequal(op, +)
            return sum(map(v -> flatten_inner_product(v, v2), args))
        elseif isequal(op, -)
            if length(args) == 2
                return flatten_inner_product(args[1], v2) - flatten_inner_product(args[2], v2)
            end
        elseif isequal(op, *)
            # Assuming first arg is scalar, second is vector
            return args[1] * flatten_inner_product(args[2], v2)
        end
    end

    if iscall(v2)
        op = operation(v2)
        args = arguments(v2)
        if isequal(op, +)
            return sum(map(v -> flatten_inner_product(v1, v), args))
        elseif isequal(op, -)
            new_args = map(v -> flatten_inner_product(v1, v), args)
            if length(args) == 2
                return flatten_inner_product(v1, args[1]) - flatten_inner_product(v1, args[2])
            end
        elseif isequal(op, *)
            # Assuming first arg is scalar, second is vector
            return args[1] * flatten_inner_product(v1, args[2])
        end
    end

    error("Could not flatten inner product between vectors $v1 and $v2")
end

"""
    find_evaluation_points!(node, state::ExtendedProblemAnalysisState)

Recursively crawls your optimization tree. It safely matches standard function calls 
and looks inside applied adjoint operators to capture gradient evaluation points.
"""
function find_evaluation_points(f, node)
    evals = find_nodes(x -> iscall(x) && isequal(operation(x), f), node)
    map(x -> arguments(x)[1], collect(evals))
end

function flatten_constraints(node)
    list = []
    flatten_constraints!(list, node)
    return list
end

function flatten_constraints!(list, node)
    if iscall(node) && isequal(operation(node), ∧)
        map(arg -> flatten_constraints!(list, arg), arguments(node))
        return
    elseif node isa Expr && isequal(node.head, :call)
        op = node.args[1]
        if isequal(op, ∧) || isequal(op, :∧)
            map(arg -> flatten_constraints!(list, arg), node.args[2:end])
            return
        end
    end
    push!(list, node)
end

function tostring(node)
    buf = IOBuffer()
    show(buf, MIME"text/plain"(), node)
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
