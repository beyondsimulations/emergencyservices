import Pkg
Pkg.activate("emergency_services")

# load all necessary packages and functions
    include("load_packages.jl")

# state the parts of the framework that should be executed
# stage 1: only the optimisation will be executed
# stage 2: only the simulation will be executed (requires at least one run of stage 1)
# both:    both stages will be executed
    framework = "both"::String

# state the name of the problem instance that should be solved, possible examples
# are "0510","1008","1508","2010" where the name corresponds to the number of BAs
    problem  = "0510"::String  

# state the main input parameters for the optimisation (framework stage 1)
    number_districts = 6::Int64      # number of districts that should be opened
    max_drive        = 30.0::Float64 # maximum driving distance (minutes) to district border
    nearby_districts = 1::Int64      # minimal number of districts within nearby radius
    nearby_radius    = 15.0::Float64 # maximal driving time to nearby district center
    fixed_locations  = 0::Int64      # number of current locations that should not be moved
    plot_district    = true::Bool    # state whether the resulting district should be plotted

# state the optimisation options
    optcr   = 0.000::Float64         # allowed gap
    reslim  = 10800::Int64           # maximal duration of optimisation in seconds
    cores   = 8::Int64               # number of CPU cores
    nodlim  = 1000000::Int64         # maximal number of nodes
    iterlim = 1000000::Int64         # maximal number of iterations
    silent  = false::Bool             # state whether to surpress the optimisation log

# state the strength of the compactness and contiguity constraints
# C0 = no contiguity constraints (no compactness)
# C1 = solely contiguity constrains (no compactness)
# C2 = contiguity and normal ompactness constraints
# C3 = contiguity and strong compactness constraints
# For more details take a look at the article this program is based on
    compactness = "C2"        
    
# state the weight of each priority for the driving time
# important: the weight has to equal the number of priorities
# in the incident data stage
    prio_weight = [1, 1, 1, 1, 1]

# state the main parameters for the simulation (framework stage 2)
    min_capacity   = 1::Int64      # minimal capacity for each district during each weekhour
    exchange_prio  = 5::Int64      # till which priority can cars be exchanged to foreign districts
    backlog_max    = 30::Int64     # maximal average backlog (minutes) per car in district for exchange
    max_queue      = 50::Int64     # maximal length of the queue of incidents per district and priority
    real_capacity  = false::Bool   # state whether a predefined capacity plan should be loaded
    drop_incident  = 300::Int64    # total number of minutes after which an incident
                                   # will leave the queue even if it's not fully fulfilled

# state the main parameters for the capacity estimation if no capacity plan is given
    total_capacity   = 75::Int64        # average capacity per hour in the area over the incident timeframe
    capacity_service = 0.90::Float64    # alpha service level for weekhour workload estimation

# state how many cars should be reserved for the own district per incident priority
# during exchanges to other districts this threshold will not be crossed 
# important: the exchange_reserve has to equal the number of priorities
    exchange_reserve = [0,0,0,0,0]

# state whether to save the plotted results
    save_plots = true::Bool # save the plots

# load the input data
    include("load_input.jl")
    print("\n Input data sucessfully loaded.")

# prepare the input data for stage 1 (also neccessary for stage 2!)
    include("framework/prepare_stage_1.jl")
    print("\n Input sucessfully prepared for both stages.")


# district optimisation (framework stage 1)
if framework != "stage 2"
    print("\n Starting optimisation.")

# Start the optimisation model
scnds = @elapsed districts, gap, objval = districting_model(optcr::Float64,
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
                                        fixed_locations::Int64,
                                        silent::Bool)
    print("\n Duration of the optimisation: ", scnds, " seconds")

# Plot the resulting district layout
    if plot_district && hexshape !== nothing
        district_plot = plot_generation(districts, hexshape)
        display(district_plot)
        if save_plots == 1
            savefig("graphs/district_layout_$problem.pdf")
        end
    end

# Save the resulting district layout
    CSV.write("results/district_layout_$problem.csv", districts)
    print("\n Results from stage 1 written to file.")

# End stage 1 of the framework
end

# emergency service simulation (framework stage 2)
if framework != "stage 1"

# prepare the input data for the simulation
# load the district layout in case solely stage 2 is executed
    if framework == "stage 2"
        print("\n Only stage 2 will be executed.")
        districts = CSV.read("results/district_layout_$problem.csv", DataFrame)
        districts[!,:index] = convert.(Int64,districts[!,:index])
        districts[!,:location] = convert.(Int64,districts[!,:location])
        print("\n Districts loaded from file.")
    end

# prepare the input data for stage 2
    include("framework/prepare_stage_2.jl")
    print("\n Input sucessfully prepared for simulation.")
    print("\n Ressource matrix build.")

# start the simulation
    scnds = @elapsed part2_simulation!(districts::DataFrame,
                      incidents::DataFrame,
                      sim_data::DataFrame,
                      ressource_flow::Array{Int64,3},
                      drivingtime::Array{Float64,2},
                      traffic::Array{Float64,2},
                      max_drive::Float64,
                      drop_incident)
    print("\n Simulation completed.")
    print("\n Duration of the simulation: ", scnds, " seconds")
    print("\n Average ressources allocated to districts during simulation: ",
    round(Int64,sum(ressource_flow[1:size(ressource_flow,1)-1000,:,1:5]
                                    /(size(ressource_flow,1)-1000))))

# plot the results
    include("framework/prepare_results.jl")
    print("\n Framework completed.")
    print("\n Main results:")
    print("\n Average dispatch time:           ", 
            overall_missing[1,:dispatch_time_first])
    print("\n Average response time:           ", 
            overall_missing[1,:response_time_first])
    print("\n Average exchange ratio:          ", 
            overall_missing[1,:exchange_ratio])
    print("\n Average ratio undispatched cars: ", 
            overall_missing[1,:ratio_cars_undispatched])
    print("\n Unfullfilled calls for service:  ", 
            overall_missing[1,:incidents_unfulfilled])
    CSV.write("results/summary_$problem.csv", overall_missing)
    print("\n Results from stage 2 written to file.")
    print("\n")
end 

