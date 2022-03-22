import Pkg
Pkg.activate("emergency_services")

# load all necessary packages and functions
include("functions/start_load_packages.jl")

# state the parts of the framework that should be executed
# stage 1: only the optimisation will be executed
# stage 2: only the simulation will be executed (requires at least one run of stage 1)
# both:    both stages will be executed
    framework   = "both"::String

# state the name of the problem instance that should be solved, possible examples
# are "0510","1008","1508","2040" where the name corresponds to the number of BAs
    problem     = "2040"::String

# state the name of the subproblem that should be solved, for example "one_location",
# "basic", "two_locations", eg.
    subproblem  = "twelve_locations"::String

# state the strength of the compactness and contiguity constraints
# C0 = no contiguity constraints (no compactness)
# C1 = solely contiguity constrains (no compactness)
# C2 = contiguity and normal ompactness constraints
# C3 = contiguity and strong compactness constraints
# For more details take a look at the article this program is based on
    compactness = "C0"::String

# state the number of simulations that should be executed due to the variability of the driving time
    sim_number = 100::Int64

# state the main input parameters for the optimisation (framework stage 1)
    number_districts = 12::Int64       # number of districts that should be opened
    max_drive        = 30.0::Float64  # maximum driving distance (minutes) to district border
    nearby_districts = 2::Int64       # minimal number of districts within nearby radius
    nearby_radius    = 30.0::Float64  # maximal driving time to nearby district center
    fixed_locations  = 0::Int64       # number of current locations that should not be moved
    plot_district    = true::Bool     # state whether the resulting district should be plotted

# state the optimisation options
    solver = "gurobi"
    const GRB_ENV = Gurobi.Env()
    const optcr   = 0.000::Float64         # allowed gap
    const reslim  = 21600::Int64           # maximal duration of optimisation in seconds
    const cores   = 8::Int64               # number of CPU cores
    const nodlim  = 1000000::Int64         # maximal number of nodes
    const iterlim = 100000000::Int64       # maximal number of iterations
    const silent  = false::Bool            # state whether to surpress the optimisation log
    
# state the weight of each priority for the driving time
# important: the weight has to equal the number of priorities
# in the incident data stage
    prio_weight = [1, 1, 1, 1, 1]

# state the main parameters for the simulation (framework stage 2)
    const min_capacity   = 2::Int64        # minimal capacity for each district during each weekhour
    const exchange_prio  = 5::Int64        # till which priority can cars be exchanged to foreign districts
    const patrol_prio    = 5::Int64        # till which priority can patrol cars be dispatched as backup
    const patrol_ratio   = 0.00::Float64   # which proportion of the ressources is assigned to be on patrol
    const patrol_time    = 5.00::Float64   # maximal driving time for a patrol car dispatch as help
    const patrol_area    = 5::Int64        # time spent patrolling per basic area
    const backlog_max    = 60::Int64       # maximal average backlog (minutes) per car in district for exchange
    const max_queue      = 80::Int64       # maximal length of the queue of incidents per district and priority
    const real_capacity  = false::Bool     # state whether a predefined capacity plan should be loaded
    const drop_incident  = 360::Int64      # total number of minutes after which an incident
                                           # will leave the queue even if it's not fully fulfilled

# state the main parameters for the capacity estimation if no capacity plan is given
    const total_capacity   = 50.0::Float64   # average capacity per hour in the area over the incident timeframe
    const capacity_service = 0.90::Float64    # alpha service level for weekhour workload estimation

# state how many cars should be reserved for the own district per incident priority
# during exchanges to other districts this threshold will not be crossed 
# important: the exchange_reserve has to equal the number of priorities
    exchange_reserve = [0,0,0,0,0]

# state whether to save the plotted results
    const save_plots = true::Bool # save the plots

# lock to avoid racing conditions during the simulation
    ren_lock = ReentrantLock()

# load the input data
    include("2_define_data.jl")
    print("\n Input data sucessfully loaded.")

# prepare the input data for stage 1 (also neccessary for stage 2!)
# append the weekhour to the incident dataset
    incidents.weekhour = epoch_weekhour.(incidents.epoch)

