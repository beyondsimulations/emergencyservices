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
#  create the neccessary variables
    inc::Int64           = incidents[current_case,:location] # incident_location
    dc::Int64            = locations[i]                      # location district center
    arrival_inc::Int64   = 0                # minute of arrival at incident
    departure_inc::Int64 = 0                # minute of departure at incident
    arrival_dc::Int64    = 0                # minute of arrival at district center

# calculate the minute the car will arrive at the incident location
    arrival_inc = now + dispatch_drivingtime(drivingtime[dc,inc],traffic,now)

# calculate the minute of arrival at the incident and the minute of departure from the incident
    if sim_data[current_case,:cars_dispatched] == 0
        departure_inc = arrival_inc + incidents[current_case,:length]
        arrival_dc = departure_inc + dispatch_drivingtime(drivingtime[inc,dc],traffic,departure_inc)
        ressource_flow[arrival_dc,i,6] += incidents[current_case,:backlog]
    else
        departure_inc = min(arrival_inc + incidents[current_case,:length], arrival_inc + 
                        incidents[current_case,:length] - sim_data[current_case,:dispatch_minute_first] + now)
        arrival_dc = departure_inc + dispatch_drivingtime(drivingtime[inc,dc],traffic,departure_inc)                 
    end

# calculate the number of cars to dispatch to the incident
# k = 1: only one car will be dispatched
# k = 2: the number of dispatched cars dependends on the availability
    cars_backlog::Int64 = 0  # number of cars dispatched from location currently working on backlog
    cars_free::Int64    = 0  # number of cars dispatched from location currently free
    if ressource_flow[now,i,1] > 0
        if k == 1
            cars_free = 1
        else
            cars_free = min(sim_data[current_case,:cars_missing], ressource_flow[now,i,1])
        end
        cars_backlog = 0
    else
        cars_free = 0
        cars_backlog = 1
    end

    # assign the calculated capacities into the ressource flow matrix
    ressource_flow[now,i,1]             -= cars_free
    ressource_flow[now,i,5]             -= cars_backlog
    ressource_flow[now,i,2]             += cars_free + cars_backlog
    ressource_flow[arrival_inc,i,2]     -= cars_free + cars_backlog
    ressource_flow[arrival_inc,i,3]     += cars_free + cars_backlog
    ressource_flow[departure_inc,i,3]   -= cars_free + cars_backlog
    ressource_flow[departure_inc,i,4]   += cars_free + cars_backlog
    ressource_flow[arrival_dc,i,4]      -= cars_free + cars_backlog
    ressource_flow[arrival_dc,i,1]      += cars_free + cars_backlog

    # write the resulting times to the sim_data DataFrame
    if sim_data[current_case,:cars_dispatched] == 0
        sim_data[current_case,:location_dispatched_first] = locations[i]
        sim_data[current_case,:dispatch_minute_first]     = now
        sim_data[current_case,:arrival_minute_first]      = arrival_inc
    end
    sim_data[current_case,:arrival_minute_first]    = min(sim_data[current_case,:arrival_minute_first],arrival_inc)
    sim_data[current_case,:cars_dispatched]         += cars_free + cars_backlog
    sim_data[current_case,:cars_missing]            -= cars_free + cars_backlog
    if sim_data[current_case,:cars_missing] == 0
        sim_data[current_case,:dispatch_minute_all] = now
        sim_data[current_case,:arrival_minute_all]  = arrival_inc
    end
    if  own_district == 1
        sim_data[current_case,:cars_location_responsible] += cars_free + cars_backlog
    end
end