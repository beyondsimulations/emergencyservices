function prepare_next_minute!(sim_data::DataFrame,
                              incidents::DataFrame,
                              ressource_flow::Array{Int64,3},
                              incident_queue::Array{Union{Missing,Int64},3},
                              mnt::Int64,
                              drop_incident::Int64)
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
                    end
                end
            end
        end
    end
    if mnt + 1 <= size(ressource_flow,1)
        for i = 1:size(ressource_flow,2)
            for j = 1:size(ressource_flow,3)
                ressource_flow[mnt+1,i,j] += ressource_flow[mnt,i,j]
            end
        end
    end
end