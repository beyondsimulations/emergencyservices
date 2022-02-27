function model_and_optimise(solver::String,  
                            number_locations::Int64,
                            distance::Array{Float64,2},
                            we::Vector{Float64},
                            price::Array{Float64,2},
                            adj::Array{Bool,2},
                            N::Array{Bool,3},
                            M::Array{Bool,3}, 
                            card_n::Array{Int64,2},
                            card_m::Array{Int64,2},
                            max_dist::Float64,
                            compactness::String,
                            pl::Vector{Bool},
                            nearby_radius::Float64,
                            nearby_districts::Int64,
                            current_locations::Vector{Bool},
                            fixed_locations::Int64,
                            equal::Bool = false)
    model, X = build_districting(solver, number_locations, distance, we, price, adj, N, M, 
                                    card_n, card_m, max_dist, compactness, nearby_radius,
                                    nearby_districts ,current_locations, fixed_locations, equal, pl)
    X, gap, objval, scnds = optimise_model(model, X, pl, current_locations, fixed_locations, number_locations)
    return X, gap, objval, scnds
end

function create_model(::Val{:gurobi},
                        optgap::Float64 = 0.000,
                        ressourcelimit::Int64 = 3600,
                        nodelimit::Int64 = 1000000000,
                        iterationlimit::Int64 = 1000000000,
                        maxcores::Int64 = 8,
                        silentoptimisation::Bool = false)
    ## Define the Model for Gurobi
    model = Model(() -> Gurobi.Optimizer(GRB_ENV))

    if silentoptimisation == true
        set_silent(model)
    end
    set_optimizer_attribute(model, "MIPGap",          optgap)
    set_optimizer_attribute(model, "TimeLimit",       ressourcelimit)
    set_optimizer_attribute(model, "NodeLimit",       nodelimit)
    set_optimizer_attribute(model, "IterationLimit",  iterationlimit)
    set_optimizer_attribute(model, "Presolve",        0)
    set_optimizer_attribute(model, "Method",          5)
    MOI.set(model, MOI.NumberOfThreads(), maxcores)

    return model
end

function create_model(::Val{:cplex},
                        optgap::Float64 = 0.000,
                        ressourcelimit::Int64 = 3600,
                        nodelimit::Int64 = 1000000000,
                        iterationlimit::Int64 = 1000000000,
                        maxcores::Int64 = 8,
                        silentoptimisation::Bool = false)
    # Define the model for create_cplex
    model = direct_model(CPLEX.Optimizer())

    if silentoptimisation == true
        set_silent(model)
    end
    set_optimizer_attribute(model, "CPX_PARAM_EPGAP",   optgap)
    set_optimizer_attribute(model, "CPX_PARAM_TILIM",   ressourcelimit)
    set_optimizer_attribute(model, "CPX_PARAM_NODELIM", nodelimit)
    set_optimizer_attribute(model, "CPX_PARAM_ITLIM",   iterationlimit)
    MOI.set(model, MOI.NumberOfThreads(), maxcores)

    return model
end

function build_districting(solver::String,
                            number_locations::Int64,
                            distance::Array{Float64,2},
                            weight::Vector{Float64},
                            price::Array{Float64,2},
                            adj::Array{Bool,2},
                            N::Array{Bool,3},
                            M::Array{Bool,3}, 
                            card_n::Array{Int64,2},
                            card_m::Array{Int64,2},
                            max_dist::Float64,
                            cmpc::String,
                            nearby_radius::Float64,
                            nearby_districts::Int64,
                            current_locations::Vector{Bool},
                            fixed_locations::Int64,
                            equal::Bool = true,
                            pl = Vector{Bool,1}(undef,length(weight)) .= true)
## Create local parameters
    BAs = size(distance,1)
    model = create_model(Val(Symbol(solver)), optcr, reslim, nodlim, iterlim, cores, silent)

## Check whether the locations are already fixed in advance
   if fixed_locations == number_locations
        pl = current_locations
   end 

## Initialise the decision variable X
    @variable(model, X[i = 1:BAs, j = 1:BAs ; pl[i] == true && distance[i,j] <= max_dist], Bin)

## Store all available indices from the variable
    XI = Matrix{Bool}(undef,BAs,BAs) .= false
    for key in eachindex(X)
        XI[key[1],key[2]] = true
    end

## Define the objective function                
    @objective(model, Min, sum(price[i,j] * X[i,j] for i = 1:BAs, j = 1:BAs if XI[i,j] == true))

