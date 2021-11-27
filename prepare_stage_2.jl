### simulation: DataFrame with all additional incident information created during the simulation
    sim_data = DataFrame(incidentid                 = Int[], 
                         location_responsible       = Int[],
                         location_dispatched_first  = Union{Missing, Int}[],
                         incident_minute            = Int[],
                         dispatch_minute_first      = Union{Missing, Int}[],
                         dispatch_minute_all        = Union{Missing, Int}[], 
                         arrival_minute_first       = Union{Missing, Int}[],
                         arrival_minute_all         = Union{Missing, Int}[],
                         cars_dispatched            = Union{Missing, Int}[],
                         cars_missing               = Union{Missing, Int}[],
                         cars_location_responsible  = Union{Missing, Int}[])
    for i = 1:nrow(incidents)
        push!(sim_data, (incidentid                 = incidents[i, :incidentid], 
                         location_responsible       = districts[incidents[i, :location], :location],
                         location_dispatched_first  = missing,
                         incident_minute            = floor(incidents[i, :epoch]/60),
                         dispatch_minute_first      = missing,
                         dispatch_minute_all        = missing,
                         arrival_minute_first       = missing,
                         arrival_minute_all         = missing,
                         cars_dispatched            = 0,
                         cars_missing               = incidents[i, :cars],
                         cars_location_responsible  = 0))
    end

### simulation_capacity: define the capacity of each location in each weekhour
    if real_capacity == false
        simulation_capacity = capacity_heuristic(incidents::DataFrame,
                                                 sim_data::DataFrame,
                                                 hourly_capacity::Int64,
                                                 min_capacity::Int64)
    end

### ressource_flow: the ressource flow matrix of the simulation
    ressource_flow = ressource_flow_matrix(sim_data::DataFrame,
                                            incidents::DataFrame,
                                            simulation_capacity::Array{Int64,2})