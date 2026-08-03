export with_parameters, with_additional_parameters
export get_parameters, is_parameter
export hasvalue, value

const PARAMETERS = Base.ScopedValues.ScopedValue{Dict}(Dict())

get_parameters() = PARAMETERS[]

is_parameter(x::Node) = x ∈ keys(get_parameters())

function get_parameter(x::Node)
    if is_parameter(x)
        return get_parameters()[x]
    end
end

hasvalue(x::Node) = is_constant(x) || is_parameter(x)

function value(x::Node)
    if is_constant(x)
        return arguments(x)[1]
    elseif is_parameter(x)
        return get_parameters()[x]
    else
        error("$x has no value")
    end
end

"""
    with_parameters(code, parameters::Dict)

Execute code within a local scope in which the parameters have the given values. This is typically called with the following syntax:

    with_parameters(parameters) do
        code
    end
"""
function with_parameters(code::Function, parameters::Dict)
    return Base.ScopedValues.with(code, PARAMETERS => parameters)
end

"""
    with_additional_parameters(code, parameters::Dict)

Execute code within a local scope in which the parameters have the given values. This adds the parameters to those already in scope.

    with_parameters(some_parameters) do
        some_code
        with_additional_parameters(more_parameters) do
            more_code
        end
    end
"""
function with_additional_parameters(code::Function, parameters::Dict)
    return with_parameters(code, merge(parameters, get_parameters()))
end
