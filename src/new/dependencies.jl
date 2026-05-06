dependencies(::NewExpression)::Vector{ExpressionID} = error("dependencies must be overloaded")

dependencies(d::LinearDecomposition)::Vector{ExpressionID} = collect(keys(d.terms))
dependencies(::SSCFunction)::Vector{ExpressionID} = Vector{ExpressionID}[]
dependencies(ssc_∇::SSCGradient)::Vector{ExpressionID} = [ssc_∇.function_of]
dependencies(eval::OracleEvaluation)::Vector{ExpressionID} = [eval.input_id, eval.oracle_id]
dependencies(transition::StateTransition)::Vector{ExpressionID} = [transition.current_id, transition.next_id]
dependencies(::NewR)::Vector{ExpressionID} = Vector{ExpressionID}[]
dependencies(::NewRⁿ)::Vector{ExpressionID} = Vector{ExpressionID}[]
dependencies(transpose::NewTranspose)::Vector{ExpressionID} = [transpose.transposed_id]
dependencies(inner_product::NewInnerProduct)::Vector{ExpressionID} = [inner_product.transpose_id, inner_product.variable_id]