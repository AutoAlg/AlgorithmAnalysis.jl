cd("C:\\Users\\nlam1\\.julia\\dev\\BlackBoxOptimization.jl\\")
#using Pkg
#Pkg.activate(".")
#using Revise
#using Convex, SCS, LinearAlgebra
#using BlackBoxOptimization

#@innerproductspace X, R

function analysis(currentState, nextState)
    currentVariables, nextVariables = Set(), Set()
    for i in range(1, length(currentState))
        currentVariables = union(currentVariables, keys(selfdecomp(currentState[i]).weights))
        nextVariables = union(nextVariables, keys(selfdecomp(nextState[i]).weights))
    end
    algorithmInputs = collect(union(setdiff(currentVariables, nextVariables), setdiff(nextVariables, currentVariables)))
    
    A = zeros(length(currentState),length(currentState))
    B = zeros(length(currentState), length(algorithmInputs))
    C = zeros(length(algorithmInputs), length(currentState))
    for i in range(1, length(nextState))
        decomp = selfdecomp(nextState[i]).weights
        for j in range(1, length(currentState))
            if currentState[j] in keys(decomp)
                A[i, j] = decomp[currentState[j]]
            end
        end
        for j in range(1, length(algorithmInputs))
            if algorithmInputs[j] in keys(decomp)
                B[i, j] = decomp[algorithmInputs[j]]
            end
        end
    end
    for i in range(1, length(algorithmInputs))
        decomp = selfdecomp(algorithmInputs[i]).weights
        for j in range(1, length(currentState))
            if currentState[j] in keys(decomp)
                C[i, j] = decomp[currentState[j]]
            end
        end
    end 
    return A, B, C, algorithmInputs
end

function createConstraintMatrix(constraint::Constraint, currentState, u)
    #Create matrix M
    dict = weights(selfdecomp(expression((constraint))))
    vals = [currentState; u]
    M = zeros(length(vals), length(vals))
    for i in range(1,length(vals))
        for j in range(1,length(vals))
            M[i,j] = dict[vals[i]'*vals[j]]
        end
    end
    return M
end

function solve(A,B,M,rho)
    # state dimension
    n = size(A,1); #number of states
    m = size(B,2) #number of inputs
    P = cvx.Variable(n,n);#Variable(nn, nn); #P

    numberOfConstraints = length(M)
    l1 = cvx.Variable(numberOfConstraints, 1); #lambda1
    l2 = cvx.Variable(numberOfConstraints, 1); #lamnda2

    Pi1 = zeros(n+m, n+m);
    Pi2 = zeros(n+m, n+m);

    problem = cvx.satisfy();
    for i in range(start = 1, stop = length(M))
        
        Pi1 = Pi1 + l1[i]*M[i];
        Pi2 = Pi2 + l2[i]*M[i];
        
        problem.constraints += (l1[i] >= 0);
        problem.constraints += (l2[i] >= 0);
    end
    #decrease conditions
    problem.constraints += (-[A B]'P*[A B] + rho^2*[LinearAlgebra.I zeros(n,m)]'*P*[LinearAlgebra.I zeros(n,m)] - Pi1) in :SDP;
    problem.constraints += P-Matrix(1LinearAlgebra.I, n, n) in :SDP;

    cvx.solve!(problem, SCS.Optimizer, silent_solver = false);
    return problem.status
end

createConstraintMatrix(cons::Constraints, currentState, u) = [createConstraintMatrix(constraint, currentState, u) for constraint in prune!(cons)]