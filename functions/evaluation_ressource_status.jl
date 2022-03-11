# function to aggregate the ressource flows of the simulation into
# average weekly data over all locations
function ressource_status(ressource_flow::Array{Int64,3},
                          incidents::DataFrame,
                          simulation_capacity::Array{Int64,2})
    # Dataframe to be filled
    capacity_status = DataFrame(sum(ressource_flow, dims = 2)[:,1,:],
                                        [:at_location,
                                        :to_incident,
                                        :at_incident,
                                        :to_location,
                                        :at_backlog,
                                        :at_patrol,
                                        :backlog_minutes])
    # append the weekhour to the ressource flow DataFrame
    current_weekhour = incidents[1,:weekhour]
    current_minute   = minute(unix2datetime(incidents[1,:epoch]))
    capacity_status[:,:weekhour] .= 0
    for i = 1:size(capacity_status,1)
        if current_minute == 60
            current_minute = 0
            if current_weekhour >= size(simulation_capacity,1)
                current_weekhour = 0
            end
            current_weekhour += 1
        end
        capacity_status[i,:weekhour]  = current_weekhour
        current_minute +=1
    end
    # group the DataFrame by weekhour
    capacity_status = groupby(capacity_status, :weekhour)
    capacity_status = combine(capacity_status,
                        :at_location => mean => :at_location,
                        :to_incident => mean => :to_incident,
                        :at_incident => mean => :at_incident,
                        :to_location => mean => :to_location,
                        :at_backlog  => mean => :at_backlog,
                        :at_patrol   => mean => :at_patrol,
                        :backlog_minutes => mean => :backlog_minutes)
    capacity_status = sort!(capacity_status, :weekhour)

    # create an additional DataFrame to hold the average backlog for
    # each weekhour over all locations
    capacity_status = select!(capacity_status, Not([:backlog_minutes]))
    main_capacity_status = combine(capacity_status, [n => mean => n for n in names(capacity_status)])
    capacity_status = sort!(stack(capacity_status, 2:7), [:weekhour])
    
    return capacity_status, main_capacity_status
end