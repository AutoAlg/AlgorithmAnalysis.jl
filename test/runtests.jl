using AlgorithmAnalysis
using Test

default_setup()

@testset "AlgorithmAnalysis.jl" begin

  ######################################################
  # FEASIBILITY
  ######################################################
  @test @eval @alg let
    x ∈ R
    return feasible( (x ≥ 1.0) ∧ (x ≤ 2.0) )
  end

  @test @eval @alg let
    x ∈ R
    return !feasible( (x ≥ 1.0) ∧ (x ≤ -1.0) )
  end

  @test @eval @alg let
    x ∈ R
    A = [-2.0 x; x -2.0]
    return !feasible( zero(Sym(R,2)) ⪯ A )
  end

  ######################################################
  # LINEAR PROGRAMMING
  ######################################################
  @test @eval @alg let
    x, y ∈ R
    c1 = 50.0 * x + 24.0 * y ≤ 2400.0
    c2 = 30.0 * x + 33.0 * y ≤ 2100.0
    c3 = x ≥ 45.0
    c4 = y ≥ 5.0
    cons = c1 ∧ c2 ∧ c3 ∧ c4
    obj = x + y - 50.0
    opt = maximize(obj, cons)
    return with_optimizer() do
      evaluate(opt) ≈ 1.25 && evaluate(x) ≈ 45.0 && evaluate(y) ≈ 6.25
    end
  end

  ######################################################
  # SEMIDEFINITE PROGRAMMING
  ######################################################
  @test @eval @alg let
    x ∈ R
    A = [2.0 x; x 2.0]
    con = zero(Sym(R, 2)) ⪯ A
    obj = x
    opt = maximize(obj, con)
    return evaluate(opt) ≈ 2.0
  end

  @test @eval @alg let
    X ∈ Sym(R, 2)
    A = Object[1.0 0.0; 0.0 0.0]
    B = Object[0.0 0.0; 0.0 1.0]
    C = Object[0.0 1.0; 1.0 0.0]
    b = one(R)
    c1 = zero(Sym(R, 2)) ⪯ X
    c2 = tr(A * X) == b
    c3 = tr(B * X) ≤ b
    con = c1 ∧ c2 ∧ c3
    obj = tr(C * X)
    opt = minimize(obj, con)
    return with_optimizer() do
      evaluate(opt) ≈ -2.0 && evaluate(X) ≈ [1 -1; -1 1]
    end
  end

  # @test begin
  #   m,L = 1,10
  #   α = 2 / (L + m)
  #   @algorithm begin
  #       f = DifferentiableFunctional{Rⁿ}()
  #       xs = first_order_stationary_point(f)
  #       f' ∈ SectorBounded(m, L, xs, f'(xs))
  #       x0 = Rⁿ()
  #       x1 = x0 - α * f'(x0)
  #       x0 => x1
  #       performance = (x0 - xs)^2
  #   end
  #   rate(performance) ≈ ((L-m)/(L+m))^2
  # end
end
