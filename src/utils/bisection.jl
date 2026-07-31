"""
simple binary search
  f: function that evaluates to true or false
  a: lower bound
  b: upper bound
  tol: tolerance
Assumes f(a)==false and f(b)==true and f is monotone (only one cross-over point)
Returns the smallest x in [a,b] (within tol) such that f(x)==true.
"""
function bsmin(f, a::T, b::T; tol=T(1e-5), verbose=false) where T
    a, b = a > b ? (b, a) : (a, b)
    !f(b) && error("Top of bisection interval returns false")
    i = 0
    while (b - a) > tol
        i += 1
        c = (a + b) / T(2)
        f(c) ? (b = c) : (a = c)
        verbose && println("iteration $i: ($a, $b), gap = $(b-a)")
    end
    return b
end
