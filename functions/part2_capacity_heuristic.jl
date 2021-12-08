# function to generate an adequate DataFrame with capacities for each 
# weekhour and district center if no external capacity plan is provided
 function capacity_heuristic(incidents::DataFrame,
                                sim_data::DataFrame,
                                total_capacity::Int64,
                                min_capacity::Int64)
    # create a DataFrame with time data
        incidents_time = DataFrame(incidentid   = Int[],
        location    = Int[],
        year        = Int[],
        yearweek    = Int[],
        weekhour    = Int[],
        workload    = Float64[])
    # fill the DataFrame with the incident data
        for i = 1:nrow(incidents)
        push!(incidents_time, (incidentid   = incidents[i, :incidentid], 
            location    = sim_data[i,:location_responsible],
            year        = year(unix2datetime(incidents[i, :epoch])),
            yearweek    = week(unix2datetime(incidents[i, :epoch])),
            weekhour    = incidents[i, :weekhour],
            workload = 0))
        end
    # calculate the overall workload in minutes per incident (including 
    # variability of the driving time)
        for i = 1:nrow(incidents)
            for j = 1:incidents[i,:cars]
            incidents_time[i,:workload] += 
            dispatch_drivingtime(drivingtime[sim_data[i,:location_responsible],
            incidents[i,:location]],traffic,sim_data[i,:incident_minute])
            incidents_time[i,:workload] += incidents[i,:length]
            incidents_time[i,:workload] += 
            dispatch_drivingtime(drivingtime[sim_data[i,:location_responsible],
            incidents[i,:location]],traffic,sim_data[i,:incident_minute])
            end
            incidents_time[i,:workload] += incidents[i,:backlog]
        end
    # group the data and create temporary DataFrames to include each weekhour
    # during the incident data set timeframe in each location of a district center
        incidents_time = groupby(incidents_time,[:location,:year,:yearweek,:weekhour])
        incidents_time = combine(incidents_time, :workload  => sum => :workload)
        incidents_time = groupby(incidents_time,[:location,:yearweek,:weekhour])
        incidents_time = combine(incidents_time, :workload  => mean => :workload)
        time_frame = DataFrame(Array{Int64,2}(undef,length(unique(incidents_time[!,:yearweek])),1),[:yearweek])
        time_frame[:,:yearweek] .= unique(incidents_time[!,:yearweek])
        weekhours = DataFrame(Array{Int64,2}(undef,168,1),[:weekhour])
        for i = 1:168
            weekhours[i,:weekhour] = i
        end
        time_frame = crossjoin(time_frame, weekhours, makeunique = true)
        all_locations = unique!(sim_data[:,[:location_responsible]], :location_responsible)
        all_locations = rename!(all_locations,[:location])
        time_frame = crossjoin(time_frame, all_locations, makeunique = true)
        time_frame[:,:shift] .= 0
        for i = 1:nrow(time_frame)
            time_frame[i,:shift] = shifts[time_frame[i, :weekhour]]
        end
        incidents_time = outerjoin(incidents_time,time_frame,on=[:location,:yearweek,:weekhour])
        incidents_time = coalesce.(incidents_time, 0.0)
        incidents_time = sort!(incidents_time,[:location,:yearweek,:weekhour])
    # group the data and include a safety buffer as stated in our article
        incidents_time = groupby(incidents_time,[:location,:weekhour])
        incidents_time = combine(incidents_time,
        :shift => maximum => :shift,
        :workload => mean => :workload_mean,
        :workload => std =>  :workload_std)
        incidents_time = coalesce.(incidents_time, 0.0)
        incidents_time = sort!(incidents_time, [:location,:weekhour,:shift])
        incidents_time[:,:workload] = incidents_time[:,:workload_mean] #+
            incidents_time[:,:workload_std] * 
            quantile.(Normal(), capacity_service)
    # group the resulting workload to generate a mean hourly workload for each
    # district per shift
        shifts_time = groupby(incidents_time,[:location, :shift])
        shifts_time = combine(shifts_time,:workload => maximum => :workload, nrow => :shift_hours)
        shift_length = groupby(shifts_time, :shift)
        shift_length = combine(shift_length, :shift_hours => maximum => :shift_hours)
        shifts_time = select!(shifts_time, Not([:shift_hours]))
        shifts_time = unstack(shifts_time,:location,:workload)
        shifts_capacity = copy(shifts_time)
        shifts_out = copy(shifts_time)
    # assign the available ressources to the shifts during the course of a week
        shifts_capacity = shifts_capacity[:,2:end] .= min_capacity
        shifts_time = shifts_time[:,2:end] = shifts_time[:,2:end] .- 60 * min_capacity
        shifts_capacity = Array(shifts_capacity)
        shifts_time = Array(shifts_time)
        shift_length = Array(shift_length)
        all_capacity = (total_capacity - min_capacity * size(shifts_time,2)) * 168
        while all_capacity >= maximum(shift_length[:,2])
            highest_capacity_pressure = findmax(shifts_time[:,:])[2]
            shifts_time[highest_capacity_pressure] -= 60
            shifts_capacity[highest_capacity_pressure] += 1
            all_capacity -= shift_length[highest_capacity_pressure[1],2]
        end
    # export the resulting DataFrame with the planned capacity per weekhour
    # and district
        shifts_out[:,2:end] = shifts_capacity
        weekhours[:,:shift] .= shifts[:,1]
        shifts_out = innerjoin(weekhours, shifts_out,on=:shift)
        shifts_out = sort!(shifts_out, [:weekhour,:shift])
        simulation_capacity = Array{Int64,2}(shifts_out[:,3:end])
    return simulation_capacity, shifts_out
end