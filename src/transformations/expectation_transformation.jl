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

function expectation_transformation(node::Node{R})
    return rewrite(node, [
        @rule(E(+(~~X)) => sum(map(expr -> E(expr), ~~X))),
        @rule(E(~X) => mean_component(~X) where issym(~X)), # isleaf
        @rule(Var(~X) => Cov(~X, ~X)),
        @rule(Cov(+(~~X), ~Y) => sum(map(x -> Cov(x, ~Y), ~~X))),
        @rule(Cov(~X, +(~~Y)) => sum(map(y -> Cov(~X, y), ~~Y))),
    ])
end
