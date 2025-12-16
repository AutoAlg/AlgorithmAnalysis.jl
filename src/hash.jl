import Base.hash

"""
    hash(x, h::UInt)

Hash of an expression. Custom types must provide specialized methods for this function due to [this issue](https://github.com/JuliaLang/julia/issues/10267).
"""
function hash end

# hash(x::Component, h::UInt) = hash(objectid(x), h)

# function hash(a::AbstractArray{<:Component}, h::UInt)
#     h = hash(size(a), hash(:AbstractArray, h))
#     for x ∈ a
#         h = hash(x, h)
#     end
#     h
# end

# We commandeer `==` to create a constraint.
# Therefore we define `isequal` to still have a notion of equality
# (Normally `isequal` falls back to `==`, so we need to provide a method).
# All `Object`s are compared by value.
isequal(::Component, ::Any) = false
isequal(::Any, ::Component) = false

function isequal(x::Component, y::Component)
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
function hash(x::Component, h::UInt)
    h = hash(typeof(x), h)
    for i in 1:fieldcount(typeof(x))
        h = hash(getfield(x, i), h)
    end
    h
end

hash(p::Property, h::UInt) = hash(typeof(p), h)
hash(c::Constraint, h::UInt) = hash(objectid(c), h)

# isequal(x::Component, y::Component) = isequal(objectid(x), objectid(y))
# hash(x::Component, h::UInt) = hash(objectid(x), h)

############################################################################################
# IsEqual

# isequal(x1::T, x2::T) where {T<:Expression} = x1 ≡ x2

# isequal(x::Property, y::Property) = isequal(objectid(x), objectid(y))

function isequal(x::Object{CartesianProduct{T}}, y::Object{CartesianProduct{T}}) where T
    # dict = CartesianProduct{T}().dict
    # if x ∈ keys(dict) && y ∈ keys(dict) #&& isequal(dict[x], dict[y])
    #     true
    # else
    #     false
    # end
    isequal(as_tuple(x), as_tuple(y))
end