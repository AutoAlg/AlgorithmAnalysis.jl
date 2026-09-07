# Feasibility

## Tests
### Feasibility
```julia
@alg let
    x ∈ R
    A = [-2 x; x -2]

    local all_pass::Bool = true;

    all_pass &= with_numerics() do
        evaluate(feasible((x ≥ 1) ∧ (x ≤ 2)))
    end

    !all_pass && return all_pass;

    all_pass &= with_numerics() do
        !evaluate(feasible((x ≥ 1) ∧ (x ≤ -1)))
    end

    !all_pass && return all_pass;

    all_pass &= with_numerics() do
        !evaluate(feasible(A ⪰ 0))
    end

    return all_pass;
end
``` 
