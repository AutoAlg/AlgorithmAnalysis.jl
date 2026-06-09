# ------------------------------------------------------
# NUMERIC
# ------------------------------------------------------

export with_numerics, evaluate, model

import JuMP, Hypatia


const JUMP_MODEL = Base.ScopedValues.ScopedValue{JuMP.GenericModel}()

active_model() = isassigned(JUMP_MODEL)

function default_model()
    model = JuMP.Model(Hypatia.Optimizer)
    JuMP.set_silent(model)
    return model
end

function with_numerics(code::Function, model_constructor::Function = () -> default_model())
    if active_model()
        code()
    else
        verbose() && @info "Initializing JuMP model..."
        val = Base.ScopedValues.with(code, JUMP_MODEL => model_constructor())
        verbose() && @info "JuMP model complete!"
        return val
    end
end

function model()
    if active_model()
        JUMP_MODEL[]
    else
        error("No JuMP model instantiated. Use with_numerics() to run code inside of an optimizer.")
    end
end

# function evaluate(x::Object, dict::Dict = Dict())
#     if x ∈ keys(dict)
#         verbose() && @info "Object $x exists in the dictionary $dict"
#         return dict[x]
#     end
#     if active_model() && label(x) ∈ keys(JuMP.object_dictionary(model()))
#         verbose() && @info "Object $x exists in the JuMP model"
#         val = model()[label(x)]
#         if JuMP.has_values(model())
#             return JuMP.value(val)
#         else
#             return val
#         end
#     end
#     if hasvalue(x)
#         val = value(x)
#         if val isa Evaluation
#             verbose() && @info "Object $x is an Evaluation, so evaluating its value"
#             return evaluate(val, dict)
#         else
#             verbose() && @info "Returning the value of object $x"
#             return val
#         end
#     end
#     if has_evaluation(x)
#         verbose() && @info "Object $x has an Evaluator"
#         return get(x, Evaluator).evaluator[x]()
#     end
#     if hastrait(x, Product)
#         verbose() && @info "Object $x is a product, so evaluating each component"
#         return evaluate.(as_tuple(x), Ref(dict))
#     end
#     if hastrait(x, Symmetric)
#         verbose() && @info "Object $x is a matrix, so evaluating each component"
#         return evaluate.(as_array(x), Ref(dict))
#     end
#     if active_model() && hastrait(x, Numeric)
#         t = get(x, Numeric)

#         if datatype(t) == Float64
#             sym = label(x)
#             model()[sym] = JuMP.@variable(model(), base_name = string(sym))
#             verbose() && @info "Object $x is numeric with datatype Float64, so initializing in the JuMP model as $(model()[sym])"
#             return model()[sym]

#         elseif datatype(t) == Matrix{Float64}
#             sym = label(x)
#             n = dim(get(x, Symmetric))
#             model()[sym] = JuMP.@variable(model(), [1:n,1:n], Symmetric, base_name = string(sym))
#             verbose() && @info "Object $x is numeric with datatype Matrix{Float64}, so initializing in the JuMP model as $(model()[sym])"
#             return model()[sym]
            
#         end
#     end
#     error("Cannot evaluate object $x in space $(space(x)).")
# end

function feasible(constraint::BasicSymbolic{<:Constraint})
    with_numerics() do
        if !implementable(constraint)
            error("Constraint $constraint is not implementable")
        end
        evaluate(constraint)
        JuMP.optimize!(model())
        return JuMP.is_solved_and_feasible(model())
    end
end