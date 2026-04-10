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

See also: [`@algorithm`](@ref).

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


############################################################################################
# Expressions

label!(::Any, ::String) = nothing

label!(e::Expression, label::String) = (e.label=label; nothing)

function label!(x::InnerProductSpace, label::String)
    x.label = label
    haskey(x.associations, Dual) && label!(x.associations[Dual],label*"'")
    nothing
end

############################################################################################
# Oracles

function label!(o::Oracle, label::String)
    o.label = label
    for a ∈ associations(o)
        if hasmethod(defaultlabel, (Type{first(a)}, String))
            label!(last(a), defaultlabel(first(a), label))
        end
    end
    nothing
end

"""
    defaultlabel(T, label)

Create a label for an expression depending on its type `T`` and its label `label`
- **Transpose**:  
  For a transpose expression of an expression labeled `e`, return label string `e*`

- **Subdifferential**:  
  For the subdifferential of a functional labeled `f`, return label string `∂f`

- **Gradient**:  
    For the Gradient of a functional labeled `f`, return label string `∇f`
    
- **Hessian**:  
    For the Hessian of a functional labeled `f`, return label string `∇²f`

- **AbstractOperator**:
    For an abstract operator labeled `f` applied on an expression labeled `e`, return label string `f(e)`

- **ConstantMap**:
    For an ConstantMap label `Σ`, return its label string `Σ`

- **InnerProduct**:
    For an inner product between expressions labeled `e1` and `e2` , return label string `<e1, e2>`

- **Norm**:
    For an inner product between an expression labeled `e1` and its transpose labeled `e1*`, return label string `|e1|²`

```julia-repl
julia> f = QuadraticFunctional{Rⁿ}()
julia> defaultlabel(Type{f'}, label(f))
```
"""
defaultlabel(::Type{Transpose}, label::String) = label * "*"
defaultlabel(::Type{Subdifferential}, label::String) = "∂" * label
defaultlabel(::Type{Gradient}, label::String) = "∇" * label
defaultlabel(::Type{Hessian}, label::String) = "∇²" * label
defaultlabel(o::AbstractOperator, x) = "$(label(o))($(label(x)))"
defaultlabel(o::ConstantMap, ::Any) = label(o)

function defaultlabel(o::AbstractLinearFunctional{X}, x::X) where {X<:InnerProductSpace}
    if haskey(associations(o), DualOf)
        y = o.associations[DualOf]
        isequal(y, x) ? "|"*label(x)*"|²" : "⟨"*label(y)*","*label(x)*"⟩"
    else
        "⟨"*label(x)*","*label(o)*"⟩"
    end
end

############################################################################################
# @ALGORITHM
############################################################################################

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
        
        # else if the expression is declaring a variable (e.g., x ∈ R), then eval and label
        elseif ex.head == :call && ex.args[1] == :(∈)
            eval_and_label(ex)

        elseif ex.head == :tuple && ex.args[end].args[1] == :(∈)
            eval_and_label(ex)

        # else if the expression is of the form f : X → Y, then eval and label
        # see Meta.@dump(f : X → Y)
        elseif ex.head == :call && length(ex.args) == 3 && ex.args[1] == :(→) && length(ex.args[2].args) == 3 && ex.args[2].args[1] == :(:)
            f = esc(ex.args[2].args[2])
            X = esc(ex.args[2].args[3])
            Y = esc(ex.args[3])
            str = string(ex.args[2].args[2])
            quote
                $f = Map{$X, $Y}()
                label!($f, $str)
            end

        # else if the expression is of the form f : X → Y, then eval and label
        elseif ex.head == :call && length(ex.args) == 3 && ex.args[1] == :(⇒) && length(ex.args[2].args) == 3 && ex.args[2].args[1] == :(:)
            f = esc(ex.args[2].args[2])
            X = esc(ex.args[2].args[3])
            Y = esc(ex.args[3])
            str = string(ex.args[2].args[2])
            quote
                $f = Operator{$X, $Y}()
                label!($f, $str)
            end

        # else if the expression is an assignment, evaluate and label it
        elseif ex.head == :(=)
            eval_and_label(ex)

        # otherwise the expression is not an assignment, so just evaluate it
        else
            :($(esc(ex)))
        end
    end
end

eval_and_label(x::Expression) = :($(esc(x)))

function eval_and_label(ex::Expr)
    
    # if the expression is an equality
    if ex.head == :(=)

        lhs = esc(ex.args[1])
        rhs = esc(ex.args[2])
        str = string(ex.args[1])

        quote
            $lhs = $rhs
            label!($lhs, $str)
        end

    # else if the expression is an inclusion (e.g., x ∈ R)
    # elseif ex.head == :call && (ex.args[1] == :(∈) || ex.args[1] == :in)

    #     lhs = esc(ex.args[2])
    #     rhs = esc(ex.args[3])
    #     str = string(ex.args[2])

    #     quote
    #         if $rhs isa $DataType && $rhs <: Expression
    #             $lhs = $rhs()
    #             label!($lhs, $str)
    #         else
    #             $(esc(ex))
    #         end
    #     end

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

    # x,y ∈ R
    elseif ex.head == :tuple && ex.args[end].args[1] == :(∈)

        expr = ex
        vars = Any[]
        rhs = nothing

        if expr isa Expr
            if expr.head == :tuple
                parts = expr.args
                last = parts[end]
                if last isa Expr && last.head == :call && (last.args[1] == :in || last.args[1] == :∈)
                    rhs = last.args[3]
                    append!(vars, parts[1:end-1])
                    push!(vars, last.args[2])
                else
                    error("@algorithm: expected syntax like `x, y, z in R`")
                end
            elseif expr.head == :call && (expr.args[1] == :in || expr.args[1] == :∈)
                rhs = expr.args[3]
                lhs = expr.args[2]
                if lhs isa Expr && lhs.head == :tuple
                    append!(vars, lhs.args...)
                else
                    push!(vars, lhs)
                end
            else
                error("@algorithm: expected syntax like `x, y, z in R`")
            end
        else
            error("@algorithm: expected an expression")
        end

        # Build assignment + labeling statements
        stmts = Any[]
        for v in vars
            push!(stmts, :( $v = $rhs() ))
            push!(stmts, :( label!($v, $(string(v))) ))
        end

        esc(Expr(:block, stmts...))

    # otherwise just evaluate the expression
    else
        :($(esc(ex)))
    end
end
