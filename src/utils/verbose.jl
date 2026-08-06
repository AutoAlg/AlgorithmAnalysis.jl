export with_verbose

const VERBOSE = Base.ScopedValues.ScopedValue{Bool}(false)
verbose() = VERBOSE[]

"""
    with_verbose(code, verbose = true)

Creates a local scope with a given verbosity.

## Example

    with_verbose() do
        code
    end
"""
function with_verbose(code::Function, verbose::Bool = true)
    Base.ScopedValues.with(code, VERBOSE => verbose)
end
