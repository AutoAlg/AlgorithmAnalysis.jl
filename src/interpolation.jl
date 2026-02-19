
############################################################################################
# Properties

abstract type AbstractQuadraticConstraint <: Property{AbstractOperator} end
abstract type AbstractPointwiseQuadraticConstraint <: AbstractQuadraticConstraint end
abstract type AbstractIncrementalQuadraticConstraint <: AbstractQuadraticConstraint end

abstract type AbstractLinearQuadraticConstraint <: Property{AbstractLocallyLipschitzFunctional} end
abstract type AbstractTwoPointLinearQuadraticConstraint <: AbstractLinearQuadraticConstraint end

# ax ‖xi-xj‖² + ay ‖yi-yj‖² ≤ (xi-xj)'*(yi-yj) ≤ bx ‖xi-xj‖² + by ‖yi-yj‖²
"""
    PointwiseQuadraticConstraint(M, x, y)

A generic pointwise quadratic constraint.
"""
struct PointwiseQuadraticConstraint <: AbstractPointwiseQuadraticConstraint
    M::Matrix{Real}
    x::VectorSpace
    y::VectorSpace
end

"""
    IncrementalQuadraticConstraint(M)

A generic incremental quadratic constraint.
"""
struct IncrementalQuadraticConstraint <: AbstractIncrementalQuadraticConstraint
    M::Matrix{Real}
end

# """
#     PointwiseLinearQuadraticConstraint(M, m, x, y, f)

# A generic pointwise linear--quadratic constraint.
# """
# struct PointwiseLinearQuadraticConstraint <: AbstractPointwiseLinearQuadraticConstraint
#     M::Matrix{Real}
#     m::Vector{Real}
#     x::VectorSpace
#     y::VectorSpace
#     f::Field
# end

"""
    TwoPointLinearQuadraticConstraint(M, m)

A generic incremental linear--quadratic constraint.
"""
struct TwoPointLinearQuadraticConstraint <: AbstractTwoPointLinearQuadraticConstraint
    M::Matrix{Real}
    m::Vector{Real}
end

"""
    SlopeRestricted(a,b)

A slope-restricted constraint.
"""
struct SlopeRestricted <: AbstractIncrementalQuadraticConstraint
    a::Real
    b::Real
end

"""
SectorBounded(a,b)

A sector-bounded constraint.
"""
struct SectorBounded <: AbstractPointwiseQuadraticConstraint
    a::Real
    b::Real
    x::VectorSpace
    y::VectorSpace
end

# ax ‖xi-xj‖² + ay ‖yi-yj‖² ≤ (xi-xj)'*(yi-yj) ≤ bx ‖xi-xj‖² + by ‖yi-yj‖²
"""
    Monotone


"""
struct Monotone{a,b} <: Property{AbstractOperator} end
struct Comonotone{a,b} <: Property{AbstractOperator} end                       # a ‖yi-yj‖² ≤ (xi-xj)'*(yi-yj) ≤ b ‖yi-yj‖²
struct WeaklyMonotone{a,b,xs,ys} <: Property{AbstractOperator} end             # a ‖x -xs‖² ≤ (x -xs)'*(y -ys) ≤ b ‖x -xs‖²
struct WeaklyComonotone{a,b,xs,ys} <: Property{AbstractOperator} end           # a ‖y -ys‖² ≤ (x -xs)'*(y -ys) ≤ b ‖y -ys‖²

"""
    RelativelyBounded(a,b,x,y)

The property that an operator is relatively bounded.

``a^2\\,\\|x_i-x_j\\|^2 \\leq \\|y_i-y_j\\|^2 \\leq b^2\\,\\|x_i-x_j\\|^2``
"""
struct RelativelyBounded <: Property{AbstractOperator} # a² ‖xi-xj‖² ≤ ‖yi-yj‖² ≤ b² ‖xi-xj‖²
    a::Real
    b::Real
    x::Union{NormedVectorSpace, Missing}
    y::Union{NormedVectorSpace, Missing}
    
    RelativelyBounded(a,b,x=missing,y=missing) = new(a,b,x,y)
end

