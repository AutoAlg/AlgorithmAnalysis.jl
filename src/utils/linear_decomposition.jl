export linear_decomposition, as_matrix, from_matrix

function linear_decomposition(
    v::Node{T}, 
    basis::AbstractVector{<:Node}
) where {T<:Union{VectorSpace, Field, MatrixSpace}}
    
    F = field(T)
    one_node = one(F)
    
    # 1. Pre-simplify basis elements to ensure AST normalization matches simplify(expr)
    # simplified_basis = map(simplify, basis)
    terms = Dict{Node, Node}()

    # Robust check for basis membership via isequal
    in_basis(a) = any(b -> isequal(a, b), basis)

    # 2. Recursive helper to flatten nested * AST nodes (e.g., a * (b * x) -> [a, b, x])
    function flatten_mul(arg::Node)
        if iscall(arg) && isequal(operation(arg), *) && !in_basis(arg)
            res = Node[]
            for child in arguments(arg)
                append!(res, flatten_mul(child))
            end
            return res
        else
            return Node[arg]
        end
    end

    function add_term!(terms::Dict, leaf::Node, coeff::Node)
        if iszero(coeff)
            return
        end
        
        # Look for existing key using isequal structural match
        existing_key = nothing
        for k in keys(terms)
            if isequal(k, leaf)
                existing_key = k
                break
            end
        end

        if existing_key !== nothing
            updated = terms[existing_key] + coeff
            if iszero(updated)
                delete!(terms, existing_key)
            else
                terms[existing_key] = updated
            end
        else
            terms[leaf] = coeff
        end
    end

    function _decompose!(terms::Dict, expr::Node, scale::Node)
        v = expr
        scale = simplify(scale)

        if iszero(v) || iszero(scale)
            return
        end

        # Direct Basis Match (excluding unit 1)
        if in_basis(v) && !isequal(v, one_node)
            add_term!(terms, v, scale)
            return
        end

        # Leaf Node Handling
        if !iscall(v)
            if is_constant(v) || is_parameter(v)
                c_val = scale * v
                if in_basis(one_node)
                    add_term!(terms, one_node, c_val)
                elseif !iszero(c_val)
                    error("Scalar term $c_val present in expression, but unit 1 is not in the provided basis.")
                end
                return
            else
                error("Variable leaf $v is not in the provided basis.")
            end
        end

        # Composite Expressions (+, -, *)
        op, raw_args = operation(v), arguments(v)

        if isequal(op, +)
            for arg in raw_args
                _decompose!(terms, arg, scale)
            end

        elseif isequal(op, -)
            if length(raw_args) == 1
                _decompose!(terms, raw_args[1], -scale)
            else
                _decompose!(terms, raw_args[1], scale)
                for arg in raw_args[2:end]
                    _decompose!(terms, arg, -scale)
                end
            end

        elseif isequal(op, *)
            # A. Un-nest multiplication AST nodes into a flat array of factors
            args = Node[]
            for arg in raw_args
                append!(args, flatten_mul(arg))
            end

            # B. Distribute products over sums: c * (A + B)
            sum_idx = findfirst(a -> iscall(a) && (isequal(operation(a), +) || isequal(operation(a), -)) && !in_basis(a), args)

            if sum_idx !== nothing
                sum_arg = args[sum_idx]
                other_args = deleteat!(copy(args), sum_idx)
                other_factor = isempty(other_args) ? one_node : (length(other_args) == 1 ? other_args[1] : foldl(*, other_args))

                sum_op = operation(sum_arg)
                sum_children = arguments(sum_arg)

                if isequal(sum_op, +)
                    for child in sum_children
                        _decompose!(terms, child * other_factor, scale)
                    end
                elseif isequal(sum_op, -)
                    if length(sum_children) == 1
                        _decompose!(terms, sum_children[1] * other_factor, -scale)
                    else
                        _decompose!(terms, sum_children[1] * other_factor, scale)
                        for child in sum_children[2:end]
                            _decompose!(terms, child * other_factor, -scale)
                        end
                    end
                end
                return
            end

            # C. Partition flattened factors into direct basis elements vs non-basis factors
            basis_args = filter(a -> in_basis(a) && !isequal(a, one_node), args)
            non_basis_args = filter(a -> !in_basis(a) || isequal(a, one_node), args)

            if length(basis_args) == 1
                basis_term = basis_args[1]
                
                # All non-basis factors (e.g. `a` and `b` in `a * b * x`) combine into the coefficient
                coeff_factor = isempty(non_basis_args) ? one_node : (length(non_basis_args) == 1 ? non_basis_args[1] : foldl(*, non_basis_args))
                add_term!(terms, basis_term, scale * coeff_factor)
                return

            elseif length(basis_args) > 1
                error("Non-linear product of basis elements in $v: $basis_args")

            else
                # D. No individual factor matched directly. Check if composite non-basis factors match (e.g. x * y)
                composite_candidate = length(non_basis_args) == 1 ? non_basis_args[1] : foldl(*, non_basis_args)
                
                if in_basis(composite_candidate) && !isequal(composite_candidate, one_node)
                    add_term!(terms, composite_candidate, scale)
                    return
                else
                    # Pure scalar product fallback
                    c_val = scale * v
                    if in_basis(one_node)
                        add_term!(terms, one_node, c_val)
                        return
                    else
                        error("Composite term $v is not in the provided basis.")
                    end
                end
            end
        else
            error("Unsupported operation $op in term $v.")
        end
    end

    # Run in-place recursive decomposition starting with scale = 1
    _decompose!(terms, v, one_node)

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

    [ get(linear_decomposition(term, basis), v, zero(field(term))) for term ∈ terms, v ∈ basis ]
end

function as_matrix(p::Pair{<:Vector{<:Node}, Node{Sⁿ}})
    basis, term = p
    n = size(term, 1)
    A = reshape(arguments(term), n, n)

    F = field(A[1,1])

    [ get(linear_decomposition(A[i,j], basis), v, zero(F)) for i ∈ 1:n, j ∈ 1:n, v ∈ basis ]
end

"""
    from_matrix(basis::Vector{<:Node}, coords::AbstractVector)

Reconstructs a symbolic Node expression from a coordinate vector and a basis.
"""
function from_matrix(basis::Vector{<:Node}, coords::AbstractVector)
    return sum(c * b for (c, b) in zip(coords, basis))
end