# prepare the workload for each BA if allocated to a potential center
    if isfile("data/$problem/workload_$problem.csv")
        workload = readdlm("data/$problem/workload_$problem.csv", Float64)
        we = readdlm("data/$problem/weight_$problem.csv", Float64)[:,1]
        print("\n Workload and weight recovered from saved file.")
    else
        dur = @elapsed workload, we = workload_calculation(incidents::DataFrame,
                                                        prio_weight::Vector{Int64},
                                                        drivingtime::Array{Float64,2},
                                                        traffic::Array{Float64,2},
                                                        size(airdist,1)::Int64)
        workload = round.(workload, digits = 3)
        writedlm("data/$problem/workload_$problem.csv", workload)
        writedlm("data/$problem/weight_$problem.csv", we)
        print("\n Finished workload and weight calculation after ",dur," seconds.")
    end

# prepare the sets for the contiguity and compactness constraints
    dur = @elapsed N, M, card_n, card_m = sets_m_n(airdist::Array{Float64,2}, size(airdist,1)::Int64)
    print("\n Finished set calculation after ", dur," seconds.")
    print("\n Input sucessfully prepared for both stages.")

# state which problem and constraints will be the aim of the framework
    print("\n Framework will be applied to the problem ",subproblem," with the constraint set ", compactness,".")

# district optimisation (framework stage 1)
if framework != "stage 2"
    print("\n Starting optimisation.")

# Create a Dataframe to save the main results
    opt_out = DataFrame(prbl = String[], cmpct = String[], objv = Float64[], gp = Float64[], time = Float64[])

# Start the optimisation model
    X, gap, objval, scnds = model_and_optimise(solver, number_districts, drivingtime, we,
                                                workload, adjacent, N, M, card_n, card_m, max_drive,
                                                compactness, potential_locations, nearby_radius,
                                                nearby_districts, current_locations, fixed_locations)
    districts =  create_frame(X, size(airdist,1))
    print("\n Duration of the optimisation: ", scnds, " seconds")

    # Save the optimisation results and district layouts
    CSV.write("results_stage1/$problem/district_layout_$(problem)_$(subproblem)_$(compactness).csv", districts)
    push!(opt_out, (prbl = problem, cmpct = compactness, objv = objval, gp = gap, time = scnds))
    CSV.write("results_stage1/$problem/optimisation_$(problem)_$(subproblem)_$(compactness).csv", opt_out)
    print("\n Results from stage 1 written to file.")

# Plot the resulting district layout
    if plot_district && hexshape !== nothing
        district_plot = plot_generation(districts, hexshape)
        display(district_plot)
        if save_plots == 1
            savefig("graphs/$problem/district_layout_$(problem)_$(subproblem)_$(compactness).pdf")
        end
    end

# End stage 1 of the framework
end

# emergency service simulation (framework stage 2)
if framework != "stage 1"

# prepare the input data for the simulation
# load the district layout in case solely stage 2 is executed
    if isfile("results_stage1/$problem/district_layout_$(problem)_$(subproblem)_$(compactness).csv")
        districts = CSV.read("results_stage1/$problem/district_layout_$(problem)_$(subproblem)_$(compactness).csv", DataFrame)
        districts[!,:index] = convert.(Int64,districts[!,:index])
        districts[!,:location] = convert.(Int64,districts[!,:location])
        print("\n Districts loaded from file.")
    else
        error("Perform stage 1 first, to determine the district layouts.")
    end

# prepare the input data for stage 2
    sim_data = prepare_simulation_data(incidents, districts)

## simulation_capacity: apply a heuristic to derive the capacity of each location in each weekhour   
    simulation_capacity, capacity_plot = capacity_heuristic(incidents,sim_data,total_capacity,min_capacity)

## ressource_flow: fill the intial ressource flow matrix of the simulation
    ressource_flow = ressource_flow_matrix(sim_data, incidents, simulation_capacity)

    print("\n Input sucessfully prepared for simulation.")
    print("\n Ressource matrix build.","\n")

