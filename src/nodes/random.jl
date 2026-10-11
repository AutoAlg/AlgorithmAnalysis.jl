export RandomR, E, mean_component, centered_component, Var, Cov, get_cov_leaf

abstract type RandomField <: Field end

abstract type RandomR <: RandomField end
abstract type RandomRCenteredComponent <: RandomField end

function mean_component(x::Node{RandomR}) 
    if issym(x)
        return leaf(R, Symbol("μ_$(x)"))
    else
        error("Cannot call mean_component on a RandomR that is not a leaf node itself")
    end
end


function centered_component(x::Node{RandomR}) 
    if issym(x)
        return leaf(RandomRCenteredComponent, Symbol("c_$(x)"))
    else
        error("Cannot call centered_component on a RandomR that is not a leaf node itself!")
    end
end

function get_cov_leaf(left::Node{RandomR}, right::Node{RandomR})
    if issym(left) && issym(right)

        if "$(left)" < "$(right)"
            return leaf(R, Symbol("E⟨c_$(left), c_$(right)⟩"))
        else  
            return leaf(R, Symbol("E⟨c_$(right), c_$(left)⟩"))
        end
        
    else
        error("cannot call get_cov_leaf on non leaf nodes")
    end
end

E(x::Node{RandomR})::Node = Term{R}(E, [x])
Var(x::Node{RandomR})::Node = Term{R}(Var, [x])
Cov(left::Node{RandomR}, right::Node{RandomR}) = Term{R}(Cov, [left, right])


E(x::Node{R}) = x
Var(::Node{R}) = zero(R)
Cov(::Node{R}, ::Node{RandomR}) = zero(R)
Cov(::Node{RandomR}, ::Node{R}) = zero(R)
Cov(::Node{R}, ::Node{R}) = zero(R)


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



