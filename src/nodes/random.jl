export RandomR, E, mean_component, centered_component, Var, Cov, get_cov_leaf

abstract type RandomR <: Field end

function mean_component(x::Node{RandomR}) 
    if issym(x)
        return leaf(R, Symbol("μ_$(x)"))
    else
        error("Cannot call mean_component on a RandomR that is not a leaf node itself")
    end
end


function centered_component(x::Node{RandomR}) 
    if issym(x)
        return leaf(R, Symbol("c_$(x)"))
    else
        error("Cannot call centered_component on a RandomR that is not a leaf node itself!")
    end
end


E(x::Node{RandomR})::Node = Term{R}(E, [x])

# Var(X)
# Cov(X, X)
# E<c_X, c_X>
# E||c_X||^2
Var(x::Node{RandomR})::Node = Term{R}(Var, [x])

Cov(left::Node{RandomR}, right::Node{RandomR}) = Term{R}(Cov, [left, right])

function get_cov_leaf(left::Node{RandomR}, right::Node{RandomR})
    if issym(left) && issym(right)
        return leaf(R, Symbol("E⟨$(left), $(right)⟩")) # TODO: flatten if theyre the same and also this E is different...
    else
        error("cannot call get_cov_leaf on non leaf nodes")

    end

end

