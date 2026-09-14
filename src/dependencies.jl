export dependencies

dependencies(scale::Scale)::Vector{ExpressionID} = [scale.scaled]
dependencies(sum::Sum)::Vector{ExpressionID} = sum.expressions
dependencies(p::Product)::Vector{ExpressionID} = [p.left, p.right]

dependencies(cvv::ConcretelyValuedVariable)::Vector{ExpressionID} = []
dependencies(oe::OracleEvaluation)::Vector{ExpressionID} = [oe.oracle_id, oe.input_id]
dependencies(t::Transpose)::Vector{ExpressionID} = [t.transposed_id]
dependencies(ip::InnerProduct)::Vector{ExpressionID} = [ip.left, ip.right]

dependencies(f::SSCFunction)::Vector{ExpressionID} = []
dependencies(gf::SSCGradient)::Vector{ExpressionID} = [gf.function_of]