## Define the p-median constraints
    #@constraint(model, allocate_one_a[i = 1:BAs; XI[i,i] == true], X[i,i] + sum(X[j,i] for j = 1:BAs if j != i && XI[j,i] == true) == 1)
    @constraint(model, allocate_one_b[j = 1:BAs], sum(X[i,j] for i = 1:BAs if XI[i,j] == true) == 1)
    @constraint(model, district_count, sum(X[i,i] for i = 1:BAs if XI[i,i] == true) == number_locations)
    @constraint(model, cut_nocenter[i = 1:BAs, j = 1:BAs; XI[i,j] == true], X[i,j] <= X[i,i])

    ## Define the additional constraints regarding nearby district centers and fixed locations
    if nearby_districts > 0
        @constraint(model, nearby_secure[i = 1:BAs; XI[i,i] == true], sum(X[k,k] for k = 1:BAs if distance[i,k] <= nearby_radius && i != k && XI[k,k] == true) >= nearby_districts * X[i,i])
    end

    if fixed_locations > 0
        @constraint(model, partially_fixed, sum(X[i,i] for i = 1:BAs if current_locations[i] == 1 &&  XI[i,i] == true) >= fixed_locations)
    end

## Define the contiguity and compactness constraints
    compactness_constraints!(Val(Symbol(cmpc)), cmpc, BAs, max_dist, distance, adj, N,
                                M, card_n, card_m, model, X, XI)

## Define the bounds for the weight of the districts (if wished for)
    if equal == true
        equalise_districts!(model, weight, X, number_locations)
    end

    print("\n JuMP districting model sucessfully build.")
    return model, X
end

function change_bounds(X::JuMP.Containers.SparseAxisArray{VariableRef}, 
                        pl::Vector{Bool},
                        current_locations::Vector{Bool},
                        fixed_locations::Int64, 
                        number_locations::Int64)
    ## Fix the Variables
    for i = 1:length(pl)
        for key in eachindex(X)
            if is_fixed(X[key])
                unfix(X[key])
            end
            if pl[key[1]] == false
                fix(X[key], 0)
            end
        end
    end
    return X
end

function optimise_model(model::Model, 
                        X::JuMP.Containers.SparseAxisArray{VariableRef},
                        pl::Vector{Bool},
                        current_locations::Vector{Bool},
                        fixed_locations::Int64,
                        number_locations::Int64)
## Fix the Variables
    X = change_bounds(X, pl, current_locations, fixed_locations, number_locations)
## Start the optimisation
    scnds = @elapsed JuMP.optimize!(model)

## Check whether a solution was found
    if termination_status(model) == MOI.OPTIMAL
        # print("\n Solution is optimal.")
    elseif termination_status(model) == MOI.TIME_LIMIT && has_values(model)
        print("\n Solution is suboptimal due to a time limit, but a primal solution is available.")
    else
        print("\n The model was not solved correctly.")
    end

## Save the gap and the objective value
    if termination_status(model) == MOI.OPTIMAL || termination_status(model) == MOI.TIME_LIMIT && has_values(model)
        gap = abs(objective_bound(model)-objective_value(model))/abs(objective_value(model)+0.00000000001)
        objval = objective_value(model)
    else
        gap = 100.0
        objval = 0.0
        X = nothing
    end
    
    return  X,
            gap, 
            objval,
            scnds
end

function create_frame(X::JuMP.Containers.SparseAxisArray{VariableRef}, BAs::Int64)
    ## Create a DataFrame for the export
    result = Array{Float64,2}(undef,BAs,2) .= 0
    result = DataFrame(result,[:index, :location])
    for i = 1:BAs
        result[i,:index] = i
    end
    for key in eachindex(X)
        if value(X[key]) != 0
            result[key[2], :location] = key[1] 
        end
    end
    return result::DataFrame
end

function compactness_constraints!(::Val{:C0}, 
                                  cmpc::String,
                                  BAs::Int64,
                                  max_dist::Float64,
                                  distance::Array{Float64,2},
                                  adj::Array{Bool,2},
                                  N::Array{Bool,3},
                                  M::Array{Bool,3}, 
                                  card_n::Array{Int64,2},
                                  card_m::Array{Int64,2},
                                  model::Model,
                                  X::JuMP.Containers.SparseAxisArray{VariableRef},
                                  XI::Matrix{Bool})
    print("\n Level of compactness constraints: C0")
end

function compactness_constraints!(::Val{:C1}, 
                                  cmpc::String,
                                  BAs::Int64,
                                  max_dist::Float64,
                                  distance::Array{Float64,2},
                                  adj::Array{Bool,2},
                                  N::Array{Bool,3},
                                  M::Array{Bool,3}, 
                                  card_n::Array{Int64,2},
                                  card_m::Array{Int64,2},
                                  model::Model,
                                  X::JuMP.Containers.SparseAxisArray{VariableRef},
                                  XI::Matrix{Bool})
    print("\n Level of compactness constraints: ", cmpc)
    @constraint(model, C1[i = 1:BAs, j = 1:BAs; XI[i,j] == true && adj[i,j] == 0 && i != j],
                X[i,j] <= sum(X[i,v] for v = 1:BAs if N[i,j,v] == 1 && XI[i,v] == true))
