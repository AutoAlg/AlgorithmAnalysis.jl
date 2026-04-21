dependencies(::NewExpression)::Vector{ExpressionID} = error("dependencies must be overloaded")

dependencies(d::LinearDecomposition)::Vector{ExpressionID} = collect(keys(d.terms))
dependencies(::SSCFunction)::Vector{ExpressionID} = Vector{ExpressionID}[]
dependencies(ssc_∇::SSCGradient)::Vector{ExpressionID} = [ssc_∇.function_of]
dependencies(ssc_∇of::SSCGradientOf)::Vector{ExpressionID} = [ssc_∇of.∇_id, ssc_∇of.x_id]
dependencies(transition::StateTransition)::Vector{ExpressionID} = [transition.current_id, transition.next_id]
dependencies(::NewR)::Vector{ExpressionID} = Vector{ExpressionID}[]
dependencies(::NewRⁿ)::Vector{ExpressionID} = Vector{ExpressionID}[]