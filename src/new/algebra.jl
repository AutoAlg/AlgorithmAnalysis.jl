import Base: +, -, *, =>, adjoint, ^

struct NewZero{S <: AbstractSpace} <: ConcretelyValuedVariable{S}
    id::ExpressionID
end

as_decomposition_dict(concretely_valued_variable::ConcretelyValuedVariable)::Dict{ExpressionID, Float64} = Dict{ExpressionID, Float64}(concretely_valued_variable.id => 1.0)
as_decomposition_dict(linear_decomposition::LinearDecomposition)::Dict{ExpressionID, Float64} = deepcopy(linear_decomposition.terms)
as_decomposition_dict(zero_variable::NewZero)::Dict{ExpressionID, Float64} = Dict{ExpressionID, Float64}()

scale_decomposition_dict(decomposition_dict::Dict{ExpressionID, Float64}, scale_factor::Float64)::Dict{ExpressionID, Float64} = Dict{ExpressionID, Float64}(expression_id => term_coefficient * scale_factor for (expression_id, term_coefficient) in decomposition_dict)

function linearly_merge_decomposition_dictionaries(left_terms::Dict{ExpressionID, Float64}, right_terms::Dict{ExpressionID, Float64})::Dict{ExpressionID, Float64}
    merged_terms::Dict{ExpressionID, Float64} = copy(left_terms)

    for (expression_id, coefficient_value) in right_terms
        new_coefficient::Float64 = get(merged_terms, expression_id, 0.0) + coefficient_value
        if new_coefficient == 0.0
            delete!(merged_terms, expression_id)
        else
            merged_terms[expression_id] = new_coefficient
        end
    end

    maybe_current_context::Union{AlgorithmContext, Nothing} = try_get_algorithm_context()

    if isnothing(maybe_current_context)
        error("all algebraic operations must happen under a context")
    end
    
    for e_id in keys(merged_terms)
        if !is_bound_to(e_id, maybe_current_context)
            error("discovered algebraic operand that is not part of the current context")
        end
    end
    
    return merged_terms
end

function *(scalar_multiplier::Real, concretely_valued_variable::ConcretelyValuedVariable{S})::LinearDecomposition{S} where {S <: AbstractSpace}
    return LinearDecomposition{S}(scale_decomposition_dict(as_decomposition_dict(concretely_valued_variable), Float64(scalar_multiplier)))
end

function *(scalar_multiplier::Real, linear_decomposition::LinearDecomposition{S})::LinearDecomposition{S} where {S <: AbstractSpace}
    scale_factor::Float64 = Float64(scalar_multiplier)
    
    if scale_factor == 1.0
        return linear_decomposition
    end
    
    return LinearDecomposition{S}(scale_decomposition_dict(as_decomposition_dict(linear_decomposition), scale_factor))
end

*(concretely_valued_variable::ConcretelyValuedVariable{S}, scalar_multiplier::Real) where {S <: AbstractSpace} = scalar_multiplier * concretely_valued_variable
*(linear_decomposition::LinearDecomposition{S}, scalar_multiplier::Real) where {S <: AbstractSpace} = scalar_multiplier * linear_decomposition

+(left_variable::ConcretelyValuedVariable{S}, right_variable::ConcretelyValuedVariable{S}) where {S <: AbstractSpace} = LinearDecomposition{S}(linearly_merge_decomposition_dictionaries(as_decomposition_dict(left_variable), as_decomposition_dict(right_variable)))
+(left_variable::ConcretelyValuedVariable{S}, right_decomposition::LinearDecomposition{S}) where {S <: AbstractSpace} = LinearDecomposition{S}(linearly_merge_decomposition_dictionaries(as_decomposition_dict(left_variable), as_decomposition_dict(right_decomposition)))
+(left_decomposition::LinearDecomposition{S}, right_variable::ConcretelyValuedVariable{S}) where {S <: AbstractSpace} = LinearDecomposition{S}(linearly_merge_decomposition_dictionaries(as_decomposition_dict(left_decomposition), as_decomposition_dict(right_variable)))
+(left_decomposition::LinearDecomposition{S}, right_decomposition::LinearDecomposition{S}) where {S <: AbstractSpace} = LinearDecomposition{S}(linearly_merge_decomposition_dictionaries(as_decomposition_dict(left_decomposition), as_decomposition_dict(right_decomposition)))

-(left_variable::ConcretelyValuedVariable{S}, right_variable::ConcretelyValuedVariable{S}) where {S <: AbstractSpace} = LinearDecomposition{S}(linearly_merge_decomposition_dictionaries(as_decomposition_dict(left_variable), scale_decomposition_dict(as_decomposition_dict(right_variable), -1.0)))
-(left_variable::ConcretelyValuedVariable{S}, right_decomposition::LinearDecomposition{S}) where {S <: AbstractSpace} = LinearDecomposition{S}(linearly_merge_decomposition_dictionaries(as_decomposition_dict(left_variable), scale_decomposition_dict(as_decomposition_dict(right_decomposition), -1.0)))
-(left_decomposition::LinearDecomposition{S}, right_variable::ConcretelyValuedVariable{S}) where {S <: AbstractSpace} = LinearDecomposition{S}(linearly_merge_decomposition_dictionaries(as_decomposition_dict(left_decomposition), scale_decomposition_dict(as_decomposition_dict(right_variable), -1.0)))
-(left_decomposition::LinearDecomposition{S}, right_decomposition::LinearDecomposition{S}) where {S <: AbstractSpace} = LinearDecomposition{S}(linearly_merge_decomposition_dictionaries(as_decomposition_dict(left_decomposition), scale_decomposition_dict(as_decomposition_dict(right_decomposition), -1.0)))

adjoint(variable::AbstractVariable{S}) where {S <: AbstractSpace} = NewTranspose(variable)

*(transpose_variable::AbstractVariable{DualSpace{S}}, variable::AbstractVariable{S}) where {S <: AbstractSpace} = NewInnerProduct(transpose_variable, variable)

function ^(variable::AbstractVariable{S}, power::Int)::ConcretelyValuedVariable{RealSpace} where {S <: AbstractSpace}
    if power != 2
        error("non squares are unrepresentable")
    end
    
    return variable'*variable
end