end

function compactness_constraints!(::Val{:C2}, 
                                  cmpc::String,
                                  BAs::Int64,
                                  max_dist::Float64,
                                  distance::Array{Float64,2},
                                  adj::Array{Bool,2},
                                  N::Array{Bool,3},
                                  M::Array{Bool,3}, 
                                  card_n::Array{Int64,2},
                                  card_m::Array{Int64,2},
                                  model::Model,
                                  X::JuMP.Containers.SparseAxisArray{VariableRef},
                                  XI::Matrix{Bool})
    print("\n Level of compactness constraints: ", cmpc)
    @constraint(model, C2a[i = 1:BAs, j = 1:BAs; card_n[i,j] <= 1 && XI[i,j] == true && adj[i,j] == 0 && i != j],
                  X[i,j] <= sum(X[i,v] for v = 1:BAs if N[i,j,v] == 1 && XI[i,v] == true))
    @constraint(model, C2b[i = 1:BAs, j = 1:BAs; card_n[i,j] > 1 && XI[i,j] == true && adj[i,j] == 0 && i != j],
                2*X[i,j] <= sum(X[i,v] for v = 1:BAs if N[i,j,v] == 1 && XI[i,v] == true))
end

function compactness_constraints!(::Val{:C3}, 
                                  cmpc::String,
                                  BAs::Int64,
                                  max_dist::Float64,
                                  distance::Array{Float64,2},
                                  adj::Array{Bool,2},
                                  N::Array{Bool,3},
                                  M::Array{Bool,3}, 
                                  card_n::Array{Int64,2},
                                  card_m::Array{Int64,2},
                                  model::Model,
                                  X::JuMP.Containers.SparseAxisArray{VariableRef},
                                  XI::Matrix{Bool})
    print("\n Level of compactness constraints: ", cmpc)
    @constraint(model, C3a[i = 1:BAs, j = 1:BAs; card_n[i,j] <= 1 && XI[i,j] == true && adj[i,j] == 0 && i != j],
                  X[i,j] <= sum(X[i,v] for v = 1:BAs if N[i,j,v] == 1 && XI[i,v] == true))
    @constraint(model, C3b[i = 1:BAs, j = 1:BAs; card_n[i,j] > 1 && card_m[i,j] < 5 && XI[i,j] == true && adj[i,j] == 0 && i != j],
                2*X[i,j] <= sum(X[i,v] for v = 1:BAs if N[i,j,v] == 1 && XI[i,v] == true))
    @constraint(model, C3c[i = 1:BAs, j = 1:BAs; card_m[i,j] == 5 && XI[i,j] == true && adj[i,j] == 0 && i != j],
                3*X[i,j] <= sum(X[i,v] for v = 1:BAs if M[i,j,v] == 1 && XI[i,v] == true))
end

function equalise_districts!(model::Model, weight::Vector{Float64}, X::JuMP.Containers.SparseAxisArray{VariableRef}, number_locations::Int64, allowed_diff = 0.2)
    total_weight = sum(weight)
    UB = round((total_weight/number_locations)* (1 + allowed_diff))
    LB = round((total_weight/number_locations)* (1 - allowed_diff))                         
    @constraint(model, population_ub[i = 1:length(weight); pl[i] == 1],
                sum(weight[j]*X[i,j] for j = 1:length(weight)) <= UB)
    @constraint(model, population_lb[i = 1:length(weight); pl[i] == 1],
                sum(weight[j]*X[i,j] for j = 1:length(weight)) >= LB*X[i,i])
end

function bench_plot(X::JuMP.Containers.SparseAxisArray{VariableRef}, 
                    BAs::Int64, 
                    dur::Float64, 
                    objval::Float64, 
                    gap::Float64, 
                    hs)
    results = create_frame(X, BAs)
    print("\n Optimisation took ",round(dur,digits = 2)," seconds. ")
    print("\n The objective value is ",round(objval, digits = 2) ,". ")
    print("\n The objective gap is ",round(gap, digits = 6) ,". \n")
    display(plot_generation(results, hs))
end

function bench_plot(X::Nothing, 
                    BAs::Int64, 
                    dur::Float64, 
                    objval::Float64, 
                    gap::Float64, 
                    hs)
    print("\n No solution could be found within the specified timeframe.")
end