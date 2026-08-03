export @alg, @var, @def

# ------------------------------------------------------
# MACROS
# ------------------------------------------------------

macro var(ex)

    _var(x) = error("Invalid expression for @var macro: $x")
    _var(x::LineNumberNode) = x

    function _var(x::Expr)
        if x.head == :call && length(x.args) == 3 && (x.args[1] == :(∈) || x.args[1] == :in)
            var = x.args[2]
            T = x.args[3]
            sym = QuoteNode(x.args[2])
            quote
                $lhs = AlgorithmAnalysis.leaf($T, $sym); nothing
            end
        elseif x.head == :block || x.head == :tuple
            Expr(:block, map(_var, x.args)...)
        else
            error("Invalid expression for @var macro: $x")
        end
    end
    
    return esc(quote
        $(_var(ex)); nothing
    end)
end

macro def(ex)

    _def(x) = error("Invalid expression for @def macro: $x")
    _def(x::LineNumberNode) = x

    function _def(x::Expr)
        if x.head == :(=)
            lhs = x.args[1]
            rhs = x.args[2]
            sym = QuoteNode(x.args[1])
            quote
                $lhs = $rhs
                $lhs = AlgorithmAnalysis.set_id($lhs, $sym)
                nothing
            end
        elseif x.head == :block || x.head == :tuple
            Expr(:block, map(_def, x.args)...)
        else
            error("Invalid expression for @def macro: $x")
        end
    end
    
    return esc(quote
        $(_def(ex)); nothing
    end)
end

"""
    @alg ex

Domain-specific language (DSL) for algorithmic computation. Constructs and initializes symbolic variables, expression terms, and state transitions.

# Syntax Rules

1. Leaf variables (`∈` or `in`)
   Declare symbolic leaf variables belonging to a specific set or space:
   - Single variable: `x ∈ R` or `x in R`
   - Tuple syntax: `x, y ∈ R`

2. Standard Symbolic Assignments (`=`)
   Assign a symbolic expression to a variable:
   - `z = 2x - 3y`

3. Transition Declarations (`→`)
   Define state transitions between two variables:
   - `t = x → x₊`

All expressions are labeled with the symbol used to represent the quantity in the code. Also, all code constructed by the macro returns `nothing` to suppress verbose output. The macro is often used with `begin..end` or `let...end` blocks to specify multiple lines of statements that are evaluated sequentially.

# Example

    @alg let
        # Declarations
        a, b ∈ R, u, v ∈ Rⁿ

        # Assignment
        z = a*u + b*v

        # Transition
        step = u → 3u
    end
"""
macro alg(ex)

    function _make_var(_var, _T)
        var = esc(_var)
        T = esc(_T)
        sym = QuoteNode(_var)
        return quote
            $var = AlgorithmAnalysis.leaf($T, $sym); nothing
        end
    end

    function _recurse(x)
        if x isa LineNumberNode
            return x
        
        elseif x isa Expr && x.head == :block
            return Expr(:block, map(_recurse, x.args)...)
            
        elseif x isa Expr && x.head == :let
            bindings = x.args[1]
            body = x.args[2]
            
            return Expr(:let, _recurse(bindings), _recurse(body))

        # Handle the operator precedence: x, y ∈ R
        elseif x isa Expr && x.head == :tuple
            expanded_exprs = []
            current_set = nothing
            
            for item in reverse(x.args)
                if item isa Expr && item.head == :call && (item.args[1] == :(∈) || item.args[1] == :in)
                    var = item.args[2]
                    current_set = item.args[3]
                    push!(expanded_exprs, _make_var(var, current_set))
                elseif (item isa Symbol || (item isa Expr && item.head == :escape)) && current_set !== nothing
                    push!(expanded_exprs, _make_var(item, current_set))
                else
                    current_set = nothing
                    push!(expanded_exprs, _recurse(item))
                end
            end
            return Expr(:block, reverse(expanded_exprs)...)
        end

        # Standard explicit single variable declaration: x ∈ R
        if x isa Expr && x.head == :call && (x.args[1] == :(∈) || x.args[1] == :in)
            lhs = x.args[2]
            set = x.args[3]
            if lhs isa Expr && lhs.head == :tuple
                return Expr(:block, [_make_var(v, set) for v in lhs.args]...)
            else
                return _make_var(lhs, set)
            end

        # Match definitions: b = expr
        elseif x isa Expr && x.head == :(=)
            lhs = esc(x.args[1])
            rhs = esc(x.args[2])
            sym = QuoteNode(x.args[1])

            raw_rhs = x.args[2]

            if raw_rhs isa Expr && raw_rhs.head == :call &&
                length(raw_rhs.args) == 3 && raw_rhs.args[1] == :(→)

                src = esc(raw_rhs.args[2])
                dst = esc(raw_rhs.args[3])
                
                return quote
                    $lhs = set_id(Term{Transition{symtype($src)}}(→, [$src, $dst]), $sym); nothing
                end
            end

            return quote
                $lhs = set_id(to_symbolic($rhs), $sym); nothing
            end

        # Fallback
        else
            return esc(x)
        end
    end

    quote
        $(_recurse(ex)); nothing
    end
end
