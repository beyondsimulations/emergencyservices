# function that handles the dispatch of cars
function incident_dispatch!(sim_data::DataFrame,
                            incidents::DataFrame,
                            ressource_flow::Array{Int64,3},
                            drivingtime::Array{Float64,2},
                            traffic::Array{Float64,2},
                            locations::Vector{Int64},
                            current_case::Int64,
                            now::Int64,
                            i::Int64,
                            k::Int64,
                            own_district::Int64)
#  save the incident_location and the locations of the arrival_district_center
    incident_location = incidents[current_case,:location]
    district_center = locations[i]
# calculate the minute the car will arrive at the incident location
    arrival_incident = now .+ dispatch_drivingtime(drivingtime[district_center,incident_location],traffic,now)
# calculate the minute of arrival at the incident and the minute of departure from the incident
    if sim_data[current_case,:cars_dispatched] == 0
        departure_incident      = arrival_incident + incidents[current_case,:length]
        arrival_district_center = departure_incident + dispatch_drivingtime(drivingtime[incident_location,district_center],
                                                                            traffic,departure_incident)
        ressource_flow[arrival_district_center,i,6] += incidents[current_case,:backlog]
    else
        departure_incident = min(arrival_incident + incidents[current_case,:length], 
                                 arrival_incident + incidents[current_case,:length] - 
                                 sim_data[current_case,:dispatch_minute_first] + now)
        arrival_district_center = departure_incident + dispatch_drivingtime(drivingtime[incident_location,district_center],
                                                                            traffic,departure_incident)
                                  
    end
# calculate the number of cars to dispatch
# k = 1: only one car will be dispatched
# k = 2: the number of dispatched cars dependends on the availability
    if k == 1
        if ressource_flow[now,i,1] > 0
            cars_backlog = 0
            cars_free = 1
        else
            cars_free = 0
            cars_backlog = 1
        end
    elseif k == 2
        if ressource_flow[now,i,1] > 0
            cars_free = min(sim_data[current_case,:cars_missing], ressource_flow[now,i,1])
            cars_backlog = 0
        else
            cars_free = 0
            cars_backlog = 1
        end
    end
    # write the calculated capacities into the ressource flow matrix
    ressource_flow[now,i,1]                     -= cars_free
    ressource_flow[now,i,5]                     -= cars_backlog
    ressource_flow[now,i,2]                     += cars_free + cars_backlog
    ressource_flow[arrival_incident,i,2]        -= cars_free + cars_backlog
    ressource_flow[arrival_incident,i,3]        += cars_free + cars_backlog
    ressource_flow[departure_incident,i,3]      -= cars_free + cars_backlog
    ressource_flow[departure_incident,i,4]      += cars_free + cars_backlog
    ressource_flow[arrival_district_center,i,4] -= cars_free + cars_backlog
    ressource_flow[arrival_district_center,i,1] += cars_free + cars_backlog
    # write the resulting times to the sim_data DataFrame
    if sim_data[current_case,:cars_dispatched] == 0
        sim_data[current_case,:location_dispatched_first] = locations[i]
        sim_data[current_case,:dispatch_minute_first]     = now
        sim_data[current_case,:arrival_minute_first]      = arrival_incident
    end
    sim_data[current_case,:arrival_minute_first]    = min(sim_data[current_case,:arrival_minute_first],arrival_incident)
    sim_data[current_case,:cars_dispatched]         += cars_free + cars_backlog
    sim_data[current_case,:cars_missing]            -= cars_free + cars_backlog
    if sim_data[current_case,:cars_missing] == 0
        sim_data[current_case,:dispatch_minute_all] = now
        sim_data[current_case,:arrival_minute_all]  = arrival_incident
    end
    if  own_district == 1
        sim_data[current_case,:cars_location_responsible] += cars_free + cars_backlog
    end
end