# This function includes the whole simulation over the incident data set
function part2_simulation!(districts::DataFrame,
                            incidents::DataFrame,
                            sim_data::DataFrame,
                            ressource_flow::Array{Int64,3},
                            drivingtime::Array{Float64,2},
                            traffic::Array{Float64,2},
                            nearby_radius::Float64,
                            drop_incident::Int64,
                            exchange_reserve::Vector{Int64})
# locations: state the current district ceters
    locations  = Vector{Int64}(vec(sort!(unique(districts[:,:location]))))

# location_dictionary: dictionary to match the locations to columns in the simulation
    location_district    = Dict(locations[i] => i for i = 1:length(locations))

# District BAs grouped by department location
    districts_grouped = groupby(districts, [:location])

# card_priorities: number of priorities in the incident data set
# card_districts:  number of districts in the district district layout
# card_incidents:  number of incidents in our simulation
# list of districts: 
    card_priorities  = maximum(incidents[:,:priority])
    card_districts   = length(locations)
    card_incidents   = nrow(incidents)

#  incident_queue: array that saves all incidents not fulfilled happening
#  exchange_queue: array that saves the incidents for exchanges
#  queue_used:     states the number of cases in a queue
#  queue_change:   states whether a queue has changed to save unnecessary sorting
#  candidates:     lists all possible candidates and their fit for an exchange
#  cin:            counts the current incident row in our DataFrames
    incident_queue  = Array{Union{Missing,Int},3}(missing,max_queue,card_districts,card_priorities)
    exchange_queue  = Array{Union{Missing,Int64},1}(missing,max_queue*card_districts)
    queue_used      = Array{Int64,2}(undef,card_districts,card_priorities) .= 1
    queue_change    = Array{Bool,2}(undef,card_districts,card_priorities) .= false
    candidates      = Vector{Union{Missing,Float64}}(missing, card_districts)
    patrol_location = Matrix{Int64}(undef,max_queue,card_districts) .= 0
    patrol_time     = Vector{Float64}(undef, size(patrol_location,1)) .= 0
    cin             = 1

# sim_start:  epoch (in minutes) of the first incident
# sim_length: epoch (in minutes) ends 5 minutes after the incident_minute
#             of the last incidents in our incidents DataFrame
    sim_start   = minimum(sim_data[:,:incident_minute])
    sim_length  = maximum(sim_data[:,:incident_minute]) + 5

# adjust the start of the incidents to write the results and all steps
# directly to the corresponding row of the ressource_flow matrix
    sim_data[:,:incident_minute] .-= sim_start - 1
    
