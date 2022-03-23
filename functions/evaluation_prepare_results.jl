function evaluate_results(incidents::DataFrame,
                          sim_data::DataFrame,
                          ressource_flow::Array{Int64,3},
                          simulation_capacity::Array{Int64,2})
# Evaluate the results of the simulation
    incd = innerjoin(incidents, sim_data, on=:incidentid)
    for i = 1:nrow(incd)
        if ismissing(incd[i,:dispatch_minute_first])
            incd[i,:dispatch_minute_first] = ceil(incd[i,:incident_minute] + drop_incident)
            incd[i,:arrival_minute_first]  = ceil(incd[i,:dispatch_minute_first] + max_drive)
        end
        if ismissing(incd[i,:dispatch_minute_all])
            incd[i,:dispatch_minute_all] = ceil(incd[i,:incident_minute] + drop_incident)
            incd[i,:arrival_minute_all]  = ceil(incd[i,:dispatch_minute_all] + max_drive)
        end
    end
    incd[:,:response_time_first]   = incd[:,:arrival_minute_first] - incd[:,:incident_minute]
    incd[:,:response_time_all]     = incd[:,:arrival_minute_all] -  incd[:,:incident_minute]
    incd[:,:dispatch_time_first]   = incd[:,:dispatch_minute_first] - incd[:,:incident_minute]
    incd[:,:dispatch_time_all]     = incd[:,:dispatch_minute_all] - incd[:,:incident_minute]
    incd[:,:driving_time_first]    = incd[:,:arrival_minute_first] - incd[:,:dispatch_minute_first]

# Group the results for evaluation
# 1. group the results according to the location and weekhour
    weekly_location = groupby(dropmissing(select!(copy(incd), Not([:priority]))), [:location_responsible, :weekhour])
    weekly_location = combine(weekly_location, nrow => :total_incidents_response,
                                            :cars => mean => :requested_cars,
                                            :cars_dispatched => mean => :dispatched_cars,
                                            :dispatch_time_first => mean => :dispatch_time_first,
                                            :dispatch_time_all => mean => :dispatch_time_all,
                                            :response_time_first => mean => :response_time_first,
                                            :response_time_all => mean => :response_time_all,
                                            :driving_time_first => mean => :driving_time_first,
                                            :cars_missing => mean => :cars_missing,
                                            :cars_location_responsible => mean => :cars_location_responsible)
    weekly_location = sort!(weekly_location, [:weekhour, :location_responsible])
    weekly_location[!,:exchange_ratio] = 1 .- weekly_location[!,:cars_location_responsible] ./ 
                                                weekly_location[!,:dispatched_cars]
    weekly_location.location_responsible = convert.(Int64, weekly_location.location_responsible)

# 2. group the results according to the priority and weekhour
    weekly_priority = groupby(select!(copy(incd), Not([:location_dispatched_first])), [:weekhour, :priority])
    weekly_priority = combine(weekly_priority,
                        nrow => :total_incidents_response,
                        :cars => mean => :requested_cars,
                        :cars_dispatched => mean => :dispatched_cars,
                        :dispatch_time_first => mean => :dispatch_time_first,
                        :dispatch_time_all => mean => :dispatch_time_all,
                        :response_time_first => mean => :response_time_first,
                        :response_time_all => mean => :response_time_all,
                        :driving_time_first => mean => :driving_time_first,
                        :cars_missing => mean => :cars_missing,
                        :cars_location_responsible => mean => :cars_location_responsible)
    weekly_priority = sort!(weekly_priority, [:weekhour, :priority])
    weekly_priority[!,:exchange_ratio] = 1 .- weekly_priority[!,:cars_location_responsible] ./ 
                                                weekly_priority[!,:dispatched_cars]
    weekly_priority[:,:priority] = Int.(weekly_priority[:,:priority])
    weekly_priority.priority = convert.(Int64, weekly_priority.priority)

# 3. group the results for a single output row
    main_results = combine(select!(copy(incd), Not([:location_dispatched_first])),
                                nrow => :total_incidents,
                                :cars => mean => :requested_cars,
                                :cars_dispatched => mean => :dispatched_cars,
                                :dispatch_time_first => mean => :dispatch_time_first,
                                :response_time_first => mean => :response_time_first,
                                :driving_time_first  => mean => :driving_time_first,
                                :dispatch_time_all   => mean => :dispatch_time_all,
                                :response_time_all   => mean => :response_time_all,
                                :cars_missing        => mean => :cars_missing,
                                :cars_location_responsible => mean => :cars_location_responsible)
    main_results[!,:incidents_unfulfilled]      .= size(filter(:cars_dispatched => isequal(0), incd),1)
    main_results[!,:total_incidents_fulfilled]   = size(incd,1) .- main_results[!,:incidents_unfulfilled]
    main_results[!,:cars_total_dispatched]       = main_results[!,:dispatched_cars] .* main_results[!,:total_incidents]
    main_results[!,:exchange_ratio]              = 1 .- main_results[!,:cars_location_responsible] ./ main_results[!,:dispatched_cars]
    main_results[!,:ratio_cars_undispatched]     = main_results[!,:cars_missing] ./ main_results[!,:dispatched_cars]
        
# 5. create a DataFrame that holds the ressource flow during the simulation
    capacity_status, mcs = ressource_status(ressource_flow::Array{Int64,3}, incd::DataFrame, simulation_capacity::Array{Int64,2})
    main_results = hcat(main_results,mcs)
    
    return main_results, weekly_location, weekly_priority, capacity_status
end
