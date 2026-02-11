export gradient_descent, fast_gradient

############################################################################################
# Algorithms

function gradient_descent(m, L;
        n = 1,
        α = 2/(L+m),
        ρ = missing,
        measure::PerformanceMeasure = DistanceToOptimality,
        verbose=false
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
        rate(performance, verbose=verbose)
    else
        certify(performance, ρ, verbose=verbose)
    end
end

function fast_gradient(m, L;
        n = 1,
        ρ = missing,
        measure::PerformanceMeasure = DistanceToOptimality,
        verbose=false
    )
    α = 4/(3L+m)
    β = (√(3L+1)-2)/(√(3L+1)+2)

    @algorithm begin
        f = DifferentiableFunctional{Rⁿ}()
        xs = first_order_stationary_point(f)
        f ∈ SmoothStronglyConvex(m, L)

        x = Vector{Rⁿ}(undef, n+1)
        y = Vector{Rⁿ}(undef, n+1)
        x[1] = Rⁿ()
        x[2] = Rⁿ()
        for k = 1:n
            x[k+1] = x[k] - α * f'(x[k])
            x[k] => x[k+1]
        end

        x0 = Rⁿ()
        x1 = Rⁿ()
        y1 = x1 + β*(x1 - x0)
        x2 = y1 - α*f'(y1)
        x0 => x1
        x1 => x2

        performance = evaluate(measure, f, x[1], xs)
    end
    if ismissing(ρ)
        rate(performance, verbose=verbose)
    else
        certify(performance, ρ, verbose=verbose)
    end
end
