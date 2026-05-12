########################################################
# DEFAULT
########################################################

export default_setup, R, Prop

function default_setup()

    @globalset Prop, R
    @trait Prop, PropositionalLogic, Numeric(Bool)
    @trait R, Ring, Order(Prop), Numeric(Float64)

    @trait Prop, Evaluator
    @trait R × R → Prop, Evaluator
    @trait R × Prop → R, Evaluator
    @trait Prop × Prop → Prop, Evaluator

    evaluator!(get(R, Order).ordering, (x) -> with_optimizer() do
        JuMP.@constraint(model(), evaluate(x[1]) ≤ evaluate(x[2])); nothing
    end)

    evaluator!(get(Prop, PropositionalLogic).conjunction, (x) -> with_optimizer() do
        evaluate.(as_tuple(x)); nothing
    end)

    evaluator!(get(R, Order).max, (problem) -> with_optimizer() do
    
        objective, constraint = as_tuple(problem)

        !implementable(objective) && error("Objective $objective is not implementable.")
        !implementable(constraint) && error("Constraint $constraint is not implementable")

        vars = collect(filter(implementable, variables(objective)))
        evaluate(constraint)
        JuMP.@objective(model(), Max, evaluate(objective))
        JuMP.optimize!(model())
        return evaluate(objective)
    end)

    evaluator!(get(R, Order).min, (problem) -> with_optimizer() do
    
        objective, constraint = as_tuple(problem)

        !implementable(objective) && error("Objective $objective is not implementable.")
        !implementable(constraint) && error("Constraint $constraint is not implementable")

        vars = collect(filter(implementable, variables(objective)))
        evaluate(constraint)
        JuMP.@objective(model(), Min, evaluate(objective))
        JuMP.optimize!(model())
        return evaluate(objective)
    end)
end