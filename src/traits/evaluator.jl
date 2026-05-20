########################################################
# EVALUATOR
########################################################

export Evaluator, evaluator!, has_evaluation, evaluate
export model, with_optimizer, feasible

import JuMP, Clarabel


mutable struct Evaluator <: Trait
    S::Space
    evaluator::Dict{Object, Function}
    func::Union{Function, Missing}

    function Evaluator(S::Space)
        register!(new(S, Dict{Object, Function}(), missing))
    end
end

show(io::IO, ::Evaluator) = print(io, "Evaluator()")

function evaluator!(x::Object, evaluation::Function)
    t = get(x, Evaluator, err_msg = "Object $x has no Evaluator trait")
    t.evaluator[x] = evaluation
    nothing
end

function evaluator!(S::Space, evaluation::Function)
    t = get(S, Evaluator, err_msg = "Space $S has no Evaluator trait")
    t.func = evaluation
    nothing
end

has_evaluation(x::Object) = hastrait(x, Evaluator) && x ∈ keys(get(x, Evaluator).evaluator)

const JUMP_MODEL = ScopedValue{JuMP.GenericModel}()

function default_model()
    model = JuMP.Model(Clarabel.Optimizer)
    JuMP.set_silent(model)
    return model
end

active_optimizer() = isassigned(JUMP_MODEL)

function with_optimizer(code::Function, model_constructor::Function = () -> default_model())
    if active_optimizer()
        code()
    else
        verbose() && @info "Initializing JuMP model..."
        # @info "Cannot evaluate in closed form. Using the numerical optimizer."
        val = with(code, JUMP_MODEL => model_constructor())
        verbose() && @info "JuMP model complete!"
        return val
    end
end

function model()
    if active_optimizer()
        JUMP_MODEL[]
    else
        error("No JuMP model instantiated. Use with_optimizer() to run code inside of an optimizer.")
    end
end

function evaluate(x::Object, dict::Dict = Dict())
    if x ∈ keys(dict)
        verbose() && @info "Object $x exists in the dictionary $dict"
        return dict[x]
    end
    if active_optimizer() && label(x) ∈ keys(JuMP.object_dictionary(model()))
        verbose() && @info "Object $x exists in the JuMP model"
        val = model()[label(x)]
        if JuMP.has_values(model())
            return JuMP.value(val)
        else
            return val
        end
    end
    if hasvalue(x)
        val = value(x)
        if val isa Evaluation
            verbose() && @info "Object $x is an Evaluation, so evaluating its value"
            return evaluate(val, dict)
        else
            verbose() && @info "Returning the value of object $x"
            return val
        end
    end
    if has_evaluation(x)
        verbose() && @info "Object $x has an Evaluator"
        return get(x, Evaluator).evaluator[x]()
    end
    if hastrait(x, Product)
        verbose() && @info "Object $x is a product, so evaluating each component"
        return evaluate.(as_tuple(x), Ref(dict))
    end
    if hastrait(x, Symmetric)
        verbose() && @info "Object $x is a matrix, so evaluating each component"
        return evaluate.(as_array(x), Ref(dict))
    end
    if active_optimizer() && hastrait(x, Numeric)
        t = get(x, Numeric)

        if datatype(t) == Float64
            sym = label(x)
            model()[sym] = JuMP.@variable(model(), base_name = string(sym))
            verbose() && @info "Object $x is numeric with datatype Float64, so initializing in the JuMP model as $(model()[sym])"
            return model()[sym]

        elseif datatype(t) == Matrix{Float64}
            sym = label(x)
            n = dim(get(x, Symmetric))
            model()[sym] = JuMP.@variable(model(), [1:n,1:n], Symmetric, base_name = string(sym))
            verbose() && @info "Object $x is numeric with datatype Matrix{Float64}, so initializing in the JuMP model as $(model()[sym])"
            return model()[sym]
            
        end
    end
    error("Cannot evaluate object $x.")
end

function evaluate(val::Evaluation, dict::Dict)
    f, x = val.f, val.x

    if has_evaluation(f)
        verbose() && @info "Evaluation $val has an evaluator"
        return get(f, Evaluator).evaluator[f](x)
    end

    # for S ∈ numeric()
    #     if f ∈ trait_objects(S)
    #         verbose() && @info "Object $f is in a numeric space, so falling back to its global implementation"
    #         return eval(label(f))( evaluate(x, dict)... )
    #     end
    # end

    return evaluate(f, dict)( evaluate(x, dict)... )
end

function feasible(constraint::Object)
    with_optimizer() do
        if !implementable(constraint)
            error("Constraint $constraint is not implementable")
        end
        evaluate(constraint)
        JuMP.optimize!(model())
        return JuMP.is_solved_and_feasible(model())
    end
end
