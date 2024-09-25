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
label(w::Wrapper) = label(unwrap(w))

description(e::Expression) = (isempty(label(e)) ? description(decomposition(e)) : label(e))

function description(d::LinearDecomposition)
    isempty(d) && return "(empty)"
    str = ""
    first = true
    for (key, value) ∈ weights(d)
        if first
            first = false
            if value == 1
                str *= string(key)
            elseif value == -1
                str *= "-" * string(key)
            else
                str *= string(value) * " " * string(key)
            end
        else
            if value == 1
                str *= " + " * string(key)
            elseif value == -1
                str *= " - " * string(key)
            elseif value ≥ 0
                str *= " + " * string(value) * " " * string(key)
            else
                str *= " - " * string(-value) * " " * string(key)
            end
        end
    end
    str
end

############################################################################################
# Expressions

label!(::Any, ::String) = nothing

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
    _algorithm(ex)
end

_algorithm(x::LineNumberNode) = x
_algorithm(x::Symbol) = x

function _algorithm(ex::Expr)

    # if the expression is a block, call the macro on each argument in the block
    if ex.head == :block
        Expr(:block, [ _algorithm(arg) for arg ∈ ex.args ]...)

    # else if the expression is a for loop, evalaute the macro on each line of the loop
    elseif ex.head == :for
        val = esc(ex.args[1].args[1])
        vals = esc(ex.args[1].args[2])
        expr = ex.args[2]

        quote
            for $val in $vals
                $(_algorithm(expr))
            end
        end
    else
    
        # if the expression is a pair, then update the pair
        if ex.head == :call && ex.args[1] == :(=>)
            lhs = esc(ex.args[2])
            rhs = esc(ex.args[3])
            quote
                update!( $lhs => $rhs )
            end
            
        # else if the expression is not an assignment, then just evaluate it
        elseif ex.head ≠ :(=)
            :($(esc(ex)))
        
        # otherwise the expression is an assignment, so evaluate and label it
        else
            eval_and_label(ex)
        end
    end
end

eval_and_label(x::Expression) = :($(esc(x)))

function eval_and_label(ex::Expr)
    
    # if the lhs is a symbol
    if ex.args[1] isa Symbol

        lhs = esc(ex.args[1])
        rhs = esc(ex.args[2])
        str = string(ex.args[1])

        quote
            $lhs = $rhs
            label!($lhs, $str)
        end

    # else if the lhs is an element of an array (evalutes the index)
    elseif ex.args[1] isa Expr && ex.args[1].head == :ref

        lhs = esc(ex.args[1])
        rhs = esc(ex.args[2])
        sym = string(ex.args[1].args[1])
        ind = esc(ex.args[1].args[2])
        
        quote
            $lhs = $rhs
            label!($lhs, $sym * "[" * string($ind) * "]")
        end

    # else if the lhs is a tuple, then label each element in the tuple
    elseif ex.args[1] isa Expr && ex.args[1].head == :tuple

        lhs = esc(ex.args[1])
        rhs = esc(ex.args[2])

        quote
            $lhs = $rhs
            label!.($lhs, $([string(x) for x ∈ ex.args[1].args]))
        end

    else
        throw(ArgumentError("@algorithm: `$ex` does not have the correct left-hand side."))
    end
end