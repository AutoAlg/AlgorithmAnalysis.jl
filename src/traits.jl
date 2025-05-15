export Structure, NoStructure, IsMagma, structure, Magma, operate

abstract type Structure end

struct NoStructure <: Structure end
struct IsMagma     <: Structure end

structure(::Type) = NoStructure()

struct Magma
    relation::Relation
    labeler::Function
end

structure(::Type{Magma}) = IsMagma()

function operate(S, a, b)
    _operate(structure(typeof(S)), S, a, b)
end

_operate(::IsMagma, S, a, b) = S.op(a, b)

# add_group = MyGroup(+, x -> -x, 0)

# a, b = 2, 3
# println("a + b = ", operate(add_group, a, b))
