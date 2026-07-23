# test/lyapunov.jl  —  Lyapunov analysis tests

# ==============================================================================
# Tests for extended @alg macro with → syntax
# ==============================================================================

@testitem "@alg with → transitions" begin
    @alg begin
        α, L ∈ R
        x, xs ∈ Rⁿ
        f ∈ F(Rⁿ)
        
        x  → x - α * f'(x)
        xs → xs
    end
    
    @test isdefined(@__MODULE__, :__transition__)
    @test __transition__ isa Transition
    @test length(__transition__.pairs) == 2
end

@testitem "@alg without → transitions (no __transition__ created)" begin
    @alg begin
        α, L ∈ R
        x, xs ∈ Rⁿ
        f ∈ F(Rⁿ)
    end
    
    # __transition__ should not exist if no transitions specified
    @test !isdefined(@__MODULE__, :__transition__)
    @test true  # Verify no error was thrown
end

@testitem "@alg with single → transition" begin
    @alg begin
        α ∈ R
        x ∈ Rⁿ
        f ∈ F(Rⁿ)
        
        x → x - α * f'(x)
    end
    
    @test isdefined(@__MODULE__, :__transition__)
    @test __transition__ isa Transition
    @test length(__transition__.pairs) == 1
end

@testitem "certify: using __transition__ from @alg" begin
    @alg begin
        α, L ∈ R
        x, xs ∈ Rⁿ
        f ∈ F(Rⁿ)
        gs = f'(xs)
        g  = f'(x)
        
        x  → x - α * g
        xs → xs
    end
    
    # Access the automatically-created transition
    @test isdefined(@__MODULE__, :__transition__)
    
    # Use it directly in a certify call
    perf  = (x - xs)^2
    c1 = smooth_convex(f, L)
    c2 = gs^2 == zero(R)
    prob  = certify(__transition__, c1 ∧ c2, perf, nothing)
    tprob = simplify(prob)

    # Evaluate the 1-step worst-case ratio
    result = with_numerics(T = BigFloat, parameters = Dict(α => big"0.1", L => big"1.0")) do
        evaluate(tprob)
    end
    @test isfinite(result)
    @test result ≥ 0
end

# ==============================================================================
# Tests for @transition macro (standalone form, still supported)
# ==============================================================================

@testitem "@transition: single-variable rule" begin
    @alg begin
        α ∈ R
        x, xs ∈ Rⁿ
        f ∈ F(Rⁿ)
        g = f'(x)
    end
    trans = @transition begin
        x  => x - α * g
        xs => xs
    end
    @test trans isa Transition
    @test length(trans.pairs) == 2
    @test isequal(first(trans.pairs[1]), x)
    @test isequal(first(trans.pairs[2]), xs)
end

@testitem "@transition: single-line form" begin
    @alg begin
        α ∈ R
        x ∈ Rⁿ
        f ∈ F(Rⁿ)
        g = f'(x)
    end
    trans = @transition x => x - α * g
    @test trans isa Transition
    @test length(trans.pairs) == 1
    @test isequal(first(trans.pairs[1]), x)
end

# ------------------------------------------------------
# apply_transition
# ------------------------------------------------------

@testitem "apply_transition: scalar distance" begin
    @alg begin
        α ∈ R
        x, xs ∈ Rⁿ
        f ∈ F(Rⁿ)
        g = f'(x)
    end
    perf      = (x - xs)^2
    trans     = Transition(Any[x => x - α*g, xs => xs])
    perf_next = apply_transition(trans, perf)
    expected  = ((x - α*g) - xs)^2
    @test isequal(perf_next, expected)
end

@testitem "apply_transition: function value gap" begin
    @alg begin
        α ∈ R
        x, xs ∈ Rⁿ
        f ∈ F(Rⁿ)
        g = f'(x)
    end
    perf      = f(x) - f(xs)
    trans     = Transition(Any[x => x - α*g, xs => xs])
    perf_next = apply_transition(trans, perf)
    expected  = f(x - α*g) - f(xs)
    @test isequal(perf_next, expected)
end

# ------------------------------------------------------
# certify + simplify pipeline
# ------------------------------------------------------

@testitem "certify: 1-step SDP is solvable (gradient descent, smooth convex)" begin
    @alg begin
        α, L ∈ R
        x, xs ∈ Rⁿ
        f ∈ F(Rⁿ)
        gs = f'(xs)
        g  = f'(x)
    end
    perf  = (x - xs)^2
    trans = @transition begin
        x  => x - α * g
        xs => xs
    end
    c1 = smooth_convex(f, L)
    c2 = gs^2 == zero(R)
    prob  = certify(trans, c1 ∧ c2, perf, nothing)
    tprob = simplify(prob)

    # Evaluate the 1-step worst-case ratio  max ‖x₁-x*‖² / ‖x₀-x*‖²
    result = with_numerics(parameters = Dict(α => 0.1, L => 1.0)) do
        evaluate(tprob)
    end
    @test isfinite(result)
    @test result ≥ 0
end

@testitem "certify: rate matches 1-step PEP (f-suboptimality, smooth convex)" begin
    # Build the same problem both as a PEP and as a Lyapunov 1-step SDP.
    # By primal-dual equivalence they should yield the same optimal value.
    @alg begin
        α, L ∈ R
        x, xs ∈ Rⁿ
        f ∈ F(Rⁿ)
        gs = f'(xs)
        g  = f'(x)
    end

    # --- PEP (N = 1) ---
    obj  = f(x - α * g) - f(xs)
    con  = smooth_convex(f, L) ∧ (gs^2 == zero(R)) ∧ ((x - xs)^2 ≤ one(R))
    pep  = maximize(obj, con)
    tpep = simplify(pep)

    # --- Lyapunov 1-step SDP with f-suboptimality as performance measure ---
    perf  = f(x) - f(xs)
    trans = @transition begin
        x  => x - α * g
        xs => xs
    end
    c_oracle = smooth_convex(f, L) ∧ (gs^2 == zero(R))
    prob     = certify(trans, c_oracle, perf, nothing)
    tprob    = simplify(prob)

    params = Dict(α => 0.075, L => 10.0)

    @test with_numerics(parameters = params) do
        evaluate(tpep) ≈ evaluate(tprob)
    end
end
