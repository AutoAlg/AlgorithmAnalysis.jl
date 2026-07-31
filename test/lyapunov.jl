@testitem "Lyapunov analysis on gradient descent" begin

    @alg begin
        α, μ, L, ρ ∈ R
        x, xs ∈ Rⁿ
        f ∈ F(Rⁿ)
        gs = f'(xs)
        g  = f'(x)
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

    with_parameters(Dict(ρ => 0.81, α => 0.1, μ => 1.0, L => 10.0)) do
        
        tprob = simplify(prob)

        with_numerics() do
            @test evaluate(tprob)
        end
    end

    with_parameters(Dict(ρ => 0.8, α => 0.1, μ => 1.0, L => 10.0)) do
        
        tprob = simplify(prob)

        with_numerics() do
            @test !evaluate(tprob)
        end
    end

    with_parameters(Dict(α => 0.1, μ => 1.0, L => 10.0)) do
        
        topt = simplify(opt)

        @test evaluate(topt) ≈ 0.81
    end
end
