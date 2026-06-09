@testitem "Feasibility" begin
    @alg let
        x ∈ R
        A = Sⁿ([-2.0 x; x -2.0])
        @test with_numerics() do
            evaluate(feasible((x ≥ 1.0) ∧ (x ≤ 2.0)))
        end
        @test with_numerics() do
            !evaluate(feasible((x ≥ 1.0) ∧ (x ≤ -1.0)))
        end
        @test with_numerics() do
            !evaluate(feasible(A ⪰ 0))
        end
    end
end