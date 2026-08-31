using AlgorithmAnalysis

feasibility_tests_handle = @generate_test_handle function feasibility_tests()
    @alg let
        x ∈ R
        A = [-2 x; x -2]

        local all_pass::Bool = true;

        all_pass &= with_numerics() do
            evaluate(feasible((x ≥ 1) ∧ (x ≤ 2)))
        end

        !all_pass && return all_pass;

        all_pass &= with_numerics() do
            !evaluate(feasible((x ≥ 1) ∧ (x ≤ -1)))
        end

        !all_pass && return all_pass;

        all_pass &= with_numerics() do
            !evaluate(feasible(A ⪰ 0))
        end

        return all_pass;
    end
end

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


TestFileDescriptor(
    file_contents=raw"""# Numerics

As a consequence of the types of analysis that the framework needs to perform, we are able to model Feasibility problems, linear programing problems.


""",
    named_tests=[
        "Feasibility" => feasibility_tests_handle,
        "Linear programming" => linear_programming_handle,
        "Semidefinite programming" => semidefinite_programming_handle,],
    references=[]
)
