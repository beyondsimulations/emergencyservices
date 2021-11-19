function workload_calculation(incidents::DataFrame,
                                prio_weight::Vector{Int64},
                                hexsize::Int64)
    workload = Array{Int64,2}(undef,hexsize,hexsize) .= 0
    for incident = 1:size(incidents,1)
        location =  incidents[incident,:location]
        weekhour =  incidents[incident,:weekhour]
        cars =      incidents[incident,:cars]
        prio =      prio_weight[incidents[incident,:priority]]
        inclen =    incidents[incident,:length]
        backl =     incidents[incident,:backlog]
        for i = 1:hexsize
            if i != location
                driving = 2 * drivingtime[i,location] * traffic[weekhour,1]
                workload[i,location] = ceil(driving * cars * prio + inclen + backl)
            end
        end
    end
    return workload::Array{Int64,2}
end