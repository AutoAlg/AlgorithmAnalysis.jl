########################################################
# NATURAL NUMBERS
########################################################

struct N <: Space
    zero::Object{N}
    elements::Objects{N}
    successor::Object{SingleValuedMap{N, N}}

    N() = get!(_CACHE, N) do
        zero = Atom{N}(Symbol(0), false)
        elements = Objects{N}()
        push!(elements, zero)
        successor = Atom{SingleValuedMap{N, N}}(:S)
        successor ∈ Invertible{N,N}()
        new( zero, elements, successor )
    end
end

label(::N) = "Natural numbers"
zero(::Type{N}) = N().zero
successor(::Type{N}) = N().successor

function N(a::Int)
    if a < 0
        error("Natural numbers are nonnegative")
    elseif a == 0
        zero(N)
    else
        zero(N) + a
    end
end

function +(a::Object{N}, b::Int)
    if b == 1
        successor(N)(a)
    elseif b > 1
        successor(N)(a) + (b-1)
    else
        error("Natural numbers are nonnegative")
    end
end

+(a::Int, b::Object{N}) = b + a

function +(a::Object{N}, b::Object{N})
    if b === zero(N)
        a
    elseif a === zero(N)
        b
    elseif b ∈ outputs(successor(N))
        successor(N)( a + inv(successor(N))(b) )
    elseif a ∈ outputs(successor(N))
        successor(N)( b + inv(successor(N))(a) )
    else
        error("Unknown value of $a + $b")
    end
end

# @var n ∈ N
# N(2) + n  # does not work, need to simplify S⁻¹(S(a)) = a