using AlgorithmAnalysis

linear_programming_handle = @generate_test_handle function linear_programming()
    @alg let
        x, y ∈ R
        c1 = 50x + 24y ≤ 2400
        c2 = 30x + 33y ≤ 2100
        c3 = x ≥ 45
        c4 = y ≥ 5
        cons = c1 ∧ c2 ∧ c3 ∧ c4
        obj = x + y - 50
        opt = maximize(obj, cons)
        return with_numerics() do
            evaluate(opt) ≈ 1.25 && evaluate(x) ≈ 45.0 && evaluate(y) ≈ 6.25
        end
    end
end

semidefinite_programming_handle = @generate_test_handle function semidefinite_programming()
    local all_pass::Bool = true;

    @alg let
        x ∈ R
        A = [2 x; x 2]
        opt = maximize(x, A ⪰ 0)
        all_pass &= with_numerics() do
            evaluate(opt) ≈ 2.0
        end
    end

    !all_pass && return all_pass;

    @alg let
        x1, x2, x3 ∈ R
        X = [x1 x2; x2 x3]
        A = [1.0 0.0; 0.0 0.0]
        B = [0.0 0.0; 0.0 1.0]
        C = [0.0 1.0; 1.0 0.0]
        c1 = X ⪰ 0
        c2 = tr(A * X) == one(R)
        c3 = tr(B * X) ≤ one(R)
        con = c1 ∧ c2 ∧ c3
        obj = tr(C * X)
        opt = minimize(obj, con)
        all_pass &= with_numerics() do
            evaluate(opt) ≈ -2.0 && evaluate(X) ≈ [1 -1; -1 1]
        end
    end

    return all_pass;
end

performance_estimation_handle = @generate_test_handle function performance_estimation()
    @alg begin
        α, L ∈ R, x, xs ∈ Rⁿ, f ∈ F(Rⁿ)

        gs = f'(xs)
        g = f'(x)
        init = (x - xs)^2
        x⁺ = x - α * g
        f⁺ = f(x⁺)
        c1 = smooth_convex(f, L)
        c2 = gs^2 == zero(R)
        c3 = init ≤ one(R)
        con = c1 ∧ c2 ∧ c3
        obj = f⁺ - f(xs)
        opt = maximize(obj, con)
    end

    topt = simplify(opt)

    return with_numerics(T=BigFloat, parameters=Dict(α => big"0.075", L => big"10.0")) do
        evaluate(topt) ≈ 2.0
    end
end

TestFileDescriptor(
    file_contents=raw"""# Optimization Programs

""",
    named_tests=[
        "Linear programming" => linear_programming_handle,
        "Semidefinite programming" => semidefinite_programming_handle,
        "Performance estimation" => performance_estimation_handle
    ],
    references=[]
)