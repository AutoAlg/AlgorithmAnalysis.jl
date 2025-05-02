############################################################################################
# Evaluate

"""
    expr(x)

Evaluate an expression at a point in its domain.

If the relation is single-valued and it has already been sampled at `x`, then the
corresponding point in the codomain is returned. Otherwise, a new point is sampled using
`Y()`, and a default label is used for the sample. A label may be specified for the sampled 
point, or it defaults to an intuitive label.

**Important:** Do not call `sample` directly. Instead, use `o(x)` to sample an oracle at a
point. For linear maps, `o*x` may also be used to denote sampling.

# Examples
```julia-repl
julia> A = LinearFunctional{Rⁿ}()
julia> x = Rⁿ()
julia> isequal(A(x), A*x)  # true
```
"""
function evaluate end

# evaluate a generic element
function (f::Object)(x::Object)
    T1 = space(f)
    T2 = space(x)
    if !canevaluate(T1, T2)
        error("Objects in $T1 cannot be evaluated at objects in $T2")
    end
    sample(relation(f), x, defaultlabel(f,x))
    # sample(instance(space(f)).relation(f), x, f.labeler(x))
end

function (f::Object)(x::Vararg{Object})
    if isfunction(f)
        f(convert(domain(f), x))
    else
        error("Cannot evaluate object of type $(typeof(f))")
    end
end
