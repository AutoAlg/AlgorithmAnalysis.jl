using AlgorithmAnalysis

verification_handle = @generate_test_handle function verficiation()

    @alg begin
        α, μ, L, ρ ∈ R
        x, xs ∈ Rⁿ
        f ∈ F(Rⁿ)
        gs = f'(xs)
        g = f'(x)
        x₊ = x - α * g
        t1 = x → x₊
        t2 = xs → xs
        t3 = (f → f) ∧ (f' → f')
        c1 = sector_bounded(f, μ, L)
        c2 = gs^2 == zero(R)
        con = t1 ∧ t2 ∧ t3 ∧ c1 ∧ c2
        perf = (x - xs)^2
        prob = certify(con, perf, ρ)
        opt = rate(con, perf)
    end


    local all_pass::Bool = true;

    with_parameters(Dict(ρ => 0.81, α => 0.1, μ => 1.0, L => 10.0)) do
        tprob = simplify(prob)

        with_numerics() do
            all_pass &= evaluate(tprob)
        end
    end

    !all_pass && return false;

    with_parameters(Dict(ρ => 0.8, α => 0.1, μ => 1.0, L => 10.0)) do
        tprob = simplify(prob)

        with_numerics() do
            all_pass &= !evaluate(tprob)
        end
    end

    !all_pass && return false;

    with_parameters(Dict(α => 0.1, μ => 1.0, L => 10.0)) do

        topt = simplify(opt)

        all_pass = (evaluate(topt) ≈ 0.81)
    end

    return all_pass
end


fileContents = raw"""
# Gradient Descent

For gradient descent with stepsize ``\alpha`` applied to ``μ``-strongly convex and ``L``-smooth functions, the distance to optimality converges at a rate of
```math
    \rho = 1-2\alpha \mu L/(L+\mu) \quad \text{if} \quad 0 < \alpha \leq \frac{2}{L+\mu}.
```
In particular, if ``\alpha = 2/(L+\mu)``, the rate is ``(\kappa-1)/(\kappa+1)`` where ``\kappa = L/\mu``.
""";


TestFileDescriptor(
    file_contents=fileContents,
    named_tests=["Gradient Descent over a Smooth Strongly Convex function" => verification_handle],
    references=[Reference("10.1007/978-3-319-91578-4", "Theorem 2.1.15")]
)