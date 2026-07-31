export with_verbose

const VERBOSE = Base.ScopedValues.ScopedValue{Bool}(false)
verbose() = VERBOSE[]

function with_verbose(code::Function, verbose::Bool = true)
    Base.ScopedValues.with(code, VERBOSE => verbose)
end
