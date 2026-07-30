# test/lyapunov.jl  —  Lyapunov analysis tests

# ==============================================================================
# Tests for extended @alg macro with → syntax
# ==============================================================================

# @testitem "@alg with → transitions" begin
#     @alg begin
#         α, L ∈ R
#         x, xs ∈ Rⁿ
#         f ∈ F(Rⁿ)
        
#         t1 = x  → x - α * f'(x)
#         t2 = xs → xs
#     end
# end

# @testitem "certify: using __transition__ from @alg" begin
#     @alg begin
#         α, L ∈ R
#         x, xs ∈ Rⁿ
#         f ∈ F(Rⁿ)
#         gs = f'(xs)
#         g  = f'(x)
        
#         x  → x - α * g
#         xs → xs
#     end
    
#     # Access the automatically-created transition
#     @test isdefined(@__MODULE__, :__transition__)
    
#     # Use it directly in a certify call
#     perf  = (x - xs)^2
#     c1 = smooth_convex(f, L)
#     c2 = gs^2 == zero(R)
#     prob  = certify(__transition__, c1 ∧ c2, perf, big"0.99")
#     tprob = simplify(prob)

#     # Evaluate feasibility of the Lyapunov certificate at fixed rate.
#     result = with_numerics(T = BigFloat, parameters = Dict(α => big"0.1", L => big"1.0")) do
#         evaluate(tprob)
#     end
#     @test result isa Bool
# end

# # ==============================================================================
# # Tests for @transition macro (standalone form, still supported)
# # ==============================================================================

# @testitem "@transition: single-variable rule" begin
#     @alg begin
#         α ∈ R
#         x, xs ∈ Rⁿ
#         f ∈ F(Rⁿ)
#         g = f'(x)
#     end
#     trans = @transition begin
#         x  => x - α * g
#         xs => xs
#     end
#     @test trans isa Transition
#     @test length(trans.pairs) == 2
#     @test isequal(first(trans.pairs[1]), x)
#     @test isequal(first(trans.pairs[2]), xs)
# end

# @testitem "@transition: single-line form" begin
#     @alg begin
#         α ∈ R
#         x ∈ Rⁿ
#         f ∈ F(Rⁿ)
#         g = f'(x)
#     end
#     trans = @transition x => x - α * g
#     @test trans isa Transition
#     @test length(trans.pairs) == 1
#     @test isequal(first(trans.pairs[1]), x)
# end

# # ------------------------------------------------------
# # apply_transition
# # ------------------------------------------------------

# @testitem "apply_transition: scalar distance" begin
#     @alg begin
#         α ∈ R
#         x, xs ∈ Rⁿ
#         f ∈ F(Rⁿ)
#         g = f'(x)
#     end
#     perf      = (x - xs)^2
#     trans     = Transition(Any[x => x - α*g, xs => xs])
#     perf_next = apply_transition(trans, perf)
#     expected  = ((x - α*g) - xs)^2
#     @test isequal(perf_next, expected)
# end

# @testitem "apply_transition: function value gap" begin
#     @alg begin
#         α ∈ R
#         x, xs ∈ Rⁿ
#         f ∈ F(Rⁿ)
#         g = f'(x)
#     end
#     perf      = f(x) - f(xs)
#     trans     = Transition(Any[x => x - α*g, xs => xs])
#     perf_next = apply_transition(trans, perf)
#     expected  = f(x - α*g) - f(xs)
#     @test isequal(perf_next, expected)
# end

# # ------------------------------------------------------
# # certify + simplify pipeline
# # ------------------------------------------------------

# @testitem "certify: fixed-rate feasibility is solvable (gradient descent, smooth convex)" begin
#     @alg begin
#         α, L ∈ R
#         x, xs ∈ Rⁿ
#         f ∈ F(Rⁿ)
#         gs = f'(xs)
#         g  = f'(x)
#     end
#     perf  = (x - xs)^2
#     trans = @transition begin
#         x  => x - α * g
#         xs => xs
#     end
#     c1 = smooth_convex(f, L)
#     c2 = gs^2 == zero(R)
#     prob  = certify(trans, c1 ∧ c2, perf, 0.99)
#     tprob = simplify(prob)

#     # Evaluate feasibility of the Lyapunov certificate.
#     result = with_numerics(parameters = Dict(α => 0.1, L => 1.0)) do
#         evaluate(tprob)
#     end
#     @test result isa Bool
# end

# @testitem "certify: rate argument is required" begin
#     @alg begin
#         α, L ∈ R
#         x, xs ∈ Rⁿ
#         f ∈ F(Rⁿ)
#         gs = f'(xs)
#         g  = f'(x)
#     end

#     perf  = f(x) - f(xs)
#     trans = @transition begin
#         x  => x - α * g
#         xs => xs
#     end
#     c_oracle = smooth_convex(f, L) ∧ (gs^2 == zero(R))

#     @test_throws Exception certify(trans, c_oracle, perf, nothing)
# end

