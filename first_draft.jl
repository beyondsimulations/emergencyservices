# load all necessary packages
    include("load_packages.jl")

# state the main input parameters
    problem = "510"         # name of the problem instance that should be solved
    number_districts = 3    # number of districts that should be opened
    max_drive = 30          # maximum driving distance (minutes) to district border
    nearby_districts = 1    # minimal number of districts within nearby radius
    nearby_radius = 10      # maximal driving time to nearby district
    fixed_locations = 0     # number of current locations that should not be moved

# state the strength of the compactness and contiguity constraints
# C0 = no contiguity constraints (no compactness)
# C1 = solely contiguity constrains (no compactness)
# C2 = contiguity and normal ompactness constraints
# C3 = contiguity and strong compactness constraints
# For more details take a look at the article this program is based on
    compactness = "C1"        
    
# state the weight of each priority for the driving time
## important: the weight has to equal the number of priorities
## in the incident data stage
    prio_weight = [1, 1, 1, 1, 1]

# load the input data
    include("load_input.jl")

# prepare the input data
    include("prepare_input.jl")

### district optimisation model

# Location Model
## Initialise the GAMS model instance
    districting = Model(GAMS.Optimizer)
    set_optimizer_attribute(districting, GAMS.ModelType(), "MIP")
    set_optimizer_attribute(districting, "Solver", "CPLEX")
    set_optimizer_attribute(districting, "OptCR",   0.000)
    set_optimizer_attribute(districting, "ResLim",  10800)
    set_optimizer_attribute(districting, "Threads", 4)
    set_optimizer_attribute(districting, "NodLim",  1000000)
    set_optimizer_attribute(districting, "Iterlim", 1000000)

## Initialise the decision variables Y and W
    @variable(districting, Y[1:hexsize], Bin)
    @variable(districting, W[1:hexsize,1:hexsize], Bin)

## Close locations that are not on the list of potential locations
    for i = 1:hexsize
        set_upper_bound(Y[i], potloc[i])
    end

## Fix allocations beyond the specified maximum driving distance
    for i = 1:hexsize
        for j = 1:hexsize
            if drivingtime[i,j] > max_drive
                set_upper_bound(W[i,j], 0)
            end
        end
    end

## Define the objective function                
    @objective(districting, Min,
                    sum(workload[i,j] * W[i,j] for i = 1:hexsize, j = 1:hexsize if drivingtime[i,j] <= max_drive && potloc[i] == 1))

## Define the p-median constraints
    @constraint(districting, allocate_one[j = 1:hexsize],
                    sum(W[i,j] for i = 1:hexsize) == 1)
    @constraint(districting, district_count,
                    sum(Y[i] for i = 1:hexsize) == number_districts)
    @constraint(districting, cut_nocenter[i = 1:hexsize, j = 1:hexsize; drivingtime[i,j] <= max_drive && potloc[i] == 1],
                    W[i,j] <= Y[i])

## Define the additional constraints regarding nearby district centers and fixed locations
    @constraint(districting, nearby_secure[i = 1:hexsize],
                    sum(Y[k] for k = 1:hexsize if drivingtime[i,k] <= nearby_radius && i !=k) >= nearby_districts * Y[i])
    @constraint(districting, partially_fixed,
                    sum(Y[i] for i = 1:hexsize if curdep[i] == 1) >= fixed_locations)

## Define the contiguity and compactness constraints
    if compactness == "C0"
        print("\nCompactness: C0")
    end
    if compactness == "C1"
        print("\nCompactness: C1")
        @constraint(districting, C1[i = 1:hexsize, j = 1:hexsize; adjacent[i,j] == 0 && drivingtime[i,j] <= max_drive],
                    W[i,j] <= sum(W[i,v] for v = 1:hexsize if N[i,j,v] == 1))
    end
    if compactness == "C2"
        print("\nCompactness: C2")
        @constraint(districting, C2a[i = 1:hexsize, j = 1:hexsize; adjacent[i,j] == 0 && card_n <= 1 && drivingtime[i,j] <= max_drive],
                    W[i,j] <= sum(W[i,v] for v = 1:hexsize if N[i,j,v] == 1))
        @constraint(districting, C2b[i = 1:hexsize, j = 1:hexsize; adjacent[i,j] == 0 && card_n > 1 && drivingtime[i,j] <= max_drive],
                    W[i,j] <= sum(W[i,v] for v = 1:hexsize if N[i,j,v] == 1))
    end
    if compactness == "C3"
        print("\nCompactness: C3")
        @constraint(districting, C3a[i = 1:hexsize, j = 1:hexsize; adjacent[i,j] == 0 && card_n <= 1 && drivingtime[i,j] <= max_drive],
                    W[i,j] <= sum(W[i,v] for v = 1:hexsize if N[i,j,v] == 1))
        @constraint(districting, C3b[i = 1:hexsize, j = 1:hexsize; adjacent[i,j] == 0 && card_n > 1 && card_m < 5 && drivingtime[i,j] <= max_drive],
                    W[i,j] <= sum(W[i,v] for v = 1:hexsize if N[i,j,v] == 1))
        @constraint(districting, C3c[i = 1:hexsize, j = 1:hexsize; adjacent[i,j] == 0 && card_m == 5 && drivingtime[i,j] <= max_drive],
                    W[i,j] <= sum(W[i,v] for v = 1:hexsize if N[i,j,v] == 1))
    end

## Start the optimisation
    JuMP.optimize!(districting)

## Save the gap and the objective value
    gap = abs(objective_bound(districting)-objective_value(districting))/abs(objective_value(districting)+0.00000000001)
    objval = objective_value(districting)