struct Bounded{b} <: Property{NormedVectorSpace} end                            # ‖xi-xj‖² ≤ b²
# struct Cobounded{b} <: Property{NormedVectorSpace} end                          # ‖yi-yj‖² ≤ b²
struct WeaklyBounded{b,xs} <: Property{NormedVectorSpace} end                   # ‖x -xs‖² ≤ b²
# struct WeaklyCobounded{b,ys} <: Property{NormedVectorSpace} end                 # ‖y -ys‖² ≤ b²
struct Convex <: Property{VectorSpace} end

"Linearity property. Applies to AbstractLinearMap oracles."
struct Linear <: Property{AbstractLinearMap} end                       # X ⊗ V = Y ⊗ U (or x'*v = y'*u for (x,y) ∈ r and (u,v) ∈ r')
struct Symmetric <: Property{AbstractSymmetricLinearMap} end           # X ⊗ Y = Y ⊗ X and U ⊗ V = V ⊗ U (or xi'*yj == yi'*xj for (xi,yi) and (xj,yj) ∈ r ∪ r')
struct SkewSymmetric <: Property{AbstractSkewSymmetricLinearMap} end   # X ⊗ V = 0 and Y ⊗ U = 0 and X ⊗ Y + Y ⊗ X = 0 and U ⊗ V + V ⊗ U = 0
struct MaxSingularValue{b} <: Property{AbstractLinearMap} end          # Y ⊗ Y ⪯ b² (X ⊗ X) and V ⊗ V ⪯ b² (U ⊗ U)

struct Eigenvalues{a,b} <: Property{AbstractSymmetricLinearMap} end    # (Y-aX) ⊗ (bX-Y) ⪰ 0

# struct Nonexpansive{v} <: OperatorProperty end              # Lipschitz{1} and v² ≤ (x-y)'*v

# Lipschitz continuous  = RelativelyBounded{0,L}
# Strongly monotone     = Monotone{μ,∞}
# One-sided Lipschitz   = Monotone{-∞,L}
# Cocoercive            = Comonotone{β,∞}
# Negatively comonotone = Comonotone{-ρ,∞}

# function properties

# fi-fj ≥ gj'*(xi-xj) + 1/2L (gi-gj)² + μ/(2(1-μ/L)) (xi-xj-1/L (gi-gj))²
"""
    SmoothStronglyConvex(a,b)

Property of a locally Lipschitz functional that is `b`-smooth and `a`-strongly convex.

``f_i-f_j \\geq \\langle g_j,x_i-x_j\\rangle + \\frac{1}{2b} \\|g_i-g_j\\|^2 + \\frac{a}{2(1-a/b)} \\|x_i-x_j-\\frac{1}{b} (g_i-g_j)\\|^2``
"""
struct SmoothStronglyConvex <: AbstractTwoPointLinearQuadraticConstraint
    a::Real
    b::Real
end

# fs-f ≥ g'*(xs-x) + 1/2L (gs-g)² + μ/(2(1-μ/L)) (xs-x-1/L (gs-g))²
struct WeakCurvature{μ,L,xs,fs,gs} <: Property{AbstractSubdifferentiableFunctional} end

# fi-fj ≥ gj'*(xi-xj) + 1/2L gj²
struct QuadraticGrowth{μ} <: Property{AbstractSubdifferentiableFunctional} end


"""
    reference(p)

Reference point of a pointwise constraint.
"""
reference(p::AbstractPointwiseQuadraticConstraint) = (p.x, p.y)

"""
    quadraticform(p)

Quadratic form of a quadratic constraint.
"""
quadraticform(p::PointwiseQuadraticConstraint) = p.M
quadraticform(p::IncrementalQuadraticConstraint) = p.M
quadraticform(p::SlopeRestricted) = [-2*p.a 1+p.a/p.b; 1+p.a/p.b -2/p.b]
quadraticform(p::SectorBounded) = [-2*p.a 1+p.a/p.b; 1+p.a/p.b -2/p.b]

"""
    linearquadraticform(p)

Linear--quadratic form of a constraint.
"""
linearquadraticform(p::TwoPointLinearQuadraticConstraint) = (p.m, p.M)
linearquadraticform(p::SmoothStronglyConvex) = ((1-p.a/p.b)*[1; -1], 0.5*[-p.a p.a p.a/p.b -1; p.a -p.a -p.a/p.b 1; p.a/p.b -p.a/p.b -1/p.b 1/p.b; -1 1 1/p.b -1/p.b])
# linearquadraticform(p::SmoothStronglyConvex) = ([0; 0], 0.5*[-p.a p.a p.a/p.b -1; p.a -p.a -p.a/p.b 1; p.a/p.b -p.a/p.b -1/p.b 1/p.b; -1 1 1/p.b -1/p.b])


