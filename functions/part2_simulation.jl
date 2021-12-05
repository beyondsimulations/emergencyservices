# This function includes the whole simulation of the incident data set
function part2_simulation!(districts::DataFrame,
                            incidents::DataFrame,
                            sim_data::DataFrame,
                            ressource_flow::Array{Int64,3},
                            drivingtime::Array{Float64,2},
                            traffic::Array{Float64,2},
                            max_drive::Float64,
                            drop_incident::Int64)
### locations: state the current district ceters
    locations  = Vector{Int64}(vec(sort!(unique(districts[:,:location]))))

### location_dictionary: dictionary to match the locations to columns in the simulation
    location_district    = Dict(locations[i] => i for i = 1:length(locations))

### card_priorities: number of priorities in the incident data set
### card_districts:  number of districts in the district district layout
### card_incidents:  number of incidents in our simulation
    card_priorities  = maximum(incidents[:,:priority])
    card_districts   = length(locations)
    card_incidents   = nrow(incidents)

##  incident_queue: array that saves all incidents not fulfilled happening
##  exchange_queue: array that saves the incidents for exchanges
##  queue_used:     states whether a queue is in use to save unnecessary sorting
##  candidates:     lists all possible candidates and their fit for an exchange
##  cin:            counts the current incident row in our DataFrames
    incident_queue  = Array{Union{Missing,Int},3}(missing,max_queue,card_districts,card_priorities)
    exchange_queue  = Array{Union{Missing,Int64},1}(missing,max_queue*card_districts)
    queue_used      = Array{Int64,2}(undef,card_districts,card_priorities)
    candidates      = Vector{Union{Missing,Float64}}(missing, card_districts)
    cin             = 1

### sim_start:  epoch (in minutes) of the first incident
### sim_length: epoch (in minutes) ends 5 minutes after the incident_minute
###             of the last incidents in our incidents DataFrame
    sim_start   = minimum(sim_data[:,:incident_minute])
    sim_length  = maximum(sim_data[:,:incident_minute]) + 5

### adjust the start of the incidents to write the results and all steps
### directly to the corresponding row of the ressource_flow matrix
    sim_data[:,:incident_minute] .-= sim_start - 1
    
##  Starting simulation
    for mnt = 1:(sim_length - sim_start)
        cin = fill_queues!(sim_data::DataFrame,
                     incidents::DataFrame,
                     location_district::Dict,
                     incident_queue::Array{Union{Missing,Int},3},
                     queue_used::Array{Int64,2},
                     cin::Int64,
                     mnt::Int64,
                     card_incidents::Int64,
                     card_priorities::Int64,
                     card_districts::Int64,
                     max_queue::Int64)
        ## start the allocation of ressources for incidents in the own district
        for p = 1:card_priorities
            own_district = 1
            for k = 1:2
                for i = 1:card_districts
                    for j = 1:max_queue
                        if ismissing(incident_queue[j,i,p]) == false
                            current_incident = incident_queue[j,i,p]
                            ## if district has capacity at district center
                            ## or if cars are working at the backlog at the district center
                            ## and the average car has a backlog below the threshold backlog_max
                            ## and the incident has to have at least one missing car
                            if ressource_flow[mnt,i,1] > 0 || (ressource_flow[mnt,i,5] > 0 &&
                               ressource_flow[mnt,i,6] < backlog_max * sum(ressource_flow[mnt,i,1:5])) &&
                               sim_data[current_incident,:cars_missing] > 0
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
                                                   own_district::Int64)
                            end
                        else
                            break
                        end
                    end
                end
            end
            own_district = 0
            if p <= exchange_prio
                fill_exchange_queue!(sim_data::DataFrame,
                                    incident_queue::Array{Union{Missing,Int64},3},
                                    exchange_queue::Array{Union{Missing,Int64},1},
                                    max_queue::Int64,
                                    card_districts::Int64,
                                    p::Int64)
                fulfill_exchange_queue!(incidents::DataFrame,
                                        sim_data::DataFrame,
                                        location_district::Dict,
                                        ressource_flow::Array{Int64,3},
                                        drivingtime::Array{Float64,2},
                                        exchange_queue::Array{Union{Missing,Int64},1},
                                        candidates::Vector{Union{Missing,Float64}},
                                        locations::Vector{Int64},
                                        exchange_reserve::Vector{Int64},
                                        card_districts::Int64,
                                        mnt::Int64,
                                        own_district::Int64,
                                        max_drive::Float64,
                                        p::Int64)
            end
        end
        prepare_next_minute!(sim_data::DataFrame,
                             incidents::DataFrame,
                             ressource_flow::Array{Int64,3},
                             incident_queue::Array{Union{Missing,Int64},3},
                             mnt::Int64,
                             drop_incident::Int64)
    end
    return incident_queue
end