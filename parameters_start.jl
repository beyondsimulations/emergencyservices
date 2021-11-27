# load all necessary packages
    include("load_packages.jl")

# state the parts of the framework that should be executed
# stage 1: only the optimisation will be executed
# stage 2: only the simulation will be executed (requires at least one run of stage 1)
# both:    both stages will be executed
    framework = "stage 2"

# state the main input parameters for the optimisation (framework stage 1)
    problem          = "510"         # name of the problem instance that should be solved
    number_districts = 5::Int64      # number of districts that should be opened
    max_drive        = 25.0::Float64 # maximum driving distance (minutes) to district border
    nearby_districts = 2::Int64      # minimal number of districts within nearby radius
    nearby_radius    = 15.0::Float64 # maximal driving time to nearby district center
    fixed_locations  = 0::Int64      # number of current locations that should not be moved
    plot_district    = true          # state whether the resulting district should be plotted

# state the optimisation options
    optcr   = 0.010::Float64         # allowed gap
    reslim  = 10800::Int64           # maximal duration of optmisation in seconds
    cores   = 5::Int64               # number of CPU cores
    nodlim  = 1000000::Int64         # maximal number of nodes
    iterlim = 1000000::Int64         # maximal number of iterations

# state the strength of the compactness and contiguity constraints
# C0 = no contiguity constraints (no compactness)
# C1 = solely contiguity constrains (no compactness)
# C2 = contiguity and normal ompactness constraints
# C3 = contiguity and strong compactness constraints
# For more details take a look at the article this program is based on
    compactness = "C2"        
    
# state the weight of each priority for the driving time
## important: the weight has to equal the number of priorities
## in the incident data stage
    prio_weight = [1, 1, 1, 1, 1]

# state the main parameters for the simulation (framework stage 2)
    min_capacity = 1::Int64        # minimal capacity for each district during each weekhour
    exchange_prio  = 5::Int64      # till which priority can cars be exchanged to foreign districts
    backlog_max = 30::Int64        # maximal average backlog (minutes) per car in district for exchange
    max_queue = 75::Int64          # maximal length of the queue of incidents per district
    real_capacity = false          # state whether a predefined capacity plan should be loaded

# state the main parameters for the capacity estimation if no capacity plan is given
    hourly_capacity = 8::Int64          # average capacity per hour and location over incident timeframe
    capacity_service = 0.90::Float64    # alpha service level for weekhour workload estimation

# state how many cars should be reserved for the own district per incident priority
# during exchanges to other districts this threshold will not be crossed 
# important: the exchange_reserve has to equal the number of priorities
    exchange_reserve = [0,0,0,0,0]

# load the input data
    include("load_input.jl")
    print("\n Input data sucessfully loaded.")

# prepare the input data for stage 1
    include("prepare_stage_1.jl")
    print("\n Input sucessfully prepared for optimisation.")


# district optimisation (framework stage 1)
if framework != "stage 2"
    print("\n Starting optimisation.")

## Start the optimisation model
    print("\n Duration of the optimisation:")
    @time districts, gap, objval = districting_model(optcr::Float64,
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
    print("\n Optimisation finished.")

## Plot the resulting district layout
    if plot_district && hexshape !== nothing
        district_plot = plot_generation(districts, hexshape)
        display(district_plot)
    end

## Save the resulting district layout
    CSV.write("results/district_layout_$problem", districts)
    print("\n Results written to file.")

## End stage 1 of the framework
end

# emergency service simulation (framework stage 2)
if framework != "stage 1"

## prepare the input data for the simulation
### load the district layout in case solely stage 2 is executed
    if framework == "stage 2"
        print("\n Only stage 2 will be executed.")
        districts = CSV.read("results/district_layout_$problem", DataFrame)
        districts[!,:index] = convert.(Int64,districts[!,:index])
        districts[!,:location] = convert.(Int64,districts[!,:location])
        print("\n Districts loaded from file.")
    end

    # prepare the input data for stage 2
    include("prepare_stage_2.jl")
    print("\n Input sucessfully prepared for simulation.")
    print("\n Ressource matrix build.")
    print("\n Average ressources per district: ",
                round(Int64,sum(ressource_flow)/5))

### start the simulation
    print("\n Duration of the simulation:")
    @time part2_simulation!(districts::DataFrame,
                      incidents::DataFrame,
                      sim_data::DataFrame,
                      ressource_flow::Array{Int64,3},
                      drivingtime::Array{Float64,2},
                      traffic::Array{Float64,2},
                      max_drive::Float64)
    print("\n Simulation completed.")

## Evaluate the results of the simulation
    incidents = innerjoin(incidents,sim_data,on=:incidentid)
    incidents[:,:response_time_first]   = incidents[:,:arrival_minute_first]    - incidents[:,:incident_minute]
    incidents[:,:response_time_all]     = incidents[:,:arrival_minute_all]      - incidents[:,:incident_minute]
    incidents[:,:dispatch_time_first]   = incidents[:,:dispatch_minute_first]   - incidents[:,:incident_minute]
    incidents[:,:dispatch_time_all]     = incidents[:,:dispatch_minute_all]     - incidents[:,:incident_minute]
    incidents[:,:driving_time_first]    = incidents[:,:arrival_minute_first]    - incidents[:,:dispatch_minute_first]
    
## Group the results on a weekly basis
    weekly = groupby(dropmissing(incidents), [:location_responsible, :weekhour])
    weekly = combine(weekly,
                        nrow => :total_cases_fulfilled,
                        :cars => mean => :requested_cars,
                        :cars_dispatched => mean => :dispatched_cars,
                        :dispatch_time_first => mean => :dispatch_time_first,
                        :response_time_first => mean => :response_time_first,
                        :driving_time_first => mean => :driving_time_first,
                        :cars_missing => mean => :cars_missing,
                        :cars_location_responsible => mean => :cars_locations_responsible)
    weekly = sort!(weekly, [:weekhour, :location_responsible])
end 

