# @testitem "Feasibility" begin
#     @alg let
#         x ∈ R
#         A = [-2 x; x -2]
#         @test with_numerics() do
#             evaluate(feasible((x ≥ 1) ∧ (x ≤ 2)))
#         end
#         @test with_numerics() do
#             !evaluate(feasible((x ≥ 1) ∧ (x ≤ -1)))
#         end
#         @test with_numerics() do
#             !evaluate(feasible(A ⪰ 0))
#         end
#     end
# end