export extract_symbols, get_safe_symbol, is_safe
export subscript, superscript
export tostring

function tostring(node::Node)
    buf = IOBuffer()
    show(IOContext(buf, :compact => true), node)
    return String(take!(buf))
end

"""
    extract_symbols!(symbols::Set{Symbol}, expr)

Recursively collects all Symbol names used across a BasicSymbolic expression 
or array of expressions.
"""
function extract_symbols(node, symbols::Set{Symbol} = Set{Symbol}())
    if has_id(node)
        push!(symbols, id(node))
    end
    if iscall(node)
        op = operation(node)
        if op isa Node
            extract_symbols(op, symbols)
        elseif op isa Symbol
            push!(symbols, op)
        end
        for arg in arguments(node)
            extract_symbols(arg, symbols)
        end
    end
    return symbols
end

# Overload for Arrays of Nodes (e.g., basis vectors, matrix operators)
function extract_symbols(collection::AbstractArray, symbols::Set{Symbol} = Set{Symbol}())
    for item in collection
        extract_symbols(item, symbols)
    end
    return symbols
end

extract_symbols(sym::Symbol, symbols::Set{Symbol} = Set{Symbol}()) = symbols ∪ Set([sym])

"""
    is_symbol_safe(candidate::Symbol, expr)

Returns `true` if `candidate` does not appear anywhere inside `expr`.
"""
is_safe(candidate::Symbol, ctx::Node) = candidate ∉ extract_symbols(ctx)

"""
    get_safe_symbol(base::Symbol, expr; subscript_fn = subscript)

Returns `base` if safe, otherwise appends subscript indices (e.g. λ -> λ₁ -> λ₂) 
until a collision-free symbol is found.
"""
function get_safe_symbol(base::Symbol, used::Set{Symbol}; force_subscript::Bool = false)
    if !force_subscript && base ∉ used
        return base
    end
    i = 1
    while true
        candidate = Symbol(base, subscript(i))
        if candidate ∉ used
            return candidate
        end
        i += 1
    end
end

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
