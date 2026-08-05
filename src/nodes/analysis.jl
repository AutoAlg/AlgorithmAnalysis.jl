export functional, differentiable_functional

const ∇ = Sym{FnType{Tuple{FnType{Tuple{Rⁿ},R,DifferentiableFunctional}},FnType{Tuple{Rⁿ},Rⁿ,Gradient},Nothing}}(:∇)


is_gradient(x) = is_function(x) && isequal(operator(x), ∇)

function convex(f::Node{FnType{Tuple{V},F,DifferentiableFunctional}}) where {F,V<:VectorSpace{F}}
    return Term{Convex}(∈, [f])
end

function smooth_convex(f::Node{FnType{Tuple{V},F,DifferentiableFunctional}}, L::Node{F}) where {F,V<:VectorSpace{F}}
    return Term{Prop}(smooth_convex, [f, L])
end

function sector_bounded(f::Node{FnType{Tuple{V},F,DifferentiableFunctional}}, μ::Node{F}, L::Node{F}) where {F,V<:VectorSpace{F}}
    return Term{Prop}(sector_bounded, [f, μ, L])
end

is_function(t) = t isa Node && typeof(t).parameters[1] <: FnType

function function_category(t::Node)
    fn_type = typeof(t).parameters[1]
    if !is_function(t)
        error("$t is not a function")
    end
    return fn_type.parameters[3]
end

"""
    functional(V)

Create a symbolic functional from a vector space `V` to its underlying scalar field.
"""
function functional(V::Type{<:VectorSpace})
    return FnType{Tuple{V},field(V),Nothing}
end

"""
    differentiable_functional(V)

Create a symbolic differentiable functional from a vector space `V` to its underlying scalar field. For a differentiable function `f`, access its gradient as `f'`.
"""
function differentiable_functional(V::Type{<:VectorSpace})
    return FnType{Tuple{V},field(V),DifferentiableFunctional}
end

function adjoint(f::Node{FnType{Tuple{V},F,DifferentiableFunctional}}) where {F,V<:VectorSpace{F}}
    return ∇(f)
end

domain(::Node{FnType{Tuple{V},F,C}}) where {F,V<:VectorSpace{F},C} = V
codomain(::Node{FnType{Tuple{V},F,C}}) where {F,V<:VectorSpace{F},C} = F
