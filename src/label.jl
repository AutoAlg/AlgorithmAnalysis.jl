"""
    label(x)

Get the label of an `Object`.
"""
function label end

"""
    label!(x, s::String)

Set the label of an `Object`.

When an operator is sampled at a point using [`sample`](@ref), the labels of the operator and the point at which it is sampled is used to automatically create an intuitive label.

For operators, this function recursively labels all suboperators.
- The main suboperator uses the same label.
- Other suboperators (accessed via the `adjoint`) are given intuitive labels. For example:
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

"""
    haslabel(x)

Check if an `Object` has a label.
"""
function haslabel end


label(obj::Object) = hasfield(typeof(obj), :label) ? obj.label : ""
label(w::Wrapper) = label(unwrap(w))

haslabel(obj::Object) = !isempty(label(obj))

label!(obj::Object, label::String) = (label!(obj, label, Objects());  nothing)
label!(::AbstractArray{<:Expression}, ::String) = nothing

# Label the object x and all of its associations except for those associated with the set of objects objs (as these have already been labeled).
function label!(obj::Object, label::String, objs::Objects)
    if hasfield(typeof(obj), :label)
        obj.label = label
    end
    push!(objs, obj)
    # for a ∈ associations(obj)
    #     if last(a) ∉ objs
    #         label!(last(a), defaultlabel(first(a), label), objs)
    #     end
    # end
end


############################################################################################
# Default labels

defaultlabel(::Any, ::Any) = ""

# defaultlabel(::Type{Transpose}, label::String) = label * "ᵀ"
# defaultlabel(::Type{Subdifferential}, label::String) = "∂" * label
# defaultlabel(::Type{Gradient}, label::String) = "∇" * label
# defaultlabel(::Type{Jacobian}, label::String) = "J" * label
# defaultlabel(::Type{Dual}, label::String) = label * "*"

function defaultlabel(o::Expression{<:Operator}, x)
    haslabel(o) && haslabel(x) ? "$(label(o))($(label(x)))" : ""
end

# defaultlabel(o::ConstantMap, ::Any) = label(o)

function defaultlabel(o::Expression{<:LinearFunctional{T}}, x::Expression{T}) where T
    if haslabel(x) && haslabel(o)
        isequal(o', x) ? "|"*label(x)*"|²" : "⟨"*label(x)*","*label(o')*"⟩"
    else
        ""
    end
end


############################################################################################
# Algorithm macro

"""
    @algorithm

Automatic labeling of types `Object`.

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

    # else if the expression is a for loop, evaluate the macro on each line of the loop
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
            
        # else if the expression is declaring a variable (e.g., x ∈ R), then 
        elseif ex.head == :call && ex.args[1] == :(∈)
            eval_and_label(ex)

        elseif ex.head == :tuple && ex.args[end].args[1] == :(∈)
            eval_and_label(ex)

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
    elseif ex.args[1] == :(∈)

        lhs = esc(ex.args[2])
        rhs = esc(ex.args[3])
        str = string(ex.args[2])

        quote
            $lhs = ($rhs)()
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

    # x,y ∈ R
    # elseif ex.head == :tuple && ex.args[end].args[1] == :(∈)

    #     lhs1 = esc(ex.args[1:end-1])
    #     lhs2 = esc(ex.args[end].args[2])
    #     rhs  = esc(ex.args[end].args[3])
    #     str1 = string(ex.args[1:end-1])
    #     str2 = string(ex.args[end].args[2])

    #     quote
    #         for x in ex.args[1:end-1]
    #             x = ($rhs)()
    #             label!(l, $(string(x)))
    #         end
    #         $lhs2 = ($rhs)()
    #         label!($lhs2, $str2)
    #     end

    else
        throw(ArgumentError("@algorithm: `$ex` does not have the correct left-hand side."))
    end
end