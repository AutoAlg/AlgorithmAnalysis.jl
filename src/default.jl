########################################################
# DEFAULT
########################################################

export default_setup, R, Rⁿ, F, Prop, Sym, ⪯

function default_setup()

    register!(:⪯)

    global Prop = Space(:Prop, callback = Prop -> begin
        @trait Prop, PropositionalLogic, Numeric(Bool), Evaluator
        @trait Prop → Prop, Evaluator
        @trait Prop × Prop → Prop, Evaluator
        evaluator!(get(Prop, PropositionalLogic).conjunction, x -> evaluate.(as_tuple(x)))
    end)

    global R = Space(:R, callback = R -> begin

        @trait R, Ring, Order(Prop), Numeric(Float64), Equality(Prop)
        @trait R, Evaluator
        @trait R → R, Evaluator
        @trait R × R → R, Evaluator
        @trait R × R → Prop, Evaluator
        @trait R × Prop → R, Evaluator

        evaluator!(get(R, Ring).additive_group.id, () -> 0.0)
        evaluator!(get(R, Ring).additive_group.op, x -> evaluate(x[1]) + evaluate(x[2]))
        evaluator!(get(R, Ring).additive_group.inv, x -> -evaluate(x))
        evaluator!(get(R, Ring).additive_group.invop, x -> evaluate(x[1]) - evaluate(x[2]))
        evaluator!(get(R, Ring).multiplicative_group.id, () -> 1.0)
        evaluator!(get(R, Ring).multiplicative_group.op, x -> evaluate(x[1]) * evaluate(x[2]))
        evaluator!(get(R, Ring).multiplicative_group.inv, x -> one(R) / evaluate(x))
        evaluator!(get(R, Ring).multiplicative_group.invop, x -> evaluate(x[1]) / evaluate(x[2]))

        evaluator!(get(R, Equality).equality, x -> with_optimizer() do
            JuMP.@constraint(model(), evaluate(x[1]) == evaluate(x[2])); nothing
        end)

        evaluator!(get(R, Order).ordering, x -> with_optimizer() do
            JuMP.@constraint(model(), evaluate(x[1]) ≤ evaluate(x[2])); nothing
        end)

        evaluator!(get(R, Order).max, problem -> with_optimizer() do
        
            objective, constraint = as_tuple(problem)

            !implementable(objective) && error("Objective $objective is not implementable.")
            !implementable(constraint) && error("Constraint $constraint is not implementable")

            try
                evaluate(constraint)
                JuMP.@objective(model(), Max, evaluate(objective))
                JuMP.optimize!(model())
                return evaluate(objective)
            catch
                @info "Failed to solve optimization problem. Searching for a convexifying transformation…"
            end
        end)

        evaluator!(get(R, Order).min, problem -> with_optimizer() do
        
            objective, constraint = as_tuple(problem)

            !implementable(objective) && error("Objective $objective is not implementable.")
            !implementable(constraint) && error("Constraint $constraint is not implementable")

            evaluate(constraint)
            JuMP.@objective(model(), Min, evaluate(objective))
            JuMP.optimize!(model())
            return evaluate(objective)
        end)
    end)

    global Rⁿ = Space(:Rⁿ, callback = Rⁿ -> begin

        @trait Rⁿ, Equality(Prop), InnerProductSpace(R)
        @trait Rⁿ, Evaluator
        @trait Rⁿ → Rⁿ, Evaluator
        @trait Rⁿ × Rⁿ → Rⁿ, Evaluator
        @trait R × Rⁿ → Rⁿ, Evaluator
        @trait Rⁿ → (Rⁿ → R), Evaluator

        evaluator!(get(Rⁿ, InnerProductSpace).scale, x -> evaluate(x[1]) * evaluate(x[2]))
        evaluator!(get(Rⁿ, InnerProductSpace).adjoint, x -> evaluate(x)')
        # evaluator!(get(Rⁿ, InnerProductSpace).group.id, () -> 0)
        evaluator!(get(Rⁿ, InnerProductSpace).group.inv, x -> -evaluate(x))
        evaluator!(get(Rⁿ, InnerProductSpace).group.invop, x -> evaluate(x[1]) - evaluate(x[2]))
    end)

    global F = Space(:F, callback = F -> begin
        @trait F, Subdifferential(Rⁿ → R)
    end)

    @eval function Sym(F::Space, dim::Int)
        Space(Symbol("Sym(", label(F), ", ", dim, ")"), callback = S -> begin
            @trait S, Symmetric(F, dim), Group(:id, :*, :inv), Order(Prop, :⪯)
            @trait S, InnerProductSpace(R, :zero, :+, :-, :⋅, :adjoint)
            if !isnothing(get(F, Numeric))
                @trait S, Numeric(Matrix{datatype(get(F, Numeric))})
            end
            @trait S, Evaluator
            @trait S → F, Evaluator
            @trait S → S, Evaluator
            @trait S × S → S, Evaluator
            @trait F × S → S, Evaluator
            @trait S → (S → F), Evaluator
            @trait S × S → Prop, Evaluator
            evaluator!(get(S, Symmetric).tr, x -> la.tr(evaluate(x)))
            evaluator!(get(S, Group).id, () -> evaluate.([ i==j ? one(F) : zero(F) for i = 1:dim, j = 1:dim ]))
            evaluator!(get(S, Group).op, x -> evaluate(x[1]) * evaluate(x[2]))
            evaluator!(get(S, Group).inv, x -> inv(evaluate(x[2])))
            evaluator!(get(S, Group).invop, x -> evaluate(x[1]) / evaluate(x[2]))
            evaluator!(get(S, InnerProductSpace).group.id, () -> evaluate.([ zero(F) for i = 1:dim, j = 1:dim ]))
            evaluator!(get(S, InnerProductSpace).group.op, x -> evaluate(x[1]) + evaluate(x[2]))
            evaluator!(get(S, InnerProductSpace).group.inv, x -> -evaluate(x))
            evaluator!(get(S, InnerProductSpace).group.invop, x -> evaluate(x[1]) - evaluate(x[2]))
            evaluator!(get(S, InnerProductSpace).scale, x -> evaluate(x[1]) * evaluate(x[2]))
            evaluator!(get(S, InnerProductSpace).adjoint, x -> evaluate(x)')
            evaluator!(get(S, Order).ordering, x -> with_optimizer() do
                JuMP.@constraint(model(), la.Symmetric(convert(Matrix{JuMP.AffExpr}, evaluate(x[2]) - evaluate(x[1]))) in JuMP.PSDCone()); nothing
            end)
        end)
    end
end