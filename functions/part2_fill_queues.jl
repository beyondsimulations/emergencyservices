function fill_queues!(sim_data::DataFrame,
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
    ## queue_used: array that saves whether a queue is in use
        queue_used .= 1
        
    ##  fill the incident queue with all new cases arriving during the new minute "mnt"
    while sim_data[cin,:incident_minute] == mnt && cin < card_incidents
        responsible_district = location_district[sim_data[cin,:location_responsible]]
        incident_priority = incidents[cin,:priority]
        if queue_used[responsible_district,incident_priority] > max_queue
            print("incident queue is to short in district",responsible_district,"!")
        else
            if ismissing(incident_queue[queue_used[responsible_district,incident_priority],responsible_district,incident_priority])
                incident_queue[queue_used[responsible_district,incident_priority],responsible_district,incident_priority] = cin
                cin += 1
            else
                queue_used[responsible_district,incident_priority] += 1
            end
        end
    end
    
    ## sort the incident queues after the incidents with the longest waiting time 
    for p = 1:card_priorities
        for i = 1:card_districts
            if queue_used[i,p] > 0
                incident_queue[:,i,p] = sort!(incident_queue[:,i,p], alg=InsertionSort)
            end
        end
    end
    return cin
end