# load all necessary packages
    include("load_packages.jl")

# state the main input parameters
    problem          = "510"         # name of the problem instance that should be solved
    number_districts = 5::Int64      # number of districts that should be opened
    max_drive        = 25.0::Float64 # maximum driving distance (minutes) to district border
    nearby_districts = 2::Int64      # minimal number of districts within nearby radius
    nearby_radius    = 10.0::Float64 # maximal driving time to nearby district
    fixed_locations  = 0::Int64      # number of current locations that should not be moved
    plot_district    = true          # state whether the resulting district should be plotted

# state the optimisation options
    optcr   = 0.010::Float64         # allowed gap
    reslim  = 10800::Int64           # maximal duration of optmisation in seconds
    cores   = 6::Int64               # number of CPU cores
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

# load the input data
    include("load_input.jl")
    print("\n Input data sucessfully loaded.")

# prepare the input data
    include("prepare_input.jl")
    print("\n Input sucessfully prepared for optimisation.")

# district optimisation (stage 1)
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

# emergency service simulation
## prepare the input data for the simulation

    