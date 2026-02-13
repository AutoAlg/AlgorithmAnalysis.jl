export evaluate
export PerformanceMeasure, OptimalityGap, DistanceToOptimality, DistanceToStationarity

"""
    @enum PerformanceMeasure OptimalityGap DistanceToOptimality DistanceToStationarity

A `PerformanceMeasure` is a symbolic representation of a performance measure that can be evaluated on the iterates of an algorithm.
- `OptimalityGap`: f(x) - fₛ where fₛ is the optimal value
- `DistanceToOptimality`: ‖x - xₛ‖² where xₛ is an optimal solution
- `DistanceToStationarity`: ‖∇f(x)‖²
"""
@enum PerformanceMeasure begin
    OptimalityGap           # f(x) - fₛ where fₛ is the optimal value
    DistanceToOptimality    # ‖x - xₛ‖² where xₛ is an optimal solution
    DistanceToStationarity  # ‖∇f(x)‖²
end

"""
    evaluate(P::PerformanceMeasure, f::Object, x::Object, xs::Object)

Evaluate the performance measure `P` on the iterates of an algorithm. The function `f` is the objective function, `x` is the current iterate, and `xs` is an optimal solution.
"""
function evaluate(P::PerformanceMeasure, f::Object, x::Object, xs::Object)
    if P == OptimalityGap
        f(x) - f(xs)
    elseif P == DistanceToOptimality
        (x - xs)^2
    elseif P == DistanceToStationarity
        f'(x)^2
    end
end
