import Base.hash

"""
    hash(x, h::UInt)

Hash of an expression. Custom types must provide specialized methods for this function due to [this issue](https://github.com/JuliaLang/julia/issues/10267).
"""
function hash end

# hash(e::Expression, h::UInt) = hash(objectid(e), h)

# function hash(a::AbstractArray{<:Expression}, h::UInt)
#     h = hash(size(a), hash(:AbstractArray, h))
#     for x ∈ a
#         h = hash(x, h)
#     end
#     h
# end


# We commandeer `==` to create a constraint.
# Therefore we define `isequal` to still have a notion of equality
# (Normally `isequal` falls back to `==`, so we need to provide a method).
# All `Expression`s (Constraints are not `Expression`s!) are compared by value, except for AbstractVariables, which are compared by `===` (objectid).
isequal(::Object, ::Object) = false

function isequal(x::Expression, y::Expression)
    if typeof(x) != typeof(y)
        return false
    end
    for i in 1:fieldcount(typeof(x))
        if !isequal(getfield(x, i), getfield(y, i))
            return false
        end
    end
    true
end

# Define hash consistently with `isequal`
function hash(x::Expression, h::UInt)
    h = hash(typeof(x), h)
    for i in 1:fieldcount(typeof(x))
        h = hash(getfield(x, i), h)
    end
    h
end

############################################################################################
# IsEqual

# isequal(x1::T, x2::T) where {T<:Expression} = x1 ≡ x2