############################################################################################
# DEFAULT
############################################################################################

export default_setup, R, Prop

function default_setup()

    @globalset Prop, R
    @trait Prop, PropositionalLogic, Numeric(Bool)
    @trait R, Ring, Order(Prop), Numeric(Float64)

    @trait R × R → Prop, Evaluator
    @trait R × Prop → R, Evaluator
    @trait Prop × Prop → Prop, Evaluator

    evaluator!(get(R, Order).ordering, (x) -> with_jump() do
    x1, x2 = as_tuple(x)
    JuMP.@constraint(model(), evaluate(x1) ≤ evaluate(x2))
    nothing
    end)

    evaluator!(get(Prop, PropositionalLogic).conjunction, (x) -> with_jump() do
    evaluate.(as_tuple(x))
    nothing
    end)

    evaluator!(get(R, Order).max, (problem) -> with_jump() do
    
    objective, constraint = as_tuple(problem)

    if !implementable(objective)
        error("The objective $objective is not implementable.")
    end
    if !implementable(constraint)
        error("The constraint $constraint is not implementable")
    end

    @info "Maximizing $objective subject to $constraint"

    vars = collect(filter(implementable, variables(objective)))

    evaluate(constraint)
    
    JuMP.@objective(model(), Max, evaluate(objective))

    JuMP.optimize!(model())

    # @info "Termination status: $(JuMP.termination_status(model()))"
    # @info "Objective value: $(evaluate(objective, sol))"
    # @info "Use `evaluate(expr, sol)` to obtain the value of any expression."

    return evaluate(objective)
    end)

end