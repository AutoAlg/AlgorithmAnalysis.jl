using AlgorithmAnalysis
using Test

default_setup()

@testset "AlgorithmAnalysis.jl" begin

  ######################################################
  # FEASIBILITY
  ######################################################
  @test @eval begin
    @var x ∈ R
    feasible( (x ≥ 1.0) ∧ (x ≤ 2.0) )
  end

  @test @eval begin
    @var x ∈ R
    !feasible( (x ≥ 1.0) ∧ (x ≤ -1.0) )
  end

  @test @eval begin
    @var x ∈ R
    @def A = [-2.0 x; x -2.0]
    !feasible( zero(Sym(R,2)) ⪯ A )
  end

  ######################################################
  # LINEAR PROGRAMMING
  ######################################################
  @test @eval begin
    @var x ∈ R, y ∈ R
    @def c1 = 50.0 * x + 24.0 * y ≤ 2400.0
    @def c2 = 30.0 * x + 33.0 * y ≤ 2100.0
    @def c3 = x ≥ 45.0
    @def c4 = y ≥ 5.0
    @def cons = c1 ∧ c2 ∧ c3 ∧ c4
    @def obj = x + y - 50.0
    @def opt = maximize(obj, cons)
    with_optimizer() do
      evaluate(opt) ≈ 1.25 && evaluate(x) ≈ 45.0 && evaluate(y) ≈ 6.25
    end
  end

  ######################################################
  # SEMIDEFINITE PROGRAMMING
  ######################################################
  @test @eval begin
    @var x ∈ R
    @def A = [2.0 x; x 2.0]
    @def con = zero(Sym(R, 2)) ⪯ A
    @def obj = x
    @def opt = maximize(obj, con)
    evaluate(opt) ≈ 2.0
  end

  @test @eval begin
    @var t ∈ R, x ∈ R
    @def X = [1.0 x; x t]
    @def con = zero(Sym(R, 2)) ⪯ A
    @def opt = maximize(x, con)
    evaluate(opt) ≈ 2.0
  end

  @test @eval begin
    @var X ∈ Sym(R, 2)
    @def A = Object[1.0 0.0; 0.0 0.0]
    @def B = Object[0.0 0.0; 0.0 1.0]
    @def C = Object[0.0 1.0; 1.0 0.0]
    @def b = one(R)
    @def c1 = zero(Sym(R, 2)) ⪯ X
    @def c2 = tr(A * X) ≐ b
    @def c3 = tr(B * X) ≤ b
    @def con = c1 ∧ c2 ∧ c3
    @def obj = tr(C * X)
    @def opt = minimize(obj, con)
    with_optimizer() do
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
