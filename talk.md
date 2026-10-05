SSA stuff is a dead end because of interpolation conditions & the ensuing blow up
docs is ready for merging now
how do we want the syntax to look for these problems

```julia
# A random variable has a value `v` that's stored as
struct RV begin
    mean::T     # E[v]
    centered::T # v - E[v]
end
# v = RV
# v = mean + centered
# v = E[v] + v - E[v]
# v = v

# we get the definitions we need
# Expectation
# E[v] = E[v.mean] + E[v.centered] = v.mean + 0 = v.mean

# Linear Combination
# aX + bY = RV(a * x.mean + b * y.mean, a * x.centered + b * y.centered)

# Covariance
# The covariance matrix of two vectors is defined as 
# Cov(X, Y) = E[(X - μ_X)(Y - μ_y)']
# which is Cov(X, Y) = E[c_X * c_Y'] but that's unrepresentable because it's nxn
# we can take the trace and move that around
# Tr(Cov(X, Y)) = Tr(E[c_X  * c_Y'])
# Tr(Cov(X, Y)) = Tr(E[c_Y' * c_X ])
# Tr(Cov(X, Y)) = E[c_Y '* c_X]


# Expected Inner products
# E[X'*Y] = E[X]'*E[Y] + Tr(Cov(X, Y))
# E[X'*Y] = E[X]'*E[Y] + E[c_Y '* c_X]

# Variance is just co variance with itself
# Var(X) = Tr(Cov(X, X))


# Examples

# (E(v)'*E(v)) <= 1 lowers into μ_V + c_V <= 1

# Var(v) <= 2 lowers into  E[c_Y '* c_X] <= 2
# where 
# E[c_Y'*c_X] = E[c_Y]'*E[c_X] + Tr(Cov(c_Y, c_X))
# E[c_Y'*c_X] = 0 + Tr(Cov(c_Y, c_X))




# Tr(Cov(g1, g2)) = E[(g1-E[g1])' * (g2-E[g2])].



# Definition of covariance 
# Cov(X, Y) = E[(X - μ_X)*(Y - μ_y)']
# if E[X] = 0, E[Y] = 0




# Cov(X, Y) = E[X'Y] 


# E[X'Y] = E[X]'E[Y] + Tr(Cov(X, Y))
# E[⟨v_1, v_2⟩] = Tr(Cov(v_1, v_2)) + ⟨E[v_1], E[v_2]⟩
# E[v_1'v_2] = Tr(Cov(v_1, v_2)) + E[v_1]'E[v_2]

# v_1 = μ_1+c_1
# v_2 = μ_2+c_2

# E[(μ_1+c_1)'(μ_2+c_2)] = Tr(Cov(v_1, v_2)) + E[v_1]'E[v_2]
# E[μ_1'μ_2 + μ_1'c_2 + c_1'μ_2 + c_1'c_2] = Tr(Cov(v_1, v_2)) + E[v_1]'E[v_2]
# E[μ_1'μ_2] + E[μ_1'c_2] + E[c_1'μ_2] + E[c_1'c_2] = Tr(Cov(v_1, v_2)) + E[v_1]'E[v_2]
# E[μ_1'c_2] = μ_1'E[c_2] = μ_1'0 = 0
# E[μ_2'c_1] = μ_2'E[c_1] = μ_2'0 = 0
# E[μ_1'μ_2] + E[c_1'c_2] = Tr(Cov(v_1, v_2)) + E[v_1]'E[v_2]
# E[c_1'c_2] + E[μ_1'μ_2] = Tr(Cov(v_1, v_2)) + E[v_1]'E[v_2]
# E[c_1'c_2] = E[(v_1-μ_1)'(v_2-μ_2)] = Tr(Cov(v_1, v_2))
# E[μ_1'μ_2] = E[v_1]'E[v_2]


# variance(x) = E(v^2) - E(v)^2

# use mean and centered component

# E[X'Y] = E[X]'E[Y] + Tr(Cov(X, Y))

    
@alg begin
    X, Y ∈ RandomR

    begin test1
        # E(x) == 2
        # E(y) <= 3
        # E(y) >= 0
        max(E(x + y)) # 5
        min(E(x + y)) # 2
    end 

    begin test 2
        # https://www.probabilitycourse.com/chapter6/6_2_4_cauchy_schwarz.php
        # |E[XY]| <= sqrt(E[X^2]E[Y^2])
        # |E<X, Y>| <= sqrt(E<X, X>E<Y, Y>)
        # |Cov(X, Y)| <= sqrt(Cov(X, X) * Cov(Y, Y))
        # |E<c_X, c_Y>| <= sqrt(E<c_X, c_X> * E<c_Y, c_Y>)


        var(X) == 1
        var(Y) == 4

        # var(X + Y) = Var(X) + 2Cov(X, Y) + Var(Y)
        # var(X + Y) = 1 + 2Cov(X, Y) + 4
        # implicit constraint on all covariances 
        # |E<c_X, c_Y>| <= sqrt(E<c_X, c_X> * E<c_Y, c_Y>)

        # ask for min(Var(X + Y))
        # ask for max(Var(X + Y))
        # ask for min(Cov(X, Y))
        # ask for max(Cov(X, Y))
    end
end
```