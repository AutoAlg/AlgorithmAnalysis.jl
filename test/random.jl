@testitem "Means of Random Scalars" begin
    @alg begin
        X, Y ∈ RandomR
        
        cμ_X = E(X) == 2.0
        cμ_Y = ((E(Y) >= 0.0) ∧ (E(Y) <= 3.0))

        with_numerics() do
            @test evaluate(simplify(minimize(E(X + Y), cμ_X ∧ cμ_Y))) ≈ 2.0
        end

        with_numerics() do
            @test evaluate(simplify(maximize(E(X + Y), cμ_X ∧ cμ_Y))) ≈ 5.0
        end
    end
end

@testitem "Covariances of Random Scalars" begin
    @alg begin
        X, Y ∈ RandomR
        
        cv_X = Var(X) == 1.0
        cv_Y = Var(Y) == 4.0

        # |Cov(X, Y)| <= sqrt(Cov(X, X) * Cov(Y, Y))
        # |Cov(X, Y)| <= sqrt(Var(X) * Var(Y))
        # |Cov(X, Y)| <= sqrt(1.0 * 4.0))
        # |Cov(X, Y)| <= 2.0
        # Cov(X, Y) ∈ [-2.0, 2.0]

        # Var(X + Y) = Var(X) + 2 Cov(X, Y) + Var(Y)
        # Var(X + Y) = 1.0 + 2 * [-2.0, 2.0] + 4.0
        # Var(X + Y) = 5.0 + [-4.0, 4.0]
        # Var(X + Y) = [1.0, 9.0]
 
        with_numerics() do
          @test evaluate(simplify(minimize(Var(X + Y), cv_X ∧ cv_Y))) ≈ 1.0
        end

        with_numerics() do
            @test evaluate(simplify(maximize(Var(X + Y), cv_X ∧ cv_Y))) ≈ 9.0
        end


        with_numerics() do
            @test evaluate(simplify(minimize(Cov(X, Y), cv_X ∧ cv_Y))) ≈ -2.0
        end


        with_numerics() do
            @test evaluate(simplify(maximize(Cov(X, Y), cv_X ∧ cv_Y))) ≈ 2.0
        end

        cxv_YX = Cov(Y, X) == 1.5  

        # Var(X + Y) = Var(X) + 2 Cov(X, Y) + Var(Y)
        # Var(X + Y) = 1.0 + 2 * 1.5 + 4.0
        # Var(X + Y) = 1.0 + 3.0 + 4.0
        # Var(X + Y) = 8.0

        with_numerics() do
            @test evaluate(simplify(minimize(Var(X + Y), cv_X ∧ cv_Y ∧ cxv_YX))) ≈ 8.0
        end
        with_numerics() do
            @test evaluate(simplify(maximize(Var(X + Y), cv_X ∧ cv_Y ∧ cxv_YX))) ≈ 8.0
        end


        with_numerics() do
            @test evaluate(simplify(minimize(Cov(X, Y), cv_X ∧ cv_Y ∧ cxv_YX))) ≈ 1.5
        end


        with_numerics() do
            @test evaluate(simplify(maximize(Cov(X, Y), cv_X ∧ cv_Y ∧ cxv_YX))) ≈ 1.5
        end
    end
end

@testitem "Algebra with Random Scalars" begin
    @alg begin
        X, Y, Z, W ∈ RandomR
        a ∈ R

        cv_X  = Var(X) == 1.0
        cv_Y  = Var(Y) == 4.0
        cc_XY_zero = Cov(X, Y) == 0.0
        cc_XY_half = Cov(X, Y) == 0.5


        # Var(2X + 3Y)
        # Cov(2X + 3Y, 2X + 3Y)
        # Cov(2X, 2X + 3Y) + Cov(3Y, 2X + 3Y)
        # 2 * Cov(X, 2X + 3Y) + 3 * Cov(Y, 2X + 3Y)
        # 2 * (Cov(X, 2X) + Cov(X, 3Y)) + 3 * (Cov(Y, 2X) + Cov(Y, 3Y))
        # 2 * (2 * Cov(X, X) + 3 * Cov(X, Y)) + 3 * (2 * Cov(Y, X) + 3 * Cov(Y, Y))
        # 4 * Var(X) + 6 * Cov(X, Y) + 6 * Cov(Y, X) + 9 * Cov(Y, Y)
        # 4 * Var(X) + 12 * Cov(X, Y) + 9 * Cov(Y, Y)
        # 4 * 1.0 + 12 * 0.0 + 9 * 4.0
        # 40.0
        with_numerics() do
            @test evaluate(simplify(minimize(Var(2.0 * X + 3.0 * Y), cv_X ∧ cv_Y ∧ cc_XY_zero))) ≈ 40.0 
        end
        with_numerics() do
            @test evaluate(simplify(maximize(Var(2.0 * X + 3.0 * Y), cv_X ∧ cv_Y ∧ cc_XY_zero))) ≈ 40.0 
        end

        with_numerics() do
            @test evaluate(simplify(maximize(Var(2 * X + Y * 3), cv_X ∧ cv_Y ∧ cc_XY_zero))) ≈ 40.0 
        end

        # Cov(3X, 4Y)
        # 12 * Cov(X, Y)
        # 12 * 0.5
        # 6
        with_numerics() do
            @test evaluate(simplify(maximize(Cov(3.0 * X, 4.0 * Y), cv_X ∧ cv_Y ∧ cc_XY_half))) ≈ 6.0 
        end

        # Var(a * Y)
        # a^2 * Var(Y)
        # 3^2 * 4.0
        # 36
        with_numerics(parameters = Dict(a => 3.0)) do
            @test evaluate(simplify(maximize(Var(a * Y), cv_Y))) ≈ 36.0
        end
    end

