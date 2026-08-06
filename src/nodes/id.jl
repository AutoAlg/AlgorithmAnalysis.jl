abstract type ID end

has_id(::Any) = false
has_id(t::Node) = SymbolicUtils.hasmetadata(t, ID) || hasproperty(t, :name)

function id(t::Node)
    if SymbolicUtils.hasmetadata(t, ID)
        return SymbolicUtils.getmetadata(t, ID)
    elseif hasproperty(t, :name)
        return t.name
    else
        return nothing
    end
end

set_id(t::Node, sym::Symbol) = SymbolicUtils.setmetadata(t, ID, sym)
set_id(::Any, ::Symbol) = nothing
