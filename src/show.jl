show(io::IO, x::TreeWrapper) = print(io, x.name)

children(x::TreeWrapper) = x.children

function children(x::Object)
    t = ()
    for trait ∈ traits(space(x))
        for sym ∈ fieldnames(typeof(trait))
            op = getfield(trait, sym)
            if op isa Object{<:Map}
                if x ∈ outputs(op)
                    ys = inverse(op, x)
                    if ys isa Object{<:Product}
                        ys = as_tuple(ys)
                    else
                        ys = (ys,)
                    end
                    t = (t..., TreeWrapper(label(op), ys))
                end
            end
        end
    end
    return t
    # (TreeWrapper(string(S), Tuple(props)), )
end

tree(S::Type{<:Space}; maxdepth=10) = print_tree(S, maxdepth=maxdepth)
tree(x::Term; maxdepth=10) = print_tree(x; maxdepth=maxdepth)
tree(io::IO, x::Object; maxdepth=10) = print_tree(io, x; maxdepth=maxdepth)
