"""
    label(x)

Get the label of an `Expression` or `Oracle`.
"""
function label end

"""
    label!(x, s::String)

Set the label of an `Expression` or `Oracle` (or its `Wrapper`).

When an oracle is sampled at a point using [`sample`](@ref), the labels of the oracle and the
point at which it is sampled is used to automatically create an intuitive label.

For oracles, this function recursively labels all suboracles.
- The main suboracle uses the same label.
- Other suboracles (accessed via the `adjoint`) are given intuitive labels. For example:
    - the adjoint of a linear map with label `A` is `A*`
    - the subdifferential of a functional with label `f` is `∂f`
    - the gradient of a functional with label `f` is `∇f`
    - the Hessian of a functional with label `f` is `∇²f`

See also: [`@autolabel`](@ref).

```julia-repl
julia> f = QuadraticFunctional{Rⁿ}()
julia> label!(f, "f")  # label the function
julia> label(f)        # "f"
julia> label(f')       # "∇f"
julia> label(f'')      # "∇²f"
julia> x = Rⁿ()        # construct a vector
julia> label!(x, "x")  # label the point
julia> y = f(x)        # sample the function at a point
julia> label(y)        # "f(x)"
```
"""
function label! end


label(x::Union{Expression,Oracle}) = x.label
label(w::Wrapper{<:Oracle}) = label(oracle(w))
label(w::Wrapper) = label(unwrap(w))

############################################################################################
# Expressions

label!(e::Expression, label::String) = (e.label=label; nothing)
# label!(x::InnerProductSpace, label::String) = (x.label=label; label!(x.dual,label*"*"); nothing)

function label!(x::InnerProductSpace, label::String)
    x.label = label
    label!(x.associations[Dual],label*"*")
    nothing
end

############################################################################################
# Oracles

label!(o::Oracle, label::String) = (o.label=label; map(p -> label!(last(p), defaultlabel(first(p), label)), collect(associations(o))); nothing)

defaultlabel(::Type{Transpose}, label::String) = label * "*"
defaultlabel(::Type{Subdifferential}, label::String) = "∂" * label
defaultlabel(::Type{Gradient}, label::String) = "∇" * label
defaultlabel(::Type{Hessian}, label::String) = "∇²" * label

defaultlabel(o::AbstractOperator, x) = "$(label(o))($(label(x)))"
defaultlabel(o::ConstantMap, ::Any) = label(o)

function defaultlabel(o::AbstractLinearFunctional{X}, x::X) where {X<:InnerProductSpace}
    "⟨"*label(x)*","*label(o)*"⟩"
end

function defaultlabel(w::Dual{X}, x::X) where {X}
    isequal(w', x) ? "|"*label(x)*"|²" : "⟨"*label(x)*","*label(w')*"⟩"
end

############################################################################################
# Algorithm macro

"""
    @algorithm

Automatic labeling of types `Expression` and `Oracle`.

This macro evaluates the right-hand side of the assignment, binds the expression to the
symbol on the left-hand side, and then calls `label!` to label the expression with the
symbol from the left-hand side.

The macro can be used on single assignment expressions or on a block of expressions.

Any non-assignment expressions are evaluated without labeling.

```julia-repl
julia> @algorithm a = R()  # define and label a scalar
julia> label(a)            # "a"
julia> @algorithm begin
julia>     x = Rⁿ()        # define and label a set of variables
julia>     y = Rᵐ()
julia> end
```
"""
macro algorithm(ex::Expr)
    if ex.head == :block
        Expr(:block, [ _algorithm(arg) for arg ∈ ex.args if !(arg isa LineNumberNode) ]...)
    else
        _algorithm(ex)
    end
end

function _algorithm(ex::Expr)
    
    # if the expression is a pair, then update the pair
    if ex.head == :call && ex.args[1] == :(=>)
        quote
            update!( $(esc(ex.args[2])) => $(esc(ex.args[3])) )
        end
        
    # else if the expression is not an assignment, then just evaluate it
    elseif ex.head ≠ :(=)
        :($(esc(ex)))
    
    # otherwise, the expression is an assignment, so evaluate it and label the new variable
    else
        if ex.args[1] isa Symbol
            quote
                local var = $(esc(ex.args[2]))
                label!(var, $(string(ex.args[1])))
                $(esc(ex.args[1])) = var
            end
        elseif ex.args[1] isa Expr && ex.args[1].head == :tuple
            quote
                local var = $(esc(ex.args[2]))
                label!.(var, $([string(x) for x ∈ ex.args[1].args]))
                $(esc(ex.args[1])) = var
            end
        else
            throw(ArgumentError("@autolabel: `$ex` does not have the correct left-hand side."))
        end
    end
end
