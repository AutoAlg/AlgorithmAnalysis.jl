export RandomR, E, mean_component, centered_component, Var, Cov, centered_product_leaf, RandomRⁿ, RandomRⁿCenteredComponent

abstract type RandomField <: Field end

abstract type RandomR <: RandomField end
abstract type RandomRCenteredComponent <: RandomField end

# TODO: rewrite this to have DeterministicVectorSpace and RandomVectorSpace
# both as subspaces of VectorSpace and then do the same thing to RandomField too
abstract type RandomVectorSpace <: NodeType end

abstract type RandomRⁿ <: RandomVectorSpace end
abstract type RandomRⁿCenteredComponent <: RandomVectorSpace end

function mean_component(x::Node{RandomR}) 
    if issym(x)
        return leaf(R, Symbol("μ_$(x)"))
    else
        error("Cannot call mean_component on a RandomR that is not a leaf node itself")
    end
end

function mean_component(x::Node{RandomRⁿ}) 
    if issym(x)
        return leaf(Rⁿ, Symbol("μv_$(x)"))
    else
        error("Cannot call mean_component on a RandomRⁿ that is not a leaf node itself")
    end
end


function centered_component(x::Node{RandomR}) 
    if issym(x)
        return leaf(RandomRCenteredComponent, Symbol("c_$(x)"))
    else
        error("Cannot call centered_component on a RandomR that is not a leaf node itself!")
    end
end

function centered_component(x::Node{RandomRⁿ}) 
    if issym(x)
        return leaf(RandomRⁿCenteredComponent, Symbol("cv_$(x)"))
    else
        error("Cannot call centered_component on a RandomRⁿ that is not a leaf node itself!")
    end
end

# reminder, this HAS to be a black box, otherwise it would
# endlessly recurse via E[XY] => E[X]E[Y] + Cov(X, Y) 
# putting that black box has to be at the lowest level
# i.e the level that lets us assume E[X] == E[Y] == 0
# is this function, give me the expectation of the
# inner product of these two zero mean vectors 
function centered_product_leaf(
    left::Node{RandomRCenteredComponent}, 
    right::Node{RandomRCenteredComponent}
)
    if issym(left) && issym(right)
        if "$(left)" < "$(right)"
            return leaf(R, Symbol("E⟨$(left), $(right)⟩"))
        else  
            return leaf(R, Symbol("E⟨$(right), $(left)⟩"))
        end
    else
        error("cannot call centered_product_leaf on non leaf nodes")
    end
end

function centered_product_leaf(
    left::Node{RandomRⁿCenteredComponent}, 
    right::Node{RandomRⁿCenteredComponent}
)
    if issym(left) && issym(right)
        if "$(left)" < "$(right)"
            return leaf(R, Symbol("E⟨$(left), $(right)⟩"))
        else  
            return leaf(R, Symbol("E⟨$(right), $(left)⟩"))
        end
    else
        error("cannot call centered_product_leaf on non leaf nodes")
    end
end


E(x::Node{R}) = x
Var(::Node{R}) = zero(R)
Cov(::Node{R}, ::Node{RandomR}) = zero(R) # TODO: deduplicate with union{...}
Cov(::Node{RandomR}, ::Node{R}) = zero(R)
Cov(::Node{R}, ::Node{R}) = zero(R)

E(x::Node{Rⁿ}) = x
Var(::Node{Rⁿ}) = zero(R)
Cov(::Node{Rⁿ}, ::Node{RandomRⁿ}) = zero(R)  # TODO: deduplicate with union as above
Cov(::Node{RandomRⁿ}, ::Node{Rⁿ}) = zero(R)
Cov(::Node{Rⁿ}, ::Node{Rⁿ}) = zero(R)

E(x::Node{RandomR}) = Term{R}(E, [x])
E(x::Node{RandomRCenteredComponent}) = issym(x) ? zero(R) : Term{R}(E, [x]) # E(centered_component(X) + 4.0) triggers this and its not zero
Var(x::Node{RandomR}) = Term{R}(Var, [x])
Cov(left::Node{RandomR}, right::Node{RandomR}) = Term{R}(Cov, [left, right])

E(x::Node{RandomRⁿ}) = Term{Rⁿ}(E, [x])
E(x::Node{RandomRⁿCenteredComponent}) = issym(x) ? zero(Rⁿ) : Term{R}(E, [x]) 
# also when writing the paper can I just define the covariance as the inner oroduct rather than the 
# trace of the outer product
Var(x::Node{RandomRⁿ}) = Term{R}(Var, [x]) # TODO: think about how to generalize this fact (RandomR'*RandomR -> R, but rn goes to R still)
Cov(left::Node{RandomRⁿ}, right::Node{RandomRⁿ}) = Term{R}(Cov, [left, right])

