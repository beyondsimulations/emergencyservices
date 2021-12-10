# function that handles prepares the queues and ressource flow for the
# next minute of the simulationn
function prepare_next_minute!(sim_data::DataFrame,
                              incidents::DataFrame,
                              ressource_flow::Array{Int64,3},
                              incident_queue::Array{Union{Missing,Int64},3},
                              queue_used::Array{Int64,2},
                              queue_change::Array{Bool,2},
                              mnt::Int64,
                              drop_incident::Int64)
    # if a location has unused ressources and a backlog, the ressources are assigned
    # to work on the backlog as long as there is a backlog left
    for i = 1:size(ressource_flow,2)
        if ressource_flow[mnt,i,1] > 0 && ressource_flow[mnt,i,6] > 0
            ressource_flow[mnt,i,5] += min(ressource_flow[mnt,i,1],ressource_flow[mnt,i,6])
            ressource_flow[mnt,i,1] -= min(ressource_flow[mnt,i,1],ressource_flow[mnt,i,6])
        end
        if ressource_flow[mnt,i,6] > 0
            ressource_flow[mnt,i,6] = max(ressource_flow[mnt,i,6] - ressource_flow[mnt,i,5], 0)
        else
            ressource_flow[mnt,i,1] += ressource_flow[mnt,i,5]
            ressource_flow[mnt,i,5]  = 0
        end
    end
    # drop all fulfilled incidents and the incidents that pass the "drop_incident" threshold from
    # the incident queues
    for i = 1:size(incident_queue,2)
        for p = 1:size(incident_queue,3)
            for j = 1:size(incident_queue,1)
                if ismissing(incident_queue[j,i,p]) == false
                    current_case = incident_queue[j,i,p]
                    if  sim_data[current_case,:cars_missing] == 0 ||
                        (ismissing(sim_data[current_case,:dispatch_minute_first]) == false && 
                        mnt - sim_data[current_case,:dispatch_minute_first] >= incidents[current_case,:length]) ||
                        mnt - sim_data[current_case,:incident_minute] >= drop_incident
                            incident_queue[j,i,p] = missing
                            queue_change[i,p] = true
                            queue_used[i,p] -= 1
                    end
                end
            end
        end
    end
    # move the current ressource status to the next minute
    if mnt + 1 <= size(ressource_flow,1)
        for i = 1:size(ressource_flow,2)
            for j = 1:size(ressource_flow,3)
                ressource_flow[mnt+1,i,j] += ressource_flow[mnt,i,j]
            end
        end
    end
end