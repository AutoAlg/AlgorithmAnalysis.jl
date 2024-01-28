############################################################################################
# Gram matrix

"A Gram matrix over a field."
struct GramMatrix{V<:InnerProductSpace} <: Expression
    label::String
    value::Union{Matrix{Number},Missing}
    decomposition::Matrix
end

"Constructor."
GramMatrix{V}(m::Matrix{F}) where {F<:Field, V<:InnerProductSpace{F}} = GramMatrix{V}( "", missing, (m+m')/2 )

zero(::F) where {F<:Field} = F(0)
zero(::V) where {V<:VectorSpace} = V(Zero())


############################################################################################
# Macro definitions of concrete expression types

"Define a field."
macro field(s::Symbol)
    quote
        mutable struct $(esc(s)) <: Field
            label::String
            value::Union{Number,Missing}
            decomposition::AffineDecomposition{$(esc(s))}
            constraints::Constraints
        end
    end
end

"Define a vector space over a field."
macro vectorspace(ex::Expr)
    if !(ex.head == :tuple && length(ex.args) == 2 && ex.args[1] isa Symbol && ex.args[2] isa Symbol)
        throw(ArgumentError("@vectorspace: `$(ex)` must be of the form: `V, F` where `V` is a vector space over a field `F`."))
    end
    quote
        mutable struct $(esc(ex.args[1])) <: VectorSpace{$(esc(ex.args[2]))}
            label::String
            value::Union{Vector,Missing,Zero}
            decomposition::LinearDecomposition{$(esc(ex.args[1]))}
            constraints::Constraints
        end
    end
end

"Define a normed vector space over a field."
macro normedvectorspace(ex::Expr)
    if !(ex.head == :tuple && length(ex.args) == 2 && ex.args[1] isa Symbol && ex.args[2] isa Symbol)
        throw(ArgumentError("@normedvectorspace: `$(ex)` must be of the form: `V, F` where `V` is a normed vector space over a field `F`."))
    end
    quote
        mutable struct $(esc(ex.args[1])) <: NormedVectorSpace{$(esc(ex.args[2]))}
            label::String
            value::Union{Vector,Missing,Zero}
            decomposition::LinearDecomposition{$(esc(ex.args[1]))}
            constraints::Constraints
        end
    end
end

"Define an inner product space over a field."
macro innerproductspace(ex::Expr)
    if !(ex.head == :tuple && length(ex.args) == 2 && ex.args[1] isa Symbol && ex.args[2] isa Symbol)
        throw(ArgumentError("@innerproductspace: `$(ex)` must be of the form: `V, F` where `V` is an inner product space over a field `F`."))
    end
    quote
        mutable struct $(esc(ex.args[1])) <: InnerProductSpace{$(esc(ex.args[2]))}
            label::String
            value::Union{Vector,Missing,Zero}
            decomposition::LinearDecomposition{$(esc(ex.args[1]))}
            constraints::Constraints
            dual::LinearFunctional{$(esc(ex.args[1]))}

            function $(esc(ex.args[1]))(label::String, value::Union{Vector,Missing,Zero}, decomposition::LinearDecomposition{$(esc(ex.args[1]))}, constraints::Constraints)
                x = new(label, value, decomposition, constraints, LinearFunctional{$(esc(ex.args[1]))}())
                x.dual.dual = x
                x
            end
        end
    end
end


############################################################################################
# Methods

value(e::Expression) = e.value
decomposition(e::Expression) = e.decomposition
constraints(e::Expression) = e.constraints
variables(e::Expression) = variables(decomposition(e))
variables(m::Matrix{F}) where {F<:Field} = mapreduce(variables, ∪, m; init=Set{F}())

# decomposition that defaults to self => 1 if empty
selfdecomp(a::F) where {F<:Field} = isempty(decomposition(a)) ? AffineDecomposition{F}(Dict(a => 1)) : decomposition(a)
selfdecomp(v::V) where {V<:VectorSpace} = isempty(decomposition(v)) ? LinearDecomposition{V}(Dict(v => 1)) : decomposition(v)

# types of expressions
iszero(e::Expression) = hasvalue(e) && iszero(value(e))
hasvalue(e::Expression) = !ismissing(value(e))
isvariable(e::Expression) = !hasvalue(e) && isempty(decomposition(e))


############################################################################################
# Constructors

# variable
(::Type{F})(label::String = "Variable{$F}") where {F<:Field} = F(label, missing, AffineDecomposition{F}(), Constraints())
(::Type{V})(label::String = "Variable{$V}") where {V<:VectorSpace} = V(label, missing, LinearDecomposition{V}(), Constraints())

# constant
(::Type{F})(value::Number) where {F<:Field} = F("", value, AffineDecomposition{F}(), Constraints())
(::Type{V})(value::Union{Vector,Zero}) where {V<:VectorSpace} = V("", value, LinearDecomposition{V}(), Constraints())

# decomposition (if the decomposition is empty, set the value to zero)
(::Type{F})(decomposition::AffineDecomposition{<:F}) where {F<:Field} = isempty(decomposition) ? F(0) : F("", missing, decomposition, Constraints())
(::Type{V})(decomposition::LinearDecomposition{<:V}) where {V<:VectorSpace} = isempty(decomposition) ? V(Zero()) : V("", missing, decomposition, Constraints())

# value and decomposition (if the decomposition is empty, set the value to zero)
(::Type{F})(value::Union{Number,Missing}, decomposition::AffineDecomposition{<:F}) where {F<:Field} = isempty(decomposition) ? F(0) : F("", value, decomposition, Constraints())
(::Type{V})(value::Union{Vector,Missing,Zero}, decomposition::LinearDecomposition{<:V}) where {V<:VectorSpace} = isempty(decomposition) ? V(Zero()) : V("", value, decomposition, Constraints())


############################################################################################
# Algebra

# Expressions
+(e1::E, e2::E) where {E<:Expression} = E( value(e1) + value(e2), selfdecomp(e1) + selfdecomp(e2) )
+(e1::Expression, e2::Expression) = +(promote(e1,e2)...)
-(e1::Expression, e2::Expression) = e1 + (-e2)
-(e::Expression) = -1*e
*(a::Number, e::E) where {E<:Expression} = E( a*value(e), a*selfdecomp(e) )
*(e::Expression, a::Number) = a*e
/(e::Expression, a::Number) = (1/a)*e

# Scalars with numbers
+(a1::F, a2::Number) where {F<:Field} = F( value(a1) + a2, selfdecomp(a1) + a2 )
+(a1::Number, a2::Field) = +(promote(a1,a2)...)
-(a1::Field, a2::Number) = a1 + (-a2)
-(a1::Number, a2::Field) = a1 + (-a2)

# Convert and promote numbers to scalars
promote_rule(::Type{F}, ::Type{<:Number}) where {F<:Field} = F
convert(::Type{F}, a::Number) where {F<:Field} = F(a)

# Squared norm of a vector in a normed vector space
^(v::NormedVectorSpace, n::Int) = (n == 2 ? v'*v : error("Can only take inner product of points."))

"""
    ⊗(x,x)

Outer product (Gram matrix) of two vectors whose elements are themselves vectors in the same inner product space.

# Examples
```julia-repl
julia> x = [ Rⁿ(); Rⁿ(); Rⁿ() ]
julia> y = [ Rⁿ(); Rⁿ() ]
julia> G = x ⊗ y
```
"""
⊗(x1::Vector{V}, x2::Vector{V}) where {V<:InnerProductSpace} = GramMatrix{V}([ x'*y for x ∈ x1, y ∈ x2 ])

# \begin{bmatrix} x_1 \\ x_2 \\ x_3 \end{bmatrix} \otimes \begin{bmatrix} y_1 \\ y_2 \end{bmatrix} = \begin{bmatrix} \langle x_1,y_1\rangle & \langle x_1,y_2\rangle \\ \langle x_2,y_1\rangle & \langle x_2,y_2\rangle \\ \langle x_3,y_1\rangle & \langle x_3,y_2\rangle \end{bmatrix}


function +(G::GramMatrix{V}, a::Number) where {V<:InnerProductSpace}
    m = copy(decomposition(G))
    for i = 1:size(G,1)
        m[i,i] += a
    end
    GramMatrix{V}( label(G), value(G), m )
end
+(a::Number, G::GramMatrix) = G + a
-(G::GramMatrix, a::Number) = G + (-a)
-(a::Number, G::GramMatrix) = a + (-G)

function *(a::Number, G::GramMatrix{V}) where {V<:InnerProductSpace}
    m = copy(decomposition(G))
    for i = 1:size(G,1)
        for j = 1:size(G,2)
        m[i,j] *= a
        end
    end
    GramMatrix{V}( label(G), value(G), m )
end
*(G::GramMatrix, a::Number) = a*G

size(G::GramMatrix, n::Int) = size(decomposition(G), n)


############################################################################################
# Evaluate

function evaluate(e::Expression)
    if hasvalue(e)
        return iszero(e) ? 0 : value(e)
    end
    isvariable(e) ? missing : evaluate(decomposition(e))
end
evaluate(x::LinearDecomposition) = mapreduce( pair -> pair.second*evaluate(pair.first), +, weights(x); init=0 )
evaluate(x::AffineDecomposition) = evaluate(linear(x)) + constant(x)
evaluate(p::Tuple{X,X}) where {X<:InnerProductSpace} = evaluate(p[1])'*evaluate(p[2])

evaluate(t::Tuple{LinearDecomposition{F},AffineDecomposition{F}}) where {F<:Field} = evaluate(t[1]) + evaluate(t[2])


############################################################################################
# IsEqual

isequal(x1::Expression, x2::Expression) = false
isequal(x1::LinearDecomposition{T}, x2::LinearDecomposition{T}) where {T} = isequal(weights(x1), weights(x2))
isequal(x1::AffineDecomposition{T}, x2::AffineDecomposition{T}) where {T} = isequal(linear(x1), linear(x2)) && isequal(constant(x1), constant(x2))
isequal(x1::AbstractArray{<:Expression}, x2::Expression) = false
isequal(x1::Expression, x2::AbstractArray{<:Expression}) = false
isequal(a1::AbstractArray{E}, a2::AbstractArray{E}) where {E<:Expression} = size(a1) == size(a2) && all( isequal(a1[i],a2[i]) for i ∈ eachindex(a1) )

function isequal(x1::T, x2::T) where {T<:Expression}
    isvariable(x1) && isvariable(x2) && return isequal(objectid(x1), objectid(x2))
    !isvariable(x1) && !isvariable(x2) && return isequal(value(x1), value(x2)) && isequal(decomposition(x1), decomposition(x2))
    false
end
