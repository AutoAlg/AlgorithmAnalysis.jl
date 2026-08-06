function add_constraint(con::Node{<:Prop}, new::Node{<:Prop})
    return con ∧ new
end

function remove_constraint(con::Node{<:Prop}, old::Node{<:Prop})
    isequal(con, old) ? satisfied() : con
end

function remove_constraint(con::Node{Conjunction}, old::Node{<:Prop})
    cons = collect(arguments(con))
    filter!(c -> !isequal(old, c), cons)
    cons = foldl(∧, cons)
end

function replace_constraint(ctx::Node{<:Prop}, old::Node{<:Prop}, new::Node{<:Prop})
    add_constraint(remove_constraint(ctx, old), new)
end

# TODO: these should use similarterm to keep metadata
function add_constraint(opt::Node{T}, con::Node{<:Prop}) where {T<:Optimization}
    Term{T}(operation(opt), [objective(opt), constraint(opt) ∧ con])
end

function add_constraint(opt::Node{T}, con::Node{<:Prop}) where {T<:Feasibility}
    Term{T}(operation(opt), [constraint(opt) ∧ con])
end

function add_constraint(opt::Node{LyapunovCertificate}, new_con::Node{<:Prop})
    con, perf, ρ = constraint(opt), performance(opt), rate(opt)
    op = operation(opt)
    Term{LyapunovCertificate}(op, [con ∧ new_con, perf, ρ])
end

function remove_constraint(opt::Node{LyapunovCertificate}, old_con::Node{<:Prop})
    con, perf, rate = arguments(opt)
    op = operation(opt)
    Term{LyapunovCertificate}(op, [remove_constraint(con, old_con), perf, rate])
end

function remove_constraint(opt::Node{LyapunovCertificate}, old_con::Node{Conjunction})
    for con ∈ arguments(old_con)
        opt = remove_constraint(opt, con)
    end
    return opt
end

function remove_constraint(opt::Node{T}, con::Node{<:Prop}) where {T<:Optimization}
    Term{T}(operation(opt), [objective(opt), remove_constraint(constraint(opt), con)])
end

function remove_constraint(opt::Node{Feasibility}, con::Node{<:Prop})
    Term{Feasibility}(feasible, remove_constraint(constraint(opt), con))
end

function replace_constraint(opt::Node{LyapunovCertificate}, old::Node{<:Prop}, new::Node{<:Prop})
    add_constraint(remove_constraint(opt, old), new)
end

function replace_constraint(opt::Node{<:Optimization}, old::Node{<:Prop}, new::Node{<:Prop})
    add_constraint(remove_constraint(opt, old), new)
end
