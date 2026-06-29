@testitem "Linear programming" begin
    @alg let
        x, y ∈ R
        c1 = 50x + 24y ≤ 2400
        c2 = 30x + 33y ≤ 2100
        c3 = x ≥ 45
        c4 = y ≥ 5
        cons = c1 ∧ c2 ∧ c3 ∧ c4
        obj = x + y - 50
        opt = maximize(obj, cons)
        @test with_numerics() do
            evaluate(opt) ≈ 1.25 && evaluate(x) ≈ 45.0 && evaluate(y) ≈ 6.25
        end
    end
end

@testitem "Semidefinite programming" begin
    @alg let
        x ∈ R
        A = [2 x; x 2]
        opt = maximize(x, A ⪰ 0)
        @test with_numerics() do
            evaluate(opt) ≈ 2.0
        end
    end

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
        @test with_numerics() do
            evaluate(opt) ≈ -2.0 && evaluate(X) ≈ [1 -1; -1 1]
        end
    end
end

@testitem "Performance estimation" begin
    @alg begin
        α, L ∈ R, x, xs ∈ Rⁿ, f ∈ F(Rⁿ)

        gs   = f'(xs)
        g    = f'(x)
        init = (x - xs)^2
        x⁺   = x - α * g
        f⁺   = f(x⁺)
        c1   = smooth_convex(f, L)
        c2   = gs^2 == zero(R)
        c3   = init ≤ one(R)
        con  = c1 ∧ c2 ∧ c3
        obj  = f⁺ - f(xs)
        opt  = maximize(obj, con)
    end

    topt = simplify(opt)

    @test with_numerics(T = BigFloat, parameters = Dict(α => big"0.075", L => big"10.0")) do
        evaluate(topt) ≈ 2.0
    end
end
