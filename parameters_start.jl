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
    exchange_backlog = 60::Int64   # maximal minutes in district backlog till exchange is forbidden
    max_queue = 75::Int64          # maximal length of the queue of incidents per district
    real_capacity = false          # state whether a predefined capacity plan should be loaded

# state the main parameters for the capacity estimation if no capacity plan is given
    hourly_capacity = 5::Int64          # average capacity per hour and location over incident timeframe
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
    districts, gap, objval = districting_model(optcr::Float64,
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
    print("\n Average capacity per district: ",
                round(Int64,sum(ressource_flow)/5))

### start the simulation
##  current_incident: it counts the current incident.
    current_incident = 1

##  incident_queue: array that saves the incidents that
##                  could not be fulfilled directly
    incident_queue = Array{Union{Missing,Int},3}(missing,
                            max_queue,
                            size(ressource_flow,2),
                            card_priorities)

##  exchange_queue: array that saves the incidents that
##                  could be fulfilled from other districts
    exchange_queue = Array{Union{Missing,Int},1}(missing,
                            max_queue * size(ressource_flow,2))

## current_status: preallocate array that saves current status         
    current_status =  Array{Int64,2}(undef,size(ressource_flow,2),
                                        card_priorities) .= 1

## timestamps: preallocate array that saves the timestamps
##             of each incident during the simulation
    timestamps = Array{Int64,1}(undef,6) .= 0

##  candidates: the preallocated list of exchange candidates
    candidates =  Array{Union{Missing,Int64},1}(missing,
                            size(ressource_flow,2))

##  Starting simulation
for m = 1:size(ressource_flow,1)
    current_status .= 1
    while cs[n,4] == m && n < size(cs,1)
        if iter[cs[n,2],cs[n,3]] == size(w,1)
            print("qd to short!")
        else
            if ismissing(w[iter[cs[n,2],cs[n,3]],cs[n,2],cs[n,3]])
                w[iter[cs[n,2],cs[n,3]],cs[n,2],cs[n,3]] = cs[n,1]
                n += 1
            else
                iter[cs[n,2],cs[n,3]] += 1
            end
        end
    end
    while cs[n,4] == m && n < size(cs,1)
        if iter[cs[n,2],cs[n,3]] == size(w,1)
            print("qd to short!")
        else
            if ismissing(w[iter[cs[n,2],cs[n,3]],cs[n,2],cs[n,3]])
                w[iter[cs[n,2],cs[n,3]],cs[n,2],cs[n,3]] = cs[n,1]
                n += 1
            else
                iter[cs[n,2],cs[n,3]] += 1
            end
        end
    end
    for p = 1:P
             allocation_own!(iter::Array{Int64,2},
                             w::Array{Union{Missing,Int},3},
                             s::Array{Int64,3},
                             cs::Array{Union{Int,Float64,Missing},2},
                             b_max::Int64,
                             drive::Array{Float64,2},
                             rush_var::Array{Float64,2},
                             rh::Array{Float64,2},
                             t::Array{Int64,1},
                             m::Int64,
                             p::Int64,
                             wh::Int64)
        fill_exchange_queue!(w::Array{Union{Missing,Int},3},
                             w_aus::Array{Union{Missing,Int},1},
                             cs::Array{Union{Int,Float64,Missing},2},
                             m::Int64,
                             p::Int64,
                             ex_del::Array{Int64,1},
                             ex_max::Float64)
        allocation_exchange!(w_aus::Array{Union{Missing,Int},1},
                             iter::Array{Int64,2},
                             drive::Array{Float64,2},
                             distance_max::Int64,
                             s::Array{Int64,3},
                             ex_res::Array{Int64,1},
                             p::Int64,
                             kand::Array{Union{Missing,Float64},1},
                             m::Int64,
                             cs::Array{Union{Int,Float64,Missing},2},
                             rush_var::Array{Float64,2},
                             rh::Array{Float64,2},
                             t::Array{Int64,1},
                             wh::Int64,
                             exchange_prio::Int64)
    end
    backlog_management!(s,m)
    clear_queue!(w,m,cs)
    timestep!(s,m,M)
end

### end stage 2
end 