# pepare the execution of multiple simulation runs
    weekly_location = DataFrame()
    weekly_priority = DataFrame()
    capacity_status = DataFrame()
    main_results    = DataFrame()

# start the simulation
    print("\n Starting ", sim_number," emergency service simulations.")
    Threads.@threads for sim_run = 1:sim_number
        rfw = copy(ressource_flow)
        smd = copy(sim_data)
        scnds = @elapsed smd,rfw = part2_simulation!(districts::DataFrame,
                                                     incidents::DataFrame,
                                                     smd::DataFrame,
                                                     rfw::Array{Int64,3},
                                                     drivingtime::Array{Float64,2},
                                                     traffic::Array{Float64,2},
                                                     max_drive::Float64,
                                                     drop_incident::Int64,
                                                     exchange_reserve::Vector{Int64})
        main_results_local, weekly_location_local, weekly_priority_local, 
        capacity_status_local = evaluate_results(incidents, smd, rfw, simulation_capacity)

    # save the results for later evaluation
        weekly_location_local[:,:simulation_run] .= sim_run
        weekly_priority_local[:,:simulation_run] .= sim_run
        capacity_status_local[:,:simulation_run] .= sim_run
        main_results_local[:,:simulation_run]    .= sim_run

        Threads.lock(ren_lock) do
            append!(weekly_location, weekly_location_local)
            append!(weekly_priority, weekly_priority_local)
            append!(capacity_status, capacity_status_local)
            append!(main_results,    main_results_local)
        end
        print("\n Simulation ",nrow(main_results)," of ", sim_number," completed after ", scnds, " seconds on thread ",Threads.threadid())
    end

    # Aggregate the results of all simulations
    weekly_location = groupby(weekly_location,[:location_responsible, :weekhour])
    weekly_location = combine(weekly_location, [n => mean => n for n in names(weekly_location) if n != "simulation_run"])
    weekly_location = round.(weekly_location, digits = 5)
    weekly_priority = groupby(weekly_priority,[:weekhour,:priority])
    weekly_priority = combine(weekly_priority, [n => mean => n for n in names(weekly_priority) if n != "simulation_run"])
    weekly_priority = round.(weekly_priority, digits = 5)
    capacity_status = groupby(capacity_status,[:weekhour,:variable])
    capacity_status = combine(capacity_status, :value => mean => :value)
    main_results    = combine(main_results, [n => mean => n for n in names(main_results) if n != "simulation_run"])
    main_results    = round.(main_results, digits = 5)
    main_priority   = groupby(weekly_priority, :priority)
    main_priority   = combine(main_priority, [n => mean => n for n in names(main_priority) if n != "weekhour"])
    main_priority   = round.(main_priority, digits = 5)

    print("\n\n Main results of simulation:")
    print("\n Average dispatch time first car:    ", main_results[1,:dispatch_time_first])
    for prio = 1:nrow(main_priority)
        print("\n   Average dispatch time priority ", prio,":   ", main_priority[prio,:dispatch_time_first])
    end
    print("\n Average dispatch time all cars:     ", main_results[1,:dispatch_time_all])
    print("\n Average response time first car:    ", main_results[1,:response_time_first])
    for prio = 1:nrow(main_priority)
        print("\n   Average response time priority ", prio,":   ", main_priority[prio,:response_time_first])
    end
    print("\n Average response time all cars:     ", main_results[1,:response_time_all])
    print("\n Average exchange ratio:             ", main_results[1,:exchange_ratio])
    print("\n Average ratio undispatched cars:    ", main_results[1,:ratio_cars_undispatched])
    print("\n Unfullfilled calls for service:     ", main_results[1,:incidents_unfulfilled])

    # Plot the aggregated results
    plot_simulation_results(weekly_location, weekly_priority, capacity_status, capacity_plot, subproblem, compactness)

    # Save the main results of the simulation
    CSV.write("results_stage2/$problem/simulation_$(problem)_$(subproblem)_$(compactness).csv", main_results)
    print("\n Results from stage 2 written to file. Framework ended.")
    print("\n")
end
print("\n")