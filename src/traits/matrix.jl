#########################################################
# MATRIX
#########################################################

export MatrixTrait, Mat

struct MatrixTrait <: Trait
    eltype::Space
    rows::Int
    cols::Int

    function MatrixTrait(S::Space, rows::Int, cols::Int)
        register!(new(S, rows, cols))
    end
end

space(t::MatrixTrait) = t.eltype

show(io::IO, t::MatrixTrait) = print(io, "Matrix($(space(t)), $(t.rows) × $(t.cols))")

Mat(s::Space, rows::Int, cols::Int) = Space(Symbol(label(s), superscript(rows), "ˣ", superscript(cols)), property = MatrixTrait(s, rows, cols))
