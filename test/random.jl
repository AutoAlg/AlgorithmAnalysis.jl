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

# @testitem "Variances of Random Scalars" begin
#     @alg begin
#         X, Y ∈ RandomR
        
#         cv_X = Var(X) == 1.0
#         cv_Y = Var(Y) == 4.0

#         # |Cov(X, Y)| <= sqrt(Cov(X, X) * Cov(Y, Y))
#         # |Cov(X, Y)| <= sqrt(Var(X) * Cov(Y))
#         # |Cov(X, Y)| <= sqrt(1.0 * 4.0))
#         # |Cov(X, Y)| <= 2.0
#         # Cov(X, Y) ∈ [-2.0, 2.0]

#         # Var(X + Y) = Var(X) + 2 Cov(X, Y) + Var(Y)
#         # Var(X + Y) = 1.0 + 2 * [-2.0, 2.0] + 4.0
#         # Var(X + Y) = 5.0 + [-4.0, 4.0]
#         # Var(X + Y) = [1.0, 9.0]

#         with_numerics() do
#             @test evaluate(simplify(minimize(Var(X + Y), cv_X ∧ cv_Y))) ≈ 1.0
#         end

#         with_numerics() do
#             @test evaluate(simplify(maximize(Var(X + Y), cv_X ∧ cv_Y))) ≈ 9.0
#         end


#         with_numerics() do
#             @test evaluate(simplify(minimize(Cov(X, Y), cv_X ∧ cv_Y))) ≈ -2.0
#         end


#         with_numerics() do
#             @test evaluate(simplify(maximize(Cov(X, Y), cv_X ∧ cv_Y))) ≈ 2.0
#         end
#     end
# end