############################################################################################
# Subsets

# ∈(s::Subset{<:T}, p::Property{T}) where {T} = push!(s.properties, p)


############################################################################################
# Constraints

"""
    constraints(o::Oracle)
    constraints(o::Oracle, p::Property)
    constraints(e::Expression)

Return the constraints information of an input depending on its type:
- **Oracle**
Return all constraints for an oracle, or the constraints for an oracle given a property.
- **Expression**
Return a list of constraints the expression `e` is in.

# Examples
```julia-repl
julia> x = Rⁿ()
julia> constraints(x)
```
"""
function constraints end

constraints(o::Wrapper, p::Property) = constraints(unwrap(o), p)

function constraints(o::OracleOrWrapper)
    cons1 = mapreduce(p -> constraints(o,p), ∪, properties(o); init=Constraints())
    cons2 = mapreduce(constraints, ∪, values(associations(o)); init=Constraints())
    cons1 ∪ cons2
end

# function constraints(o::OracleOrWrapper, checked)
#     if o ∈ checked
#         return Constraints()
#     else
#         push!(checked, o)
#         cons = mapreduce(p -> constraints(o,p), ∪, properties(o); init=Constraints())
#         # cons2 = mapreduce(constraints, ∪, values(associations(o)); init=Constraints())
#         for a in values(associations(o))
#             union!(cons, constraints(a, checked))
#         end
#         cons
#     end
# end
# constraints(o::OracleOrWrapper) = constraints(o, Set())

# Operators

