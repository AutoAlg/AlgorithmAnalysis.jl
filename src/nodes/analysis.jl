export functional, differentiable_functional
export convex, smooth_convex, smooth_strongly_convex, sector_bounded

const ∇ = Sym{FnType{Tuple{FnType{Tuple{Rⁿ},R,DifferentiableFunctional}},FnType{Tuple{Rⁿ},Rⁿ,Gradient},Nothing}}(:∇)


is_gradient(x) = is_function(x) && isequal(operator(x), ∇)

"""
    convex(f)

Proposition that the differentiable symbolic function `f` is convex.
"""
function convex(f::Node{FnType{Tuple{V},F,DifferentiableFunctional}}) where {F,V<:VectorSpace{F}}
    return Term{Convex}(∈, [f])
end

"""
    smooth_convex(f, L)

Proposition that the differentiable symbolic function `f` is `L`-smooth and convex.
"""
function smooth_convex(f::Node{FnType{Tuple{V},F,DifferentiableFunctional}}, L::Node{F}) where {F,V<:VectorSpace{F}}
    return Term{Prop}(smooth_convex, [f, L])
end

"""
    smooth_strongly_convex(f, μ, L)

Proposition that the differentiable symbolic function `f` is `L`-smooth and `μ`-strongly convex.
"""
function smooth_strongly_convex(f::Node{FnType{Tuple{V},F,DifferentiableFunctional}}, μ::Node{F}, L::Node{F}) where {F,V<:VectorSpace{F}}
    return Term{Prop}(smooth_strongly_convex, [f, μ, L])
end

@doc raw"""
    sector_bounded(f, μ, L)

Proposition that the differentiable symbolic function ``f`` is ``[\mu,L]`` sector bounded, meaning that
```math
    ( \nabla f(x) - \mu x )^\top ( \nabla f(x) - L x ) \leq 0
```
for all vectors ``x`` in the domain of ``f``.
"""
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