#  Starting simulation
    for mnt = 1:(sim_length - sim_start)
        # fill the queues with all new incidents of the corresponding minute
        cin = fill_queues!(sim_data::DataFrame,
                     incidents::DataFrame,
                     location_district::Dict,
                     incident_queue::Array{Union{Missing,Int},3},
                     queue_used::Array{Int64,2},
                     queue_change::Array{Bool,2},
                     cin::Int64,
                     mnt::Int64,
                     card_incidents::Int64,
                     card_priorities::Int64,
                     card_districts::Int64,
                     max_queue::Int64)
        # determine the location of all cars currently on patrol
        determine_patrol_location!(patrol_location,ressource_flow,locations,districts_grouped,mnt)

        # start the allocation of ressources to incidents in the own district
        for p = 1:card_priorities
            dispatch = "own_department"
            for k = 1:2
                for i = 1:card_districts
                    for j = 1:max_queue
                        if ismissing(incident_queue[j,i,p]) == false
                            current_incident = incident_queue[j,i,p]
                            # if district has capacity at district center
                            # or if cars are working at the backlog at the district center
                            # and the average car has a backlog below the threshold "backlog_max"
                            # and the incident has at least one missing car
                            if ressource_flow[mnt,i,1] > 0 || (ressource_flow[mnt,i,5] > 0 &&
                               ressource_flow[mnt,i,7] < backlog_max * sum(ressource_flow[mnt,i,1:6])) &&
                               sim_data[current_incident,:cars_missing] > 0
                               fastest_time = 0
                               incident_dispatch!(sim_data::DataFrame,
                                                   incidents::DataFrame,
                                                   ressource_flow::Array{Int64,3},
                                                   drivingtime::Array{Float64,2},
                                                   traffic::Array{Float64,2},
                                                   locations::Vector{Int64},
                                                   current_incident::Int64,
                                                   mnt::Int64,
                                                   i::Int64,
                                                   k::Int64,
                                                   dispatch::String,
                                                   fastest_time::Int64)
                            end
                        else
                            break
                        end
                    end
                end
            end
            # check whether cars on patrol within the own district can serve as backup
            #######
            dispatch = "own_patrol"
            k = 1
            for i = 1:card_districts
                for j = 1:max_queue
                    if ismissing(incident_queue[j,i,p]) == false && ressource_flow[mnt,i,6] > 0
                        current_incident = incident_queue[j,i,p]
                        # if the district has cars currently patroling the own district
                        # and there hasn't been a car dispatched to the incident and the
                        # priority is high enough to warrant a dispatch
                        if ressource_flow[mnt,i,6] > 0 && sim_data[current_incident,:cars_missing] > 0 && incidents[current_incident,:priority] <= patrol_prio
                            fastest_time = determine_patrol_driving_time(i::Int64,
                                                                            incidents::DataFrame,
                                                                            traffic::Array{Float64,2},
                                                                            patrol_location::Matrix{Int64}, 
                                                                            patrol_time::Vector{Float64}, 
                                                                            drivingtime::Array{Float64,2},
                                                                            current_incident::Int64,
                                                                            max_drive::Float64,
                                                                            mnt::Int64)
                            if fastest_time < max_drive
                                incident_dispatch!(sim_data::DataFrame,
                                                    incidents::DataFrame,
                                                    ressource_flow::Array{Int64,3},
                                                    drivingtime::Array{Float64,2},
                                                    traffic::Array{Float64,2},
                                                    locations::Vector{Int64},
                                                    current_incident::Int64,
                                                    mnt::Int64,
                                                    i::Int64,
                                                    k::Int64,
                                                    dispatch::String,
                                                    fastest_time::Int64)
                            end
                        end
                    else
                        break
                    end
                end
            end
            # start the exchange of cars to foreign districts to fulfill all incidents
            # faster if an incident happens is within a predefined perimeter. The
            # exchange queue is fulfilled stepwise starting with the hightes priority
            dispatch = "exchange_department"
            if p <= exchange_prio
                # fill the exchange queue with all unfullfilled incidents
                fill_exchange_queue!(sim_data::DataFrame,
                                    incident_queue::Array{Union{Missing,Int64},3},
                                    exchange_queue::Array{Union{Missing,Int64},1},
                                    max_queue::Int64,
                                    card_districts::Int64,
                                    p::Int64)
                # fullfill all incidents possible within the exchange queue
                fulfill_exchange_queue!(incidents::DataFrame,
                                        sim_data::DataFrame,
                                        ressource_flow::Array{Int64,3},
                                        drivingtime::Array{Float64,2},
                                        exchange_queue::Array{Union{Missing,Int64},1},
                                        candidates::Vector{Union{Missing,Float64}},
                                        locations::Vector{Int64},
                                        exchange_reserve::Vector{Int64},
                                        card_districts::Int64,
                                        mnt::Int64,
                                        dispatch::String,
                                        nearby_radius::Float64,
                                        p::Int64)
            end
        end
        # prepare the queues and the ressource_flow for the nest minute
        prepare_next_minute!(sim_data::DataFrame,
                             incidents::DataFrame,
                             ressource_flow::Array{Int64,3},
                             incident_queue::Array{Union{Missing,Int64},3},
                             queue_used::Array{Int64,2},
                             queue_change::Array{Bool,2},
                             mnt::Int64,
                             drop_incident::Int64)
    end
    return sim_data, ressource_flow
end