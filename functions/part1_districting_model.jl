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
                                    nearby_districts ,current_locations, fixed_locations, equal)
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
    #set_optimizer_attribute(model, "MIPFocus",        1)
    set_optimizer_attribute(model, "Presolve",        0)
    set_optimizer_attribute(model, "Method",          3)
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
                            equal::Bool = true)
## Create local parameters
    BAs = size(distance,1)
    model = create_model(Val(Symbol(solver)), optcr, reslim, nodlim, iterlim, cores, silent)

## Initialise the decision variable X
    @variable(model, X[1:BAs,1:BAs], Bin)

## Fix the variables above the maximal distance
    for i = 1:BAs
        for j = 1:BAs 
            if distance[i,j] > max_dist
                JuMP.fix(X[i,j], 0; force = true)
            end
        end
    end
    
## Define the objective function                
    @objective(model, Min, sum(price[i,j] * X[i,j] for i = 1:BAs, j = 1:BAs if distance[i,j] <= max_dist))

## Define the p-median constraints
    @constraint(model, allocate_one_a[i = 1:BAs], X[i,i] + sum(X[j,i] for j = 1:BAs if j != i) == 1)
    #@constraint(model, allocate_one_b[j = 1:BAs], sum(X[i,j] for i = 1:BAs) == 1)
    @constraint(model, district_count, sum(X[i,i] for i = 1:BAs) == number_locations)
    @constraint(model, cut_nocenter[i = 1:BAs, j = 1:BAs; distance[i,j] <= max_dist], X[i,j] <= X[i,i])

    ## Define the additional constraints regarding nearby district centers and fixed locations
    if nearby_districts > 0
        @constraint(model, nearby_secure[i = 1:BAs], sum(X[k,k] for k = 1:BAs if distance[i,k] <= nearby_radius && i !=k) >= nearby_districts * X[i,i])
    end

    if fixed_locations > 0
        @constraint(model, partially_fixed, sum(X[i,i] for i = 1:BAs if current_locations[i] == 1) >= fixed_locations)
    end

## Define the contiguity and compactness constraints
    compactness_constraints!(Val(Symbol(cmpc)), cmpc, BAs, max_dist, distance, adj, N,
                                M, card_n, card_m, model, X)

## Define the bounds for the weight of the districts (if wished for)
    if equal == true
        equalise_districts!(model, weight, X, number_locations)
    end

    print("\n JuMP districting model sucessfully build.")
    return model, X
end

function change_bounds(X::Matrix{VariableRef}, 
                        pl::Vector{Bool},
                        current_locations::Vector{Bool},
                        fixed_locations::Int64, 
                        number_locations::Int64)
    ## Fix the Variables
    if fixed_locations == current_locations && sum(current_locations) <= number_locations
        for i = 1:length(pl)
            if JuMP.is_fixed(X[i,i])
                JuMP.unfix(X[i,i])
            end
            if current_locations[i] == 0
                JuMP.fix(X[i,i], 0)
            else
                JuMP.fix(X[i,i], 1)
            end
        end
    else
        for i = 1:length(pl)
            if JuMP.is_fixed(X[i,i])
                JuMP.unfix(X[i,i])
            end
            if pl[i] == 0
                JuMP.fix(X[i,i], 0)
            end
        end
    end
    return X
end

function optimise_model(model::Model, 
                        X::Matrix{VariableRef},
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

function create_frame(X::Matrix{VariableRef}, BAs::Int64)
    ## Create a DataFrame for the export
    result = Array{Float64,2}(undef,BAs,2) .= 0
    result = DataFrame(result,[:index, :location])
    for i = 1:BAs
        result[i,:index] = i
        for j = 1:BAs
            if value.(X[i,j]) != 0
                result[j, :location] = i
            end
        end
    end
    return result::DataFrame
end

function create_weight_frame(X::Matrix{VariableRef}, weight::Vector{Float64}, BAs::Int64)
    ## Create a DataFrame for the export
    result = Array{Float64,2}(undef,BAs,2) .= 0
    result = DataFrame(result,[:location, :weight])
    index = 1
    for i = 1:length(weight)
        weight_district = 0
        weight_district = sum(weight[j]*value(X[i,j]) for j = 1:length(weight))
        if  weight_district > 0
        result[index,:location] = i
        result[index,:weight] = weight_district/sum(weight)
        index += 1
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
                                  X::Matrix{VariableRef})
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
                                  X::Matrix{VariableRef})
    print("\n Level of compactness constraints: ", cmpc)
    @constraint(model, C1[i = 1:BAs, j = 1:BAs; distance[i,j] <= max_dist && adj[i,j] == 0 && i != j],
                X[i,j] <= sum(X[i,v] for v = 1:BAs if N[i,j,v] == 1))
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
                                  X::Matrix{VariableRef})
    print("\n Level of compactness constraints: ", cmpc)
    @constraint(model, C2a[i = 1:BAs, j = 1:BAs; card_n[i,j] <= 1 && distance[i,j] <= max_dist && adj[i,j] == 0 && i != j],
                  X[i,j] <= sum(X[i,v] for v = 1:BAs if N[i,j,v] == 1))
    @constraint(model, C2b[i = 1:BAs, j = 1:BAs; card_n[i,j] > 1 && distance[i,j] <= max_dist && adj[i,j] == 0 && i != j],
                2*X[i,j] <= sum(X[i,v] for v = 1:BAs if N[i,j,v] == 1))
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
                                  X::Matrix{VariableRef})
    print("\n Level of compactness constraints: ", cmpc)
    @constraint(model, C3a[i = 1:BAs, j = 1:BAs; card_n[i,j] <= 1 && distance[i,j] <= max_dist && adj[i,j] == 0 && i != j],
                  X[i,j] <= sum(X[i,v] for v = 1:BAs if N[i,j,v] == 1))
    @constraint(model, C3b[i = 1:BAs, j = 1:BAs; card_n[i,j] > 1 && card_m[i,j] < 5 && distance[i,j] <= max_dist && adj[i,j] == 0 && i != j],
                2*X[i,j] <= sum(X[i,v] for v = 1:BAs if N[i,j,v] == 1))
    @constraint(model, C3c[i = 1:BAs, j = 1:BAs; card_m[i,j] == 5 && distance[i,j] <= max_dist && adj[i,j] == 0 && i != j],
                3*X[i,j] <= sum(X[i,v] for v = 1:BAs if M[i,j,v] == 1))
end

function equalise_districts!(model::Model, weight::Vector{Float64}, X::Matrix{VariableRef}, number_locations::Int64, allowed_diff = 0.2)
    total_weight = sum(weight)
    UB = round((total_weight/number_locations)* (1 + allowed_diff))
    LB = round((total_weight/number_locations)* (1 - allowed_diff))                         
    @constraint(model, population_ub[i = 1:length(weight)],
                sum(weight[j]*X[i,j] for j = 1:length(weight)) <= UB)
    @constraint(model, population_lb[i = 1:length(weight)],
                sum(weight[j]*X[i,j] for j = 1:length(weight)) >= LB*X[i,i])
end

function bench_plot(X::Matrix{VariableRef}, 
                    BAs::Int64, 
                    dur::Float64, 
                    objval::Float64, 
                    gap::Float64, 
                    hs)
    results = create_frame(X::Matrix{VariableRef}, BAs::Int64)
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