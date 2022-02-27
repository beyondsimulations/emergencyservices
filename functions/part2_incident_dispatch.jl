# function that handles the dispatch of cars
function incident_dispatch!(sim_data::DataFrame,
                            incidents::DataFrame,
                            ressource_flow::Array{Int64,3},
                            drivingtime::Array{Float64,2},
                            traffic::Array{Float64,2},
                            locations::Vector{Int64},
                            current_case::Int64,
                            now::Int64,
                            district::Int64,
                            k::Int64,
                            dispatch::String,
                            fastest_time::Int64)
#  create the neccessary variables
    inc::Int64           = incidents[current_case,:location] # incident_location
    dc::Int64            = locations[district]               # location district center

    # create a vector with all necessary timestamps
    # timestamps[1]: minute of arrival at incident
    # timestamps[2]: minute of departure at incident
    # timestamps[3]: minute of arrival at district center
    timestamps = Vector{Int64}(undef,3)

# calculate the minute the car will arrive at the incident location
    if fastest_time == 0
        timestamps[1] = now + dispatch_drivingtime(drivingtime[dc,inc],traffic,now)
    else
        timestamps[1] = now + fastest_time
    end

# calculate the minute of arrival at the incident and the minute of departure from the incident
    if sim_data[current_case,:cars_dispatched] == 0
        timestamps[2] = timestamps[1] + incidents[current_case,:length]
        timestamps[3] = timestamps[2] + dispatch_drivingtime(drivingtime[inc,dc],traffic,timestamps[2])
        ressource_flow[timestamps[3],district,7] += incidents[current_case,:backlog]
    else
        timestamps[2] = min(timestamps[1] + incidents[current_case,:length], timestamps[1] + 
                        incidents[current_case,:length] - sim_data[current_case,:dispatch_minute_first] + now)
        timestamps[3] = timestamps[2] + dispatch_drivingtime(drivingtime[inc,dc],traffic,timestamps[2])                 
    end

# calculate the number of cars to dispatch to the incident
    # cars[1]:  number of cars dispatched from location currently free
    # cars[2]:  number of cars dispatched from location currently working on backlog
    # cars[3]:  number of cars dispatched currently on patrol
    cars = Vector{Int64}(undef,3) .= 0

    # k = 1: only one car will be dispatched
    # k = 2: the number of dispatched cars dependends on the availability
    if dispatch == "own_department"
        if ressource_flow[now,district,1] > 0
            if k == 1
                cars[1] = 1
            else
                cars[1] = min(sim_data[current_case,:cars_missing], ressource_flow[now,district,1])
            end
        else
            cars[2] = 1
        end
    elseif dispatch == "own_patrol"
        cars[3] = 1
    elseif dispatch == "exchange_department"
        cars[1] = 1
    end

    # calculate the numer of dispatched cars
    total = sum(cars) 

    # assign the calculated capacities into the ressource flow matrix
    ressource_flow[now,district,1]             -= cars[1]
    ressource_flow[now,district,5]             -= cars[2]
    ressource_flow[now,district,6]             -= cars[3]
    ressource_flow[now,district,2]             += total
    ressource_flow[timestamps[1],district,2]   -= total
    ressource_flow[timestamps[1],district,3]   += total
    ressource_flow[timestamps[2],district,3]   -= total
    ressource_flow[timestamps[2],district,4]   += total
    ressource_flow[timestamps[3],district,4]   -= total
    ressource_flow[timestamps[3],district,1]   += total

    # write the resulting times to the sim_data DataFrame
    if sim_data[current_case,:cars_dispatched] == 0
        sim_data[current_case,:location_dispatched_first] = locations[district]
        sim_data[current_case,:dispatch_minute_first]     = now
        sim_data[current_case,:arrival_minute_first]      = timestamps[1]
    end
    sim_data[current_case,:arrival_minute_first]    = min(sim_data[current_case,:arrival_minute_first],timestamps[1])
    sim_data[current_case,:cars_dispatched]         += total
    sim_data[current_case,:cars_missing]            -= total
    if sim_data[current_case,:cars_missing] == 0
        sim_data[current_case,:dispatch_minute_all] = now
        sim_data[current_case,:arrival_minute_all]  = timestamps[1]
    end
    if  dispatch == "own_department" || dispatch == "own_patrol"
        sim_data[current_case,:cars_location_responsible] += total
    end
end
