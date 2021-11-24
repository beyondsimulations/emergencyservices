### card_priorities: number of priorities in the incident data set
    card_priorities = maximum(incidents[:,:priority])

### locations: state the current district ceters
    locations = vec(sort!(unique(districts[:,:location])))

### simulation: DataFrame with all additional incident information
###             created during the simulation
    simulation = DataFrame(incidentid                 = Int[], 
                            location_responsible      = Int[],
                            location_dispatched       = Union{Missing, Int}[],
                            incident_minute           = Int[],
                            dispatch_minute_first     = Union{Missing, Int}[],
                            dispatch_minute_all       = Union{Missing, Int}[], 
                            arrival_minute_first      = Union{Missing, Int}[],
                            arrival_minute_all        = Union{Missing, Int}[],
                            cars_missing              = Union{Missing, Int}[],
                            cars_location_responsible = Union{Missing, Int}[])

    for i = 1:nrow(incidents)
        push!(simulation, (incidentid = incidents[i, :incidentid], 
                            location_responsible = districts[incidents[i, :location], :location],
                            location_dispatched = missing,
                            incident_minute = floor(incidents[i, :epoch]/60),
                            dispatch_minute_first = missing,
                            dispatch_minute_all = missing,
                            arrival_minute_first = missing,
                            arrival_minute_all = missing,
                            cars_missing = missing,
                            cars_location_responsible = missing))
    end

### simulation_capacity: define the capacity of each location in each weekhour
    if real_capacity == false
        simulation_capacity = capacity_heuristic(incidents::DataFrame,
                                                    simulation::DataFrame,
                                                    hourly_capacity::Int64,
                                                    min_capacity::Int64)
    end

### current_backlog: vector holding the backlog (paperwork) in minutes
###                  for each district center
    current_backlog = Array{Int64,1}(undef,length(locations)) .= 0

### ressource_flow: the ressource flow matrix of the simulation
    ressource_flow = ressource_flow_matrix(simulation::DataFrame,
                                            incidents::DataFrame,
                                            simulation_capacity::Array{Int64,2})