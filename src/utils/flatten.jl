function flatten_evaluations(tree::Node, f::Node)

    f₊ = next(f, tree)
    T = symtype(f).parameters[2]
    iseval(x) = iscall(x) && isequal(operation(x), f)
    newsym(x) = begin
        arg = tostring(arguments(x)[1])
        fstr = tostring(f)
        sym = Symbol(fstr, "(", arg, ")")
        x₊ = next(x, tree)
        return leaf(T, sym)
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
        return leaf(F, sym)
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
