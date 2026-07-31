export ID, id, has_id, set_id

abstract type ID end

has_id(::Any) = false
has_id(t::Node) = hasmetadata(t, ID) || hasproperty(t, :name)
id(t::Node) = hasmetadata(t, ID) ? getmetadata(t, ID) : (hasproperty(t, :name) ? t.name : nothing)
set_id(t::Node, sym::Symbol) = setmetadata(t, ID, sym)
set_id(::Any, ::Symbol) = nothing