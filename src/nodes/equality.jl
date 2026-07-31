# ------------------------------------------------------
# NODE EQUALITY
# ------------------------------------------------------

function Base.isequal(a::Node{<:NodeType}, b::Node{<:NodeType})
    a === b && return true

    iscall(a) ≠ iscall(b) && return false

    if iscall(a) && iscall(b)
        return isequal(operation(a), operation(b)) && 
               isequal(arguments(a), arguments(b))
    else
        return symtype(a) == symtype(b) && id(a) == id(b)
    end
end

function Base.hash(a::Node{<:NodeType}, h::UInt)
    if iscall(a)
        h = hash(:iscall, h)
        h = hash(operation(a), h)
        return hash(arguments(a), h)
    else
        h = hash(:leaf, h)
        return hash(id(a), h)
    end
end
