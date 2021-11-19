# load all necessary packages
    include("load_packages.jl")

# state the name of the problem instance that should be solved
    problem = "510"

# state the number of districts that should be opened
    number_districts = 3

# maximum driving distance in minutes to each district border
    max_drive = 45

# state the weight of each priority for the driving time
## important: the weight has to equal the number of priorities
## in the incident data stage
    prio_weight = [1, 1, 1, 1, 1]

# load the input data
    include("load_input.jl")
    
# prepare the input data for stage 1 of the framework:
## district optimisation
### prepare the adjacency matrix
    adjacent = adjacency_matrix(airdist::Array{Float64,2})

### append the weekhour to the incident dataset
    incidents.weekhour = (dayofweek.(unix2datetime.(incidents.epoch)) .- 1) .* 24 .+ 
                        hour.(unix2datetime.(incidents.epoch)) .+ 1

### prepare the workload for each BA if allocated to a potential center
    workload = workload_calculation(incidents::DataFrame,
                                    prio_weight::Vector{Int64},
                                    hexsize::Int64)

### district optimisation model

