# calculate the workload for each possible BA combination
function workload_calculation(incidents::DataFrame,
                                prio_weight::Vector{Int64},
                                drivingtime::Array{Float64,2},
                                traffic::Array{Float64,2},
                                hex::Int64)
    workload = copy(drivingtime) 
    local_incidents = copy(incidents)
    local_incidents[:,:priority_weight] .= 0
    for i = 1:nrow(local_incidents)
        local_incidents[i,:priority_weight] = prio_weight[local_incidents[i,:priority]]
    end
    workload_group = groupby(local_incidents,[:location,:weekhour,:priority_weight])
    workload_group = combine(workload_group, nrow => :incidents, :cars => mean => :cars)
    cases_location = groupby(local_incidents,[:location])
    cases_location = combine(cases_location, nrow => :incidents)
    incidents_location = Vector{Float64}(undef,hex) .= 0
    for x = 1:nrow(cases_location)
        incidents_location[cases_location[x,:location]] = cases_location[x,:incidents]
    end
    for x = 1:nrow(workload_group)
        for i = 1:hex
            workload[i,workload_group[x,:location]] += drivingtime[i,workload_group[x,:location]] * 2 * 
                                                        traffic[workload_group[x,:weekhour],1] * 
                                                        workload_group[x,:cars] * 
                                                        workload_group[x,:priority_weight] *  
                                                        workload_group[x,:incidents]
        end
    end
    return workload::Array{Float64,2}, incidents_location::Vector{Float64}
end