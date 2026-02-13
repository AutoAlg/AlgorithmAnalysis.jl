export gradient_descent, fast_gradient, triple_momentum, heavy_ball


############################################################################################
# Algorithms

function gradient_descent(m, L;
        n = 1,
        α = 2/(L+m),
        ρ = missing,
        measure::PerformanceMeasure = DistanceToOptimality,
        verbose = false,
        solver = SCS.Optimizer
    )

    @algorithm begin
        f = DifferentiableFunctional{Rⁿ}()
        xs = first_order_stationary_point(f)
        f' ∈ SectorBounded(m, L, xs, f'(xs))
        
        x = Vector{Rⁿ}(undef, n+1)
        x[1] = Rⁿ()
        for k = 1:n
            x[k+1] = x[k] - α * f'(x[k])
            x[k] => x[k+1]
        end

        performance = evaluate(measure, f, x[1], xs)
    end

    if ismissing(ρ)
        rate(performance, verbose=verbose, solver=solver)
    else
        certify(performance, ρ, verbose=verbose, solver=solver)
    end
end

"""
    fast_gradient(m, L)


"""
function fast_gradient(m, L;
        n = 1,
        ρ = missing,
        measure::PerformanceMeasure = DistanceToOptimality,
        verbose=false,
    )
    κ = L/m
    α = 4/(3L+m)
    β = (√(3κ+1)-2)/(√(3κ+1)+2)
    # if ismissing(ρ)
    #     ρ = 1 - 2/√(3κ+1)
    # end

    @algorithm begin
        f = DifferentiableFunctional{Rⁿ}()
        xs = first_order_stationary_point(f)
        f ∈ SmoothStronglyConvex(m, L)

        x = Vector{Rⁿ}(undef, n+2)
        y = Vector{Rⁿ}(undef, n+1)
        x[1] = Rⁿ()
        x[2] = Rⁿ()
        for k = 2:n+1
            y[k] = x[k] + β * (x[k] - x[k-1])
            x[k+1] = y[k] - α * f'(y[k])
        end
        for k = 1:n+1
            x[k] => x[k+1]
        end

        performance = evaluate(measure, f, x[1], xs)
    end
    if ismissing(ρ)
        rate(performance, verbose=verbose)
    else
        certify(performance, ρ, verbose=verbose)
    end
end

"""
    triple_momentum(m, L)


"""
function triple_momentum(;
        m = 1,
        L = 10,
        n = 2,
        measure::PerformanceMeasure = DistanceToOptimality,
        verbose=false
    )
    κ = L/m
    ρ = 1 - 1/√κ
    α = (1 + ρ)/L
    β = ρ^2/(2-ρ)
    γ = ρ^2/((1+ρ)*(2-ρ))
    δ = ρ^2/(1-ρ^2)

    @algorithm begin
        f = DifferentiableFunctional{Rⁿ}()
        xs = first_order_stationary_point(f)
        f ∈ SmoothStronglyConvex(m, L)

        x = Vector{Rⁿ}(undef, n+2)
        y = Vector{Rⁿ}(undef, n+1)
        z = Vector{Rⁿ}(undef, n+1)
        x[1] = Rⁿ()
        x[2] = Rⁿ()
        for k = 2:n+1
            y[k] = x[k] + γ * (x[k] - x[k-1])
            z[k] = x[k] + δ * (x[k] - x[k-1])
            x[k+1] = x[k] + β * (x[k] - x[k-1]) - α * f'(y[k])
        end
        for k = 1:n+1
            x[k] => x[k+1]
        end

        performance = evaluate(measure, f, x[2], xs)
    end
    certify(performance, ρ, verbose=verbose)
end

"""
    heavy_ball(m, L, ρmin=0)


"""
function heavy_ball(m, L, ρmin=0)
    κ = L/m
    α = 4/((√L + √m)^2)
    β = ((sqrt(L/m)-1)/(sqrt(L/m)+1))^2
    @algorithm begin
        f = DifferentiableFunctional{Rⁿ}()
        xs = first_order_stationary_point(f)
        f ∈ SmoothStronglyConvex(m, L)
        x0 = Rⁿ()
        x1 = Rⁿ()
        x2 = x1 - α*f'(x1) + β*(x1-x0)
        x3 = x2 - α*f'(x2) + β*(x2-x1)
        x4 = x3 - α*f'(x3) + β*(x3-x2)
        x0 => x1
        x1 => x2
        x2 => x3
        x3 => x4
        performance = (x1-xs)^2
    end
    rate(performance, ρmin)
end
