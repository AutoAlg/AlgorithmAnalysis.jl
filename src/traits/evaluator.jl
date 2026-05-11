#########################################################
# EVALUATOR
#########################################################

export Evaluator, evaluator!, has_evaluation, evaluate

struct Evaluator <: Trait
    S::Space
    evaluator::Dict{Object, Dict{Tuple{Vararg{DataType}}, Function}}

    function Evaluator(S::Space)
        evaluator = Dict{Object, Dict{Tuple{Vararg{DataType}}, Function}}()
        register!(new(S, evaluator))
    end
end

show(io::IO, ::Evaluator) = print(io, "Evaluator()")

function evaluator!(x::Object, datatypes::Tuple{Vararg{DataType}}, evaluation::Function)
    t = get(x, Evaluator)
    if ismissing(t)
        error("Object $x has no Evaluator trait.")
    end
    get!(t.evaluator, x) do
        Dict{Tuple{Vararg{DataType}}, Function}()
    end
    get!(t.evaluator[x], datatypes) do
        evaluation
    end
    nothing
end

function has_evaluation(x::Object, datatypes::Tuple{Vararg{DataType}})
    t = get(x, Evaluator)
    
    !ismissing(t) && x ∈ keys(t.evaluator) && datatypes ∈ keys(t.evaluator[x])
end

function evaluate(x::Object, datatypes::Tuple{Vararg{DataType}})
    if !has_evaluation(x, datatypes)
        error("Object $x cannot be evaluated at datatypes $datatypes")
    end
    t.evaluator[x][datatypes]
end
