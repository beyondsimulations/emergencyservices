# function that fills the main queues of each department with all new incidents
# happening during the current minute "mnt"
function fill_queues!(sim_data::DataFrame,
                        incidents::DataFrame,
                        location_district::Dict,
                        incident_queue::Array{Union{Missing,Int},3},
                        queue_used::Array{Int64,2},
                        queue_change::Array{Bool,2},
                        cin::Int64,
                        mnt::Int64,
                        card_incidents::Int64,
                        card_priorities::Int64,
                        card_districts::Int64,
                        max_queue::Int64)
    ## queue_used: array that saves whether a queue is in use
    #    queue_used .= 1
    ## sort the incident queues after the incidents with the longest waiting time 
    for p = 1:card_priorities
        for i = 1:card_districts
            if queue_change[i,p] == true
                incident_queue[:,i,p] = sort!(@view(incident_queue[:,i,p]))
                queue_change[i,p] = false
            end
        end
    end
    ##  fill the incident queue with all new cases arriving during the new minute "mnt"
    while cin <= card_incidents && sim_data[cin,:incident_minute] == mnt
        responsible_district = location_district[sim_data[cin,:location_responsible]]
        incident_priority = incidents[cin,:priority]
        if queue_used[responsible_district,incident_priority] > max_queue
            error("incident queue is to short in district",responsible_district,"!")
        else
            incident_queue[queue_used[responsible_district,incident_priority],responsible_district,incident_priority] = cin
            cin += 1
            queue_used[responsible_district,incident_priority] += 1
        end
    end
    return cin
end