Cov(left::Node{RandomRCenteredComponent}, right::Node{RandomRCenteredComponent}) = error("This should never be called")
Cov(left::Node{RandomRⁿCenteredComponent}, right::Node{RandomRⁿCenteredComponent}) = error("This should never be called")

# TODO: once you properly bifrucate VectorSpace into DeterministicVectorSpace and RandomVectorSpace, this should be automatic
Base.adjoint(x::Node{RandomR}) = x
Base.adjoint(x::Node{RandomRCenteredComponent}) = x
Base.adjoint(x::Node{RandomRⁿ}) = Term{CoVector{RandomRⁿ}}(adjoint, [x])
Base.adjoint(x::Node{RandomRⁿCenteredComponent}) = Term{CoVector{RandomRⁿCenteredComponent}}(adjoint, [x])




SymbolicUtils.promote_symtype(::Node{FnType{Tuple{Rⁿ},R,DifferentiableFunctional}}, ::Type{RandomRⁿ}) = RandomR
SymbolicUtils.promote_symtype(::Node{FnType{Tuple{Rⁿ},Rⁿ,Gradient}}, ::Type{RandomRⁿ}) = RandomRⁿ


+(left::Node{R}, right::Node{RandomR}) = Term{RandomR}(+, [left, right])
+(left::Node{RandomR}, right::Node{R}) = right + left

# TODO: HACK: rewrite this to use a true Term with operation == -, this is equivalent but it doesnt look as nice
-(left::Node{R}, right::Node{RandomR}) = left + (R(-1.0) * right)
-(left::Node{RandomR}, right::Node{R}) = left + (R(-1.0) * right)

*(left::Node{R}, right::Node{RandomR}) = Term{RandomR}(*, [left, right])
*(left::Node{RandomR}, right::Node{R}) = right * left


+(left::Number, right::Node{RandomR}) = R(left) + right
+(left::Node{RandomR}, right::Number) = left + R(right)

-(left::Number, right::Node{RandomR}) = R(left) - right
-(left::Node{RandomR}, right::Number) = left - R(right)

*(left::Number, right::Node{RandomR}) = R(left) * right
*(left::Node{RandomR}, right::Number) = left * R(right)



+(left::Node{RandomRⁿ}, right::Node{RandomRⁿ}) = Term{RandomRⁿ}(+, [left, right])
+(left::Node{Rⁿ}, right::Node{RandomRⁿ}) = Term{RandomRⁿ}(+, [left, right])
+(left::Node{RandomRⁿ}, right::Node{Rⁿ}) = right + left

-(left::Node{RandomRⁿ}, right::Node{RandomRⁿ}) = left + (R(-1.0) * right)
-(left::Node{Rⁿ}, right::Node{RandomRⁿ}) =  left + (R(-1.0) * right)
-(left::Node{RandomRⁿ}, right::Node{Rⁿ}) = left + (R(-1.0) * right)


*(left::Node{R}, right::Node{RandomRⁿ}) = Term{RandomRⁿ}(*, [left, right])
*(left::Number, right::Node{RandomRⁿ}) = R(left) * right
*(left::Node{RandomRⁿ}, right::Node{R}) = right * left
*(left::Node{RandomRⁿ}, right::Number) = right * left

# TODO: same as above, this shouldn't exist, but won't after the old VectorSpace is removed
*(left::Node{CoVector{RandomRⁿ}}, right::Node{RandomRⁿ}) = Term{RandomR}(⋅, [arguments(left)[1], right])

*(left::Node{CoVector{RandomRⁿ}}, right::Node{Rⁿ}) = Term{RandomR}(⋅, [arguments(left)[1], right])
*(left::Node{CoVector{Rⁿ}}, right::Node{RandomRⁿ}) = Term{RandomR}(⋅, [arguments(left)[1], right])

*(left::Node{CoVector{RandomRⁿCenteredComponent}}, right::Node{RandomRⁿCenteredComponent}) = Term{RandomR}(⋅, [arguments(left)[1], right])

# TODO: these should be folded into the generalized \codt  impl in linear_algebra.jl
⋅(left::Node{RandomRⁿ}, right::Node{RandomRⁿ}) = left'*right
⋅(left::Node{Rⁿ}, right::Node{RandomRⁿ}) = left'*right
⋅(left::Node{RandomRⁿ}, right::Node{Rⁿ}) = left'*right

Base.literal_pow(::typeof(^), x::Node{<:RandomRⁿ}, ::Val{2}) = x'*x

-(x::Node{RandomRⁿ}) = R(-1.0) * x   
