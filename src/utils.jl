########################################################
# UTILS
########################################################

export subscript, superscript

function subscript(i::Integer)
    i<0 ? error("$i is negative") : join('₀'+d for d in reverse(digits(i)))
end

function superscript(i::Integer)
    if i<0
        error("$i is negative")
    end
    join(
        if d == 1
            '\u00B9'
        elseif d == 2
            '\u00B2'
        elseif d == 3
            '\u00B3'
        else
            '⁰'+d
        end
        for d in reverse(digits(i))
    )
end

export sym_linear_index

function sym_linear_index(i, j, n)
    @assert 1 ≤ i ≤ n "Index $i is out of bounds"
    @assert 1 ≤ j ≤ n "Index $j is out of bounds"
    if i ≤ j
        (i - 1) * n - (i - 2) * (i - 1) ÷ 2 + (j - i + 1)
    else
        sym_linear_index(j, i, n)
    end
end