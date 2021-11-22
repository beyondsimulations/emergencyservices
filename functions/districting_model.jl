# Districting optimisation model
function districting_model(optcr::Float64,
                            reslim::Int64,
                            cores::Int64,
                            nodlim::Int64,
                            iterlim::Int64,
                            hex::Int64,
                            potential_locations::Vector{Bool},
                            max_drive::Float64,
                            drivingtime::Array{Float64,2},
                            workload::Array{Float64,2},
                            adjacent::Array{Bool,2},
                            compactness::String,
                            N::Array{Bool,3},
                            M::Array{Bool,3}, 
                            card_n::Array{Int64,2},
                            card_m::Array{Int64,2},
                            nearby_radius::Float64,
                            nearby_districts::Int64,
                            current_locations::Vector{Bool},
                            fixed_locations::Int64)
# Initialise the GAMS model instance
    districting = Model(GAMS.Optimizer)
    set_optimizer_attribute(districting, GAMS.ModelType(), "MIP")
    set_optimizer_attribute(districting, "Solver", "CPLEX")
    set_optimizer_attribute(districting, "OptCR",   optcr)
    set_optimizer_attribute(districting, "ResLim",  reslim)
    set_optimizer_attribute(districting, "Threads", cores)
    set_optimizer_attribute(districting, "NodLim",  nodlim)
    set_optimizer_attribute(districting, "Iterlim", iterlim)

## Initialise the decision variables Y and W
    @variable(districting, Y[1:hex], Bin)
    @variable(districting, W[1:hex,1:hex], Bin)

## Close locations that are not on the list of potential locations
    for i = 1:hex
        set_upper_bound(Y[i], potential_locations[i])
    end

## Fix allocations beyond the specified maximum driving distance
    for i = 1:hex
        for j = 1:hex
            if drivingtime[i,j] > max_drive
                fix.(W[i,j], 0, force=true)
            end
        end
    end

## Define the objective function                
    @objective(districting, Min,
                    sum(workload[i,j] * W[i,j] for i = 1:hex, j = 1:hex if drivingtime[i,j] <= max_drive && potential_locations[i] == 1))

## Define the p-median constraints
    @constraint(districting, allocate_one[j = 1:hex],
                    sum(W[i,j] for i = 1:hex if potential_locations[i] == 1) == 1)
    @constraint(districting, district_count,
                    sum(W[i,i] for i = 1:hex if potential_locations[i] == 1) <= number_districts)
    @constraint(districting, cut_nocenter[i = 1:hex, j = 1:hex; drivingtime[i,j] <= max_drive && potential_locations[i] == 1],
                    W[i,j] - W[i,i] <= 0)
    @constraint(districting, fix_above_drive[i = 1:hex, j = 1:hex; drivingtime[i,j] > max_drive || potential_locations[i] == 0],
                    W[i,j] == 0)

## Define the additional constraints regarding nearby district centers and fixed locations
    @constraint(districting, nearby_secure[i = 1:hex],
                    sum(W[k,k] for k = 1:hex if drivingtime[i,k] <= nearby_radius && i !=k) >= nearby_districts * W[i,i])
    @constraint(districting, partially_fixed,
                    sum(W[i,i] for i = 1:hex if current_locations[i] == 1) >= fixed_locations)

## Define the contiguity and compactness constraints
    if compactness == "C0"
        print("\n Compactness: C0")
    end
    if compactness == "C1"
        print("\n Compactness: C1")
        @constraint(districting, C1[i = 1:hex, j = 1:hex; drivingtime[i,j] <= max_drive && adjacent[i,j] == 0 && i != j],
                    W[i,j] <= sum(W[i,v] for v = 1:hex if N[i,j,v] == 1))
    end
    if compactness == "C2"
        print("\n Compactness: C2")
        @constraint(districting, C2a[i = 1:hex, j = 1:hex; card_n[i,j] <= 1 && drivingtime[i,j] <= max_drive && adjacent[i,j] == 0 && i != j],
                    W[i,j] <= sum(W[i,v] for v = 1:hex if N[i,j,v] == 1))
        @constraint(districting, C2b[i = 1:hex, j = 1:hex; card_n[i,j] > 1 && drivingtime[i,j] <= max_drive && adjacent[i,j] == 0 && i != j],
                    2*W[i,j] <= sum(W[i,v] for v = 1:hex if N[i,j,v] == 1))
    end
    if compactness == "C3"
        print("\n Compactness: C3")
        @constraint(districting, C3a[i = 1:hex, j = 1:hex; card_n[i,j] <= 1 && drivingtime[i,j] <= max_drive && adjacent[i,j] == 0 && i != j],
                    W[i,j] <= sum(W[i,v] for v = 1:hex if N[i,j,v] == 1))
        @constraint(districting, C3b[i = 1:hex, j = 1:hex; card_n[i,j] > 1 && card_m[i,j] < 5 && drivingtime[i,j] <= max_drive && adjacent[i,j] == 0 && i != j],
                    2*W[i,j] <= sum(W[i,v] for v = 1:hex if N[i,j,v] == 1))
        @constraint(districting, C3c[i = 1:hex, j = 1:hex; card_m[i,j] == 5 && drivingtime[i,j] <= max_drive && adjacent[i,j] == 0 && i != j],
                    3*W[i,j] <= sum(W[i,v] for v = 1:hex if M[i,j,v] == 1))
    end
    print("\n JuMP model sucessfully build. Starting optimisation.")

## Start the optimisation
    JuMP.optimize!(districting)

## Save the gap and the objective value
    gap = abs(objective_bound(districting)-objective_value(districting))/abs(objective_value(districting)+0.00000000001)
    objval = objective_value(districting)

## Create a DataFrame for the export
    result = Array{Float64,2}(undef,hex,2) .= 0
    result = DataFrame(result,[:index, :location])
    for i = 1:hex
        result[i,:index] = i
        for j = 1:hex
            if value.(W[i,j]) != 0
                result[j, :location] = i
            end
        end
    end
    return  result::DataFrame, 
            gap::Float64, 
            objval::Float64
end