end

@testitem "Non Zero Mean Random Scalars" begin
    @alg begin
        X, Y ∈ RandomR

        cE_X = E(X) == 3.0
        cv_X = Var(X) == 2.0

        cE_Y = E(Y) == 4.0
        cv_Y = Var(Y) == 5.0

        cs = cE_X ∧ cv_X ∧ cE_Y ∧ cv_Y

        # E(2.0 * X + 1.0 - 3.0 * Y)
        # E(2.0 * 3.0 + 1.0 - 3.0 * 4.0)
        # -5
        with_numerics() do
            @test evaluate(simplify(minimize(E(2.0 * X + 1.0 - 3.0 * Y), cs))) ≈ -5.0
        end

        with_numerics() do
            @test evaluate(simplify(minimize(E(X - 1.0), cs))) ≈ 2.0 
        end
        with_numerics() do
            @test evaluate(simplify(minimize(E(1.0 - X), cs))) ≈ -2.0 
        end
        
        # Var(2.0 * X + 1.0)
        # Var(2.0 * X)
        # 4 * Var(X)
        # 4 * 2.0
        # 8.0
        with_numerics() do
            @test evaluate(simplify(maximize(Var(2.0 * X + 1.0), cs))) ≈ 8.0 
        end

        # |Cov(X, Y)| <= sqrt(Cov(X, X) * Cov(Y, Y))
        # |Cov(X, Y)| <= sqrt(Var(X) * Var(Y))
        # |Cov(X, Y)| <= sqrt(2.0 * 5.0))
        # |Cov(X, Y)| <= sqrt(10)
        # Cov(X, Y) ∈ [-sqrt(10), sqrt(10))]
        with_numerics() do
            @test evaluate(simplify(minimize(Cov(X + 5.0, Y), cs))) ≈ -sqrt(10.0)
        end
        with_numerics() do
            @test evaluate(simplify(maximize(Cov(X + 5.0, Y), cs))) ≈ sqrt(10.0)
        end


    end
end

@testitem "scalar reductions" begin
      @alg begin
        X, Y, Z ∈ RandomR
        a ∈ R

        @test isequal(simplify(E(X + Y)), E(X) + E(Y))
        @test isequal(simplify(E(X - Y)), E(X) - E(Y))
        @test isequal(simplify(E(-X)), -1.0 * E(X))

        @test isequal(simplify(E(2.0 * X)), 2.0 * E(X))
        @test isequal(simplify(E(X * 2.0)), 2.0 * E(X))
        @test isequal(simplify(E(a * X)), a * E(X))

        @test isequal(simplify(E(X + 1.0)), 1.0 + E(X))
        @test isequal(simplify(E(1.0 - X)), 1.0 + -1.0 * E(X))

        @test isequal(E(E(X)), E(X))
        @test isequal(Var(R(3.0)), zero(R))
        @test isequal(Cov(X, R(5.0)), zero(R))

        @test isequal(simplify(Var(X)), Cov(X, X))
        @test isequal(simplify(Var(X + 5.0)), Cov(X, X))

        @test isequal(simplify(Cov(2.0 * X, Y)), 2.0 * Cov(X, Y))
        @test isequal(simplify(Cov(X, 3.0 * Y)), 3.0 * Cov(X, Y))
        @test isequal(simplify(Cov(-X, Y)), -1.0 * Cov(X, Y))
        @test isequal(simplify(Cov(X - Y, Z)), Cov(X, Z) - Cov(Y, Z))
        @test isequal(simplify(Cov(Z, X - Y)), Cov(Z, X) - Cov(Z, Y))
        @test isequal(simplify(Cov(X + 5.0, Y)), Cov(X, Y))

        @test isequal(simplify(E(X * Y)), E(X) * E(Y) + Cov(X, Y))
        @test isequal(simplify(E(X * X)), E(X) * E(X) + Cov(X, X))

        @test isequal(simplify(E(X * Y * Z)), E(X * Y * Z))
        @test isequal(simplify(Cov(X * Y, Z)), Cov(X * Y, Z))
    end
end

