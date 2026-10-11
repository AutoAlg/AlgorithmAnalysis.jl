export expectation_transformation, is_expectation_transform_applicable

is_expectation_transform_applicable(::Any) = false
function is_expectation_transform_applicable(node::Node{R})::Bool
    if iscall(node)
        if operation(node) == E
            return true
        elseif operation(node) == Var
            return true
        elseif operation(node) == Cov
            return true
        else
            return false
        end
    else
        return false
    end
end

# TODO this needs to be expanded to a type level thing, i.e there is {DeterministicField, RandomField} <: Field
is_deterministic(x::Any) = true
is_deterministic(x::Node) = symtype(x) <: R
are_deterministic(xs::Any...) = all(map(is_deterministic, xs))

is_random(x::Node) = symtype(x) <: RandomR
are_random(xs::Node...) = all(map(is_random, xs))

function expectation_transformation(node::Node{R})
    return rewrite(node, [

        @rule(E(+(~~X)) => sum(map(expr -> E(expr), ~~X))),

        @rule(E(~X - ~Y) => E(~X) - E(~Y)), # TODO: handle subtractions larger than two elements
        @rule(E(-(~X)) => R(-1.0) * E(~X)),

        @rule(E(~X * ~Y) => (E(~X) * E(~Y) + Cov(~X, ~Y)) where are_random(~X, ~Y)),

        @rule(E(~a * ~X) => (~a * E(~X)) where (is_random(~X) && is_deterministic(~a))),
        @rule(E(~X * ~a) => (~a * E(~X)) where (is_random(~X) && is_deterministic(~a))),

        @rule(Var(~X) => Cov(~X, ~X)),

        @rule(Cov(~a * ~X, ~Y) => (~a * Cov(~X, ~Y)) where is_deterministic(~a)),
        @rule(Cov(~X, ~a * ~Y) => (~a * Cov(~X, ~Y)) where is_deterministic(~a)),

        @rule(Cov(-(~X), ~Y) => (R(-1.0) * Cov(~X, ~Y))),
        @rule(Cov(~X, -(~Y)) => (R(-1.0) * Cov(~X, ~Y))),

        @rule(Cov(~X - ~Y, ~Z) => Cov(~X, ~Z) - Cov(~Y, ~Z)), # TODO: handle subtractions larger than two elements
        @rule(Cov(~Z, ~X - ~Y) => Cov(~Z, ~X) - Cov(~Z, ~Y)),

        @rule(Cov(+(~~X), ~Y) => sum(map(x -> Cov(x, ~Y), ~~X))),
        @rule(Cov(~X, +(~~Y)) => sum(map(y -> Cov(~X, y), ~~Y))),
    ])
end