# calculate the workload for each possible BA combination
function workload_calculation(incidents::DataFrame,
                                prio_weight::Vector{Int64},
                                hex::Int64)
    workload = Array{Float64,2}(undef,hex,hex) .= 0
    for incident = 1:size(incidents,1)
        location =  incidents[incident,:location]
        weekhour =  incidents[incident,:weekhour]
        cars =      incidents[incident,:cars]
        prio =      prio_weight[incidents[incident,:priority]]
        inclen =    incidents[incident,:length]
        backl =     incidents[incident,:backlog]
        for i = 1:hex
            if i != location
                driving = 2 * drivingtime[i,location] * traffic[weekhour,1]
                workload[i,location] = driving * cars * prio + inclen + backl
            end
        end
    end
    return workload::Array{Float64,2}
end