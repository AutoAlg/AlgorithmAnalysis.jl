export RandomR, E, mean_component, centered_component

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
        error("Cannot call centered_component on a RandomR tat is not a leaf node itself!")
    end
end


E(x::Node{RandomR})::Node = Term{R}(E, [x])

# TODO: by subtyping Field, RandomR * RandomR compiles, should this fail at the jump level or at instantiation time?