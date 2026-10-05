export expectation_transformation, is_expectation_transform_applicable

# Rewrites E(X + Y) -> E(X) + E(Y)

# match E(x)
    # if x is a leaf
        # do nothing
    # if x is a term
        # if x.term is E
            # try decompose recursively


is_expectation_transform_applicable(::Any) = false
function is_expectation_transform_applicable(node::Node{R})::Bool
    if iscall(node)
        if operation(node) == E
            subexpr = arguments(node)[1]

            print("found subexpr $(subexpr)\n")
            if iscall(subexpr)
                print("$(subexpr)\n")
                if operation(subexpr) == + 
                    left = arguments(subexpr)[1]
                    right = arguments(subexpr)[2]
                    
                    if iscall(left) && operation(left) == E

                    elseif iscall(right) && operation(right) == E
                    else 
                        return true
                    end

                end
            end
        end
        # if operation(node) == :+
        #     return true
        # end
    end

    return false
end

function expectation_transformation(node::Node{R})
    
    subexpression = arguments(node)[1]
    print("expectation_transformation with $(subexpression)")

    if iscall(subexpression)
        if operation(subexpression) == +
            rewrite(node, [@rule(~X + ~Y => E(~X) + E(~Y))])
        end
    end

end

