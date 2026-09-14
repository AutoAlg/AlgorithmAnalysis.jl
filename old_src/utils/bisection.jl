"""
    bsmin(f, a, b; tol, verbose)

Binary search. Returns the smallest value between `a` and `b` (within `tol`) such that `f(x)` is true.

## Assumptions
- `f(a)` is false
- `f(b)` is true
- `f` is monotone (only one cross-over point)
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
