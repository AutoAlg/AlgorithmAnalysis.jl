export with_parameters, with_additional_parameters

const PARAMETERS = Base.ScopedValues.ScopedValue{Dict}(Dict())

get_parameters() = PARAMETERS[]

is_parameter(x::Node) = x ∈ keys(get_parameters())

function get_parameter(x::Node)
    if is_parameter(x)
        return get_parameters()[x]
    end
end

"""
    hasvalue(node)

Check if a node has a numeric value, either as a constant, as a parameter, or in a JuMP model with values. Use [`value`](@ref) to get the value of the node.
"""
function hasvalue(x::Node)
    return is_constant(x) || is_parameter(x) || (in_model(x) && JuMP.has_values(model()))
end


"""
    value(node)

Get the numeric value of a node if available. Throws an error if no value is available. Use [`hasvalue`](@ref) to check if the node has a value.
"""
function value(x::Node)
    if is_constant(x)
        return arguments(x)[1]
    elseif is_parameter(x)
        return get_parameters()[x]
    elseif in_model(x) && JuMP.has_values(model())
        return get_from_model(x)
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