@testitem "vector reductions" begin
    @alg begin
        x, y, z, w ∈ Rⁿ
        X, Y, Z, W ∈ RandomRⁿ

        @test Var(x) isa Node{R}
        @test Cov(x, X) isa Node{R}
        @test Cov(X, x) isa Node{R}
        @test Cov(x, y) isa Node{R}
        @test Var(X) isa Node{R}
        @test Cov(X, Y) isa Node{R}

        @test E(X) isa Node{Rⁿ}
        @test E(x) isa Node{Rⁿ}
        @test iszero(E(centered_component(X)))
        @test isequal(E(x), x)

        @test isequal(simplify(Var(X + x)), Cov(X, X))
        @test isequal(simplify(Cov(X + x, Y)), Cov(X, Y))
        @test isequal(simplify(Cov(X, Y + x)), Cov(X, Y))
        @test isequal(simplify(Var(2.0 * X + x)), simplify(Var(2.0 * X)))

        @test isequal(simplify(E(X + Y)), E(X) + E(Y))
        @test isequal(simplify(E(X + x)), x + E(X))

        @test mean_component(X) isa Node{Rⁿ}
        @test centered_component(X) isa Node{RandomRⁿCenteredComponent}
        @test centered_product_leaf(centered_component(X), centered_component(Y)) isa Node{R}
        @test isequal(centered_product_leaf(centered_component(Y), centered_component(X)), centered_product_leaf(centered_component(X), centered_component(Y)))
        @test_throws ErrorException mean_component(X + Y)
        @test_throws ErrorException centered_component(X + Y)

        @test isequal(x'y, x'(y))
        @test isequal(x'y, x ⋅ y)
        @test isequal(x'*y, x ⋅ y)
        @test isequal(X^2, X'X)
        @test X'Y isa Node{RandomR}
        @test x'X isa Node{RandomR}
        @test_throws MethodError x'y'
        @test_throws MethodError X * Y

        @test isequal(simplify(E(2.0 * X)), 2.0 * E(X))
        @test isequal(simplify(E(X - Y)), E(X) + -1.0 * E(Y))
        @test isequal(simplify(E(X'*Y)), E(X)'*E(Y) + Cov(X, Y))
        @test isequal(simplify(E(x'*X)), x'*E(X))

        @test isequal(x'*X, x ⋅ X)
        @test isequal(X'*Y, X ⋅ Y)
        @test isequal(Z'*y, Z ⋅ y)
    end
end

@testitem "deterministic means of random vectors" begin
    @alg begin
        X, Y ∈ RandomRⁿ

        cμ_X = E(X)^2 == 4.0
        cμ_Y = E(Y)^2 == 1.0

        # E(X + Y)^2
        # (E(X) + E(Y))^2
        # (E(X) + E(Y))'*(E(X) + E(Y))
        # E(X)^2 + 2 * E(X)'*E(Y) + E(Y)^2

        # |E(X)'*E(Y)| <= sqrt(E(X)^2 * E(Y)^2)
        # |E(X)'*E(Y)| <= sqrt(4.0 * 1.0)
        # |E(X)'*E(Y)| <= 2.0
        # E(X)'*E(Y) ∈ [-2.0, 2.0]

        # E(X)^2 + 2 * E(X)'*E(Y) + E(Y)^2
        # 4.0 + [-4.0, 4.0] + 1.0
        # 5.0 + [-4.0, 4.0]
        # [1.0, 9.0]

        with_numerics() do
            @test evaluate(simplify(minimize(E(X + Y)^2, cμ_X ∧ cμ_Y))) ≈ 1.0
        end

        with_numerics() do
            @test evaluate(simplify(maximize(E(X + Y)^2, cμ_X ∧ cμ_Y))) ≈ 9.0
        end

    end
end


@testitem "Means of Random Vectors" begin
    @alg begin
        X, Y ∈ RandomRⁿ
        
        cμ_X = E(X^2) == 4.0
        cμ_Y = E(Y^2) == 1.0

        # E((X + Y)^2)
        # E(X^2 + 2 * X'*Y + Y^2)
        # E(X^2) + 2 * E(X'*Y) + E(Y^2)
        # 4.0 + 2 * E(X'*Y) + 1.0

        # |E(X'*Y)| <= sqrt(E(X^2) * E(Y^2))
        # |E(X'*Y)| <= sqrt(4.0 * 1.0)
        # |E(X'*Y)| <= 2.0
        # E(X'*Y) ∈ [-2.0, 2.0]
        # 4.0 + 2 * E(X'*Y) + 1.0
        # 4.0 + 2 * [-2.0, 2.0] + 1.0
        # 5.0 + [-4.0, 4.0]
        # [1.0, 9.0]

        with_numerics() do
            @test evaluate(simplify(minimize(E((X + Y)^2), cμ_X ∧ cμ_Y))) ≈ 1.0
        end
        
        with_numerics() do
            @test evaluate(simplify(maximize(E((X + Y)^2), cμ_X ∧ cμ_Y))) ≈ 9.0
        end      
    end
end