function constraints(o::AbstractOperator, p::AbstractPointwiseQuadraticConstraint)
    xs, ys = reference(p)
    Constraints( 0 ≤ [x-xs; y-ys]'*quadraticform(p)*[x-xs; y-ys] for (x,y) ∈ o )
end

function constraints(o::AbstractOperator, p::AbstractIncrementalQuadraticConstraint)
    Constraints( 0 ≤ [xᵢ-xⱼ; yᵢ-yⱼ]'*quadraticform(p)*[xᵢ-xⱼ; yᵢ-yⱼ] for (xᵢ,yᵢ) ∈ o, (xⱼ,yⱼ) ∈ o )
end

triplets(o::AbstractLocallyLipschitzFunctional) = Set( (x,o(x),o'(x)) for (x,y) ∈ o ) ∪ Set( (x,o(x),o'(x)) for (x,_) ∈ o' )

# function constraints(o::AbstractLocallyLipschitzFunctional, p::AbstractPointwiseLinearQuadraticConstraint)
#     m, M = linearquadraticform(p)
#     xs, fs, gs = reference(p)
#     Constraints( 0 ≤ m'*[f; fs] + [x; xs; g; gs]'*M*[x; xs; g; gs] for (x,f,g) ∈ triplets(o) )
# end

function constraints(o::AbstractLocallyLipschitzFunctional, p::AbstractTwoPointLinearQuadraticConstraint)
    m, M = linearquadraticform(p)
    Constraints( 0 ≤ m'*[fᵢ; fⱼ] + [xᵢ; xⱼ; gᵢ; gⱼ]'*M*[xᵢ; xⱼ; gᵢ; gⱼ] for (xᵢ,fᵢ,gᵢ) ∈ triplets(o), (xⱼ,fⱼ,gⱼ) ∈ triplets(o) )
end

# function constraints(o::AbstractLocallyLipschitzFunctional, p::SmoothStronglyConvex)
#     a, b = p.a, p.b
#     if o isa AbstractSubdifferentiableFunctional && b < Inf
#         @warn "`SubdifferentiableFunctional` $o is constrained to be $b-smooth implying that it is differentiable. Use `DifferentiableFunctional` instead."
#     end
#     Constraints( fᵢ-fⱼ ≥ gⱼ'*(xᵢ-xⱼ) + 1/2b*(gᵢ-gⱼ)^2 + a/(2*(1-a/b))*(xᵢ-xⱼ-1/b*(gᵢ-gⱼ))^2 for (xᵢ,fᵢ,gᵢ) ∈ triplets(o), (xⱼ,fⱼ,gⱼ) ∈ triplets(o) )
# end


function constraints(o::AbstractOperator, p::RelativelyBounded)
    a, b = p.a, p.b
    if ismissing(p.x) && ismissing(p.y)
        constraints(o, PointwiseQuadraticConstraint([]))
        Constraints( a^2*(xi-xj)^2 ≤ (yi-yj)^2 for (xi,yi) ∈ o, (xj,yj) ∈ o ) ∪ Constraints( (yi-yj)^2 ≤ b^2*(xi-xj)^2 for (xi,yi) ∈ o, (xj,yj) ∈ o )
    else
        xs, ys = p.x, p.y
        Constraints( a^2*(x-xs)^2 ≤ (y-ys)^2 for (x,y) ∈ o ) ∪ Constraints( (y-ys)^2 ≤ b^2*(x-xs)^2 for (x,y) ∈ o )
    end
end

function constraints(r1::Relation{X,X}, r2::Relation{X,X}, ::Monotone{a,b}) where {X<:InnerProductSpace, a, b}
    Constraints( 0 ≤ (xi-xj)'*(yi-yj-a*(xi-xj)) for (xi,yi) ∈ r1, (xj,yj) ∈ r2 if !isequal(xi,xj) ) ∪ Constraints( (xi-xj)'*(yi-yj) ≤ b*(xi-xj)^2 for (xi,yi) ∈ r1, (xj,yj) ∈ r2 if !isequal(xi,xj) )
end

# Linear maps
function constraints(o::AbstractLinearMap{X,Y}, ::Linear) where {F<:Field, X<:InnerProductSpace{F}, Y<:InnerProductSpace{F}}
    Constraints( x'*v == y'*u for (x,y) ∈ o, (u,v) ∈ o' )
end
# Linear operators, L interpolable
function constraints(o::AbstractLinearMap{X,Y}, ::Linear, L) where {F<:Field, X<:InnerProductSpace{F}, Y<:InnerProductSpace{F}}
    # Constraints( y'*y - L^2*(x'*x) ⪯ 0 for (x,y) ∈ o)
    # Constraints( v'*v - L^2*(u'*u) ⪯ 0 for (u,v) ∈ o')
    x, y = inputs_outputs(o)
    u, v = inputs_outputs(o')
    Constraints([y⊗y - L^2*(x⊗x) ⪯ 0, v⊗v - L^2*(u⊗u) ⪯ 0])
    # Constraints([v⊗v - L^2*(u⊗u) ⪯ 0])
end

function constraints(o::AbstractLinearMap{X,X}, ::Symmetric) where {X<:InnerProductSpace}
    Constraints( xᵢ'*yⱼ == yᵢ'*xⱼ for (xᵢ,yᵢ) ∈ o, (xⱼ,yⱼ) ∈ o )
end

function constraints(o::AbstractLinearMap{X,X}, ::SkewSymmetric) where {X<:InnerProductSpace}
    Constraints( xᵢ'*yⱼ + yᵢ'*xⱼ == 0 for (xᵢ,yᵢ) ∈ o, (xⱼ,yⱼ) ∈ o )
end

# Symmetric linear maps

function constraints(o::AbstractSymmetricLinearMap{X}, ::Eigenvalues{μ,L}) where {X<:InnerProductSpace, μ, L}
    x, y = inputs_outputs(o)
    Constraints([ (y-μ*x) ⊗ (L*x-y) ⪰ 0 ])
end

function allvecs(o::AbstractLinearFunctional)
    vecs = inputs(o)
    while true
        vecs_new = inputs( filter( x -> x isa AbstractLinearFunctional, oracles(vecs) ) )
        if vecs_new ⊆ vecs
            break
        end
        union!( vecs, vecs_new )
    end
    vecs
end

function constraints(o::AbstractLinearFunctional, ::Linear)
    vecs = collect(allvecs(o))
    for v ∈ vecs, w ∈ vecs
        if !ismissing(next(v)) && !ismissing(next(w))
            update!( v'*w => next(v)'*next(w) )
        end
    end
    Constraints([ vecs ⊗ vecs ⪰ 0 ])
end

function gram end
# gram(o::Wrapper, p::Property) = gram(unwrap(o), p)
# function gram(o::OracleOrWrapper, checked)
#     if o ∈ checked
#         return Set()
#     else
#         push!(checked, o)
#         cons = mapreduce(p -> gram(o,p), ∪, properties(o); init=Set())
#         # cons2 = mapreduce(constraints, ∪, values(associations(o)); init=Constraints())
#         for a in values(associations(o))
#             union!(cons, gram(a, checked))
#         end    
#         cons
#     end
# end
gram(o::OracleOrWrapper) = gram(unwrap(o))
function gram(o::AbstractLinearFunctional)
    vecs = collect(allvecs(o))
    for v ∈ vecs, w ∈ vecs
        if !ismissing(next(v)) && !ismissing(next(w))
            update!( v'*w => next(v)'*next(w) )
        end
    end
    Gram(vecs)
end

interpolate(o::Oracle) = @warn "Interpolating oracle not implemented for $o"
interpolate(w::Wrapper) = interpolate(unwrap(w))

function interpolate(o::AbstractLinearFunctional)
    vecs = collect(allvecs(o))
    # factor Gram matrix to set the value of each vector
    G = value(vecs ⊗ vecs)
    E = la.eigen(G)
    Λ = E.values
    if any(Λ .≤ 0)
        @warn "Gram matrix is not positive semidefinite; eigenvalues are $Λ."
        Λ = abs.(Λ)
    end
    for i = 1:length(vecs)
        value!( vecs[i], sqrt.(Λ) .* E.vectors[i,:] )
    end
end


# ConvexIndicator{D} = Curvature{0,∞} and BoundedRadius{∞,0} and BoundedDiameter{D,∞}
# WeakStrongConvexity{μ,xs,fs,gs} = WeakCurvature{μ,∞,xs,fs,gs}
# RestrictedSecant{μ,xs,ys} = WeaklyMonotone{μ,∞,xs,ys}
# ErrorBound{L}: (yi-yj)² ≤ L² (xi-xj)²  (Lipschitz?)

# Lipschitz (?): y^2 ≤ M^2
# fenchel value
# block constraints


# constraints(o::LinearOperator) = Constraints( X ⊗ V == Y ⊗ U )








# ###############################################################################
# # Relation classes

# abstract type FunctionClass <: RelationClass end
# abstract type OperatorClass <: RelationClass end

# # function class primitives
# struct Curvature{μ,L} <: FunctionClass end
# # struct Smooth{L} <: FunctionClass end
# # struct Convex <: FunctionClass end
# # struct StronglyConvex{μ} <: FunctionClass end
# # struct ConvexIndicator{D} <: FunctionClass end
# struct QuadraticGrowth{μ} <: FunctionClass end
# struct ZeroFunction <: FunctionClass end

# # struct BlockSmoothConvex{L} <: FunctionClass end

# # operator class primitives
# struct LinearOperator <: OperatorClass end
# struct Monotone <: OperatorClass end
# struct Symmetric <: OperatorClass end
# struct Eigenvalues{μ,L} <: OperatorClass end
# struct MaxSingularValue{L} <: OperatorClass end
# struct SkewSymmetric <: OperatorClass end
# struct Cocoercive{β} <: OperatorClass end
# struct StronglyMonotone{μ} <: OperatorClass end
# struct Nonexpansive{v} <: OperatorClass end
# struct NegativelyComonotone{ρ} <: OperatorClass end
# struct Lipschitz{L} <: RelationClass end

# # relation class primitives
# struct ZeroImage <: RelationClass end
# struct ZeroPreimage <: RelationClass end


# # Interpolation conditions not known
# # Lipschitz{L} ∩ StronglyMonotoneOperator{μ}
# # CocoerciveOperator{β} ∩ StronglyMonotoneOperator{μ}


# ###############################################################################
# # Interpolation conditions
# ###############################################################################

# const Triplets{X,F} = Set{Tuple{X,F,X}}

# function triplets(o::ConvexFunction)
#   p = samples(o)
#   d = samples(o')
  
#   (x,o(x),evalute(o',x))
# end

# one_point_constraint(o::Oracle, f::Function) = prune(Constraints( f(x) for x ∈ samples(o) ))
# two_point_constraint(o::Oracle, f::Function) = prune(Constraints( f(x,y) for x ∈ samples(o), y ∈ samples(o) ))

# one_point_constraint(o::Functional, f::Function) = prune(Constraints( f(x) for x ∈ triplets(o) ))
# two_point_constraint(o::Functional, f::Function) = prune(Constraints( f(x,y) for x ∈ triplets(o), y ∈ triplets(o) ))

# "Interpolation conditions for an oracle and relation class. Returns a set of constraints."
# function interpolation_conditions end


# "All interpolation conditions for an oracle."
# interpolation_conditions(o::Oracle) = mapreduce(fc -> interpolation_conditions(o,fc), ∪, classes(r); init=Constraints())




# ###############################################################################
# # Functions

# # Relation = Set{<:Tuple}

# # function interpolation_conditions(o::Functional, ::Convex)
# #   two_point_constraint(o, ((x1,f1,g1),(x2,f2,_)) -> f2 ≥ f1 + g1*(x2-x1) )
# # end

# """
#   Interpolation conditions for the class of L-smooth and μ-strongly convex functions.
  
#   A. Taylor, J. Hendrickx, F. Glineur (2017).
#   Exact worst-case performance of first-order methods for composite convex optimization.
#   SIAM Journal on Optimization, 27(3):1283–1313.
#   <https://arxiv.org/pdf/1512.07516.pdf>
# """
# function interpolation_conditions(o::Functional, ::Curvature{μ,L}) where {μ,L}
#   two_point_constraint(o, ((x1,f1,g1),(x2,f2,g2)) ->
#     f2-f1-g1*(x2-x1) ≥ 1/(2*(1-μ/L))*(1/L*(g2-g1)^2 + μ*(x2-x1)^2 - 2μ/L*(g2-g1)*(x2-x1)) )
# end

# """
#   Interpolation conditions for the class of convex indicator functions.
  
#   A. Taylor, J. Hendrickx, F. Glineur (2017).
#   Exact worst-case performance of first-order methods for composite convex optimization.
#   SIAM Journal on Optimization, 27(3):1283–1313.
#   <https://arxiv.org/pdf/1512.07516.pdf>
#   Theorem 3.6
# """
# function interpolation_conditions(o::Functional, ::ConvexIndicator{D}) where {D}
#   interpolation_conditions(o, Convex()) ∪
#   interpolation_conditions(o, ZeroFunction()) ∪
#   interpolation_conditions(o, BoundedDomain{D}())
# end

# """
#   Interpolation conditions for the class of functions that are zero on the domain.
# """
# function interpolation_conditions(o::Functional, ::ZeroFunction)
#   Constraints( f == 0 for f ∈ image(o) )
# end

# """
#   Interpolation conditions for the class of functions with bounded domain.
# """
# function interpolation_conditions(o::Functional, ::BoundedDomain{D}) where {D}
#   Constraints( (xi-xj)^2 ≤ D^2 for xi ∈ preimage(o,o'), xj ∈ preimage(o,o') )
# end

# """
#   Interpolation conditions for the class of functions with quadratic growth.
  
#   References:
#     B. Goujaud, A. Taylor, A. Dieuleveut (2022).
#     Optimal first-order methods for convex functions with a quadratic upper bound.
#     <https://arxiv.org/pdf/2205.15033.pdf>
#     Theorem 2.6
# """
# function interpolation_conditions(o::Functional, ::QuadraticGrowth{L}) where {L}
#   two_point_constraint(o, ((xi,fi,gi),(xj,fj,gj)) -> fi-fj ≥ (xi-xj) ⋅ gj + 1/(2L)*gj^2)
# end


# ###############################################################################
# # Operators

# """
#   Interpolation conditions for the class of linear operators.
# """
# function interpolation_conditions(X::𝐗, Y::𝐘, U::𝐔, V::𝐕, ::Linear) where {𝐗,𝐘,𝐔,𝐕}
#   # X = Vector{𝐗}(inputs(o))
#   # Y = Vector{𝐘}(outputs(o))
#   # U = Vector{𝐘}(inputs(o'))
#   # V = Vector{𝐗}(outputs(o'))
#   # Constraints( x ⋅ v == y ⋅ u for (x,y) ∈ o, (u,v) ∈ o' )
#   if 𝐗 ≠ 𝐕 || 𝐘 ≠ 𝐔
#     error("Spaces inconsistent for a linear operator.")
#   end
#   Constraints( X ⊗ V == Y ⊗ U )
# end

# """
#   Interpolation conditions for the class of symmetric linear operators.
# """
# function interpolation_conditions(X::𝐗, Y::𝐘, U::𝐔, V::𝐕, ::Symmetric) where {𝐗,𝐘,𝐔,𝐕}
#   if 𝐗 ≠ 𝐘 || 𝐗 ≠ 𝐔 || 𝐗 ≠ 𝐕
#     error("Spaces inconsistent for a symmetric linear operator.")
#   end
#   Constraints( [X; U] ⊗ [Y; V] == [Y; V] ⊗ [X; U] )
#   # Constraints( xi ⋅ yj == yi ⋅ xj for (xi,yi) ∈ o, (xj,yj) ∈ o )
# end

# """
#   Interpolation conditions for the class of skew-symmetric linear operators.
# """
# function interpolation_conditions(X::𝐗, Y::𝐘, U::𝐔, V::𝐕, ::SkewSymmetric) where {𝐗,𝐘,𝐔,𝐕}
#   if 𝐗 ≠ 𝐘 || 𝐗 ≠ 𝐔 || 𝐗 ≠ 𝐕
#     error("Spaces inconsistent for a skew-symmetric linear operator.")
#   end
#   Constraints( [X; U] ⊗ [Y; V] + [Y; V] ⊗ [X; U] == 0 )
#   # Constraints( xi ⋅ yj + xj ⋅ yi == 0 for (xi,yi) ∈ o, (xj,yj) ∈ o )
# end

# """
#   Interpolation conditions for the class of linear operators with maximum singular value upper bounded by L.

#   N. Bousselmi, J. Hendrickx, F. Glineur (2023).
#   Interpolation Conditions for Linear Operators and applications to Performance Estimation Problems.
#   arXiv <https://arxiv.org/pdf/2302.08781.pdf>
#   Theorem 3.1
# """
# function interpolation_conditions(X::𝐗, Y::𝐘, U::𝐔, V::𝐕, ::MaxSingularValue{L})  where {𝐗,𝐘,𝐔,𝐕,L}
#   if Linear() ∉ classes(o)
#     error("Only linear operators have singular values.")
#   end
#   Constraints( Y ⊗ Y ⪯ L^2*(X ⊗ X) ) ∪ Constraints( V ⊗ V ⪯ L^2*(U ⊗ U) )
# end

# """
#   Interpolation conditions for the class of skew-symmetric linear operators with maximum singular value upper bounded by L.
  
#   N. Bousselmi, J. Hendrickx, F. Glineur (2023).
#   Interpolation Conditions for Linear Operators and applications to Performance Estimation Problems.
#   arXiv <https://arxiv.org/pdf/2302.08781.pdf>
#   Corollary 3.2
# """
# function interpolation_conditions(o::Oracle, ::MaxSingularValue{L}) where {L}
#   X = Vector{Expression{Point}}(o.inputs)
#   Y = Vector{Expression{Point}}(o.outputs)
#   (X ⊗ Y + Y ⊗ X == 0) ∪ Constraints([Y ⊗ Y ⪯ L^2*(X ⊗ X)])
# end



# """
#   Interpolation conditions for the class of symmetric linear operators with eigenvalues in the closed interval [μ,L].

#   N. Bousselmi, J. Hendrickx, F. Glineur (2023).
#   Interpolation Conditions for Linear Operators and applications to Performance Estimation Problems.
#   arXiv <https://arxiv.org/pdf/2302.08781.pdf>
#   Theorem 3.3
# """
# function interpolation_conditions(o::LinearOperator, ::Eigenvalues{μ,L}) where {μ,L}
#   X = Vector{Expression{Point}}(o.inputs)
#   Y = Vector{Expression{Point}}(o.outputs)
#   (X ⊗ Y == Y ⊗ X) ∪ Constraints([(Y-μ*X) ⊗ (L*X-Y) ⪰ 0])
# end

# """
#   Interpolation conditions for the class of monotone operators.
  
#   H. H. Bauschke and P. L. Combettes (2017).
#   Convex Analysis and Monotone Operator Theory in Hilbert Spaces.
#   Springer New York, 2nd ed.
#   Theorem 20.21
# """
# function interpolation_conditions(o::Oracle, ::Monotone)
#   two_point_constraint(o, ((xi,gi),(xj,gj)) -> (gi-gj)*(xi-xj) ≥ 0)
# end

# function interpolation_conditions(o::Oracle, ::Cocoercive{β}) where {β}
#   two_point_constraint(o, ((xi,gi),(xj,gj)) -> (gi-gj)*(xi-xj) ≥ β*(gi-gj)^2)
# end

# """
#   Interpolation conditions for the class of strongly monotone operators.
  
#   E. Ryu, A. Taylor, C. Bergeling, P. Giselsson (2020).
#   Operator splitting performance estimation: Tight contraction factors and optimal parameter selection.
#   SIAM Journal on Optimization, 30(3), 2251-2271.
#   <https://arxiv.org/pdf/1812.00146.pdf>
#   Section 2
# """
# function interpolation_conditions(o::Oracle, ::StronglyMonotone{μ}) where {μ}
#   two_point_constraint(o, ((xi,gi),(xj,gj)) -> (gi-gj)*(xi-xj) ≥ μ*(xi-xj)^2)
# end

# """
#   Interpolation conditions for the class of nonexpansive operators.
  
#   Each nonexpansive operator has a unique vector called the `infimal displacement vector`, which we denote by v.
  
#   If a nonexpansive operator is consistent, i.e., has a fixed point, then v=0.

#   If v is nonzero, a nonexpansive operator is inconsistent, i.e., does not have a fixed point.

#   References:
#     E. Ryu, A. Taylor, C. Bergeling, P. Giselsson (2020).
#     Operator splitting performance estimation: Tight contraction factors and optimal parameter selection.
#     SIAM Journal on Optimization, 30(3), 2251-2271.
#     <https://arxiv.org/pdf/1812.00146.pdf>

#     J. Park, E. Ryu (2023).
#     Accelerated Infeasibility Detection of Constrained Optimization and Fixed-Point Iterations.
#     arXiv preprint:2303.15876.
#     <https://arxiv.org/pdf/2303.15876.pdf>
# """
# function interpolation_conditions(o::Oracle, ::Nonexpansive{v}) where {v}
#   two_point_constraint(o, ((xi,gi),(xj,gj)) -> (gi-gj)^2 ≤ (xi-xj)^2) ∪
#   one_point_constraint(o, (x,g) -> v^2 ≤ (xi-gi)*v)
# end

# """
#   Interpolation conditions for the class of negatively comonotone operators (may not be sufficient) with comonotonicity parameter ρ > 0.
  
#   References:
#     E. Gorbunov, A. Taylor, S. Horváth, G. Gidel (2023).
#     Convergence of proximal point and extragradient-based methods beyond monotonicity: the case of negative comonotonicity.
#     International Conference on Machine Learning.
#     <https://proceedings.mlr.press/v202/gorbunov23a/gorbunov23a.pdf>
# """
# function interpolation_conditions(o::Oracle, ::NegativelyComonotone{ρ}) where {ρ}
#   two_point_constraint(o, ((xi,gi),(xj,gj)) -> (gi-gj)*(xi-xj) + ρ*(gi-gj)^2 ≥ 0)
# end

# """
#   Interpolation conditions for the class of Lipschitz operators.
  
#   References:
#   [1] M. Kirszbraun (1934).
#   Uber die zusammenziehende und Lipschitzsche transformationen.
#   Fundamenta Mathematicae, 22 (1934).

#   [2] F.A. Valentine (1943).
#   On the extension of a vector function so as to preserve a Lipschitz condition.
#   Bulletin of the American Mathematical Society, 49 (2).

#   [3] F.A. Valentine (1945).
#   A Lipschitz condition preserving extension for a vector function.
#   American Journal of Mathematics, 67(1).

#   Discussions and appropriate pointers for the interpolation problem can be found in:
#   [4] E. Ryu, A. Taylor, C. Bergeling, P. Giselsson (2020).
#   Operator splitting performance estimation: Tight contraction factors and optimal parameter selection.
#   SIAM Journal on Optimization, 30(3), 2251-2271.
#   <https://arxiv.org/pdf/1812.00146.pdf>
# """
# function interpolation_conditions(o::Oracle, ::Lipschitz{L}) where {L}
#   two_point_constraint(o, ((xi,gi),(xj,gj)) -> (gi-gj)^2 ≤ L^2*(xi-xj)^2)
# end
