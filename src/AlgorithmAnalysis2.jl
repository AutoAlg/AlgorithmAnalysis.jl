module AlgorithmAnalysis2

export hello, test


function hello()
    print("Heello, World!")
end

include("context.jl")
include("variables.jl")
include("ssc.jl")
include("algebra.jl")
include("dependencies.jl")
include("replace_expression_context.jl")
include("context_rewrites.jl")

function test()
    original_context::AlgorithmContext = AlgorithmContext()
    step_size::Float64 = 0.05

    e = with_context(original_context) do
        f, ∇f = SSC(3, 10)
        set_alias!(f, "f")
        set_alias!(∇f, "∇f")

        xs = Rⁿ();
        set_alias!(xs, "xs");
        # TODO: constraints

        
        x0 = Rⁿ()
        set_alias!(x0, "x0")

        x1 = x0 - step_size * ∇f(x0)
        set_alias!(x1, "x1")

        performance = (x1 - xs)^2;
        set_alias!(performance, "performance");

        [performance]
    end

    print(original_context)

    result::RewriteResult = eliminate_unreachable_expressions(map((e) -> e.id, e), original_context)

    print("\n\n\n")

    print(result)




end


end