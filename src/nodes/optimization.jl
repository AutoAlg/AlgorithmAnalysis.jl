export minimize, maximize, feasible, certify, rate

abstract type Minimization <: R end
abstract type Maximization <: R end
abstract type Bisection <: R end

const Optimization = Union{<:Minimization, <:Maximization, <:Feasibility}

"""
    maximize(obj, con)

Maximize an objective subject to a constraint.
"""
function maximize(obj::Node, con::Node{<:Prop})
    return Term{Maximization}(maximize, [obj, con])
end

"""
    minimize(obj, con)

Minimize an objective subject to a constraint.
"""
function minimize(obj::Node, con::Node{<:Prop})
    return Term{Minimization}(minimize, [obj, con])
end

"""
    feasible(con)

Determine whether or not a constraint is feasible.

## Examples

    @alg let
        x ∈ R
        A = [-2 x; x -2]
        with_numerics() do
            evaluate(feasible(A ⪰ 0))
        end
    end
"""
function feasible(con::Node{<:Prop} = satisfied())
    return Term{Feasibility}(feasible, [con])
end

function bisection(val::Node{R}, feas::Node{Feasibility}, minval::Float64, maxval::Float64, tol::Float64)
    return Term{Bisection}(bisection, [val, feas, minval, maxval, tol])
end

sense(opt::Node{<:Optimization}) = Symbol(operation(opt))
sense(::Node{LyapunovCertificate}) = :feasible
is_minimization(opt::Node{<:Optimization}) = isequal(sense(opt), :minimize)
is_maximization(opt::Node{<:Optimization}) = isequal(sense(opt), :maximize)
is_feasibility(opt::Node{<:Optimization}) = isequal(sense(opt), :feasible)

objective(opt::Node{Minimization}) = arguments(opt)[1]
objective(opt::Node{Maximization}) = arguments(opt)[1]

constraint(opt::Node{Minimization}) = arguments(opt)[2]
constraint(opt::Node{Maximization}) = arguments(opt)[2]
constraint(opt::Node{Feasibility}) = arguments(opt)[1]

"""
    certify(constraint, performance, rate)

Construct a Lyapunov certification problem. This searches for a parameterized Lyapunov function which certifies that the performance measure subject to the constraint converges with the specified rate.

To search for a Lyapunov certificate, the algorithm must have a state as specified by transitions within the constaint. For a state `x` and next state `x₊`, a valid Lyapunov certificate `V(x)` must satisfy the following conditions:
1. `V(x) ≥ performance(x)`
2. `V(x⁺) ≤ rate * V(x)`
Together, these imply that `performance` decreases by a factor of `rate` at each iteration of the algorithm. To make the search tractable, the Lyapunov candidate is parameterized linearly in the state so that `V(x) = θ ⋅ x` with parameter vector `θ`. This node evaluates to a proposition that specifies whether or not such a Lyapunov certificate exists.
"""
function certify(con::Node{<:Prop}, perf::Node{R}, rate::Node{R})
    return Term{LyapunovCertificate}(certify, Any[con, perf, rate])
end

"""
    rate(constraint, performance)

Construct a Lyapunov certification problem that finds the fastest rate for which a Lyapunov certificate exists. This node evaluates to the minimal rate for which [`certify`](@ref) holds.
"""
function rate(con::Node{<:Prop}, perf::Node{R})
    return Term{LyapunovCertificate}(rate, Any[con, perf, nothing])
end

constraint(t::Node{LyapunovCertificate}) = arguments(t)[1]
performance(con::Node{LyapunovCertificate}) = arguments(con)[2]
rate(t::Node{LyapunovCertificate}) = arguments(t)[3]
