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

function with_parameters(code::Function, parameters::Dict)
    return Base.ScopedValues.with(code, PARAMETERS => parameters)
end

function with_additional_parameters(code::Function, parameters::Dict)
    return with_parameters(code, merge(parameters, get_parameters()))
end
