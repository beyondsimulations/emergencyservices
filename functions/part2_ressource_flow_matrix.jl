# function that generates the ressource flow matrix the
# sim_data is build on
function ressource_flow_matrix(sim_data::DataFrame,
                               incidents::DataFrame,
                               simulation_capacity::Array{Int64,2})
### sim_start:  epoch (in minutes) of the first incident
### sim_length: epoch (in minutes) ends 5 minutes after the incident_minute
###             of the last incidents in our incidents DataFrame
    sim_start  = minimum(sim_data[:,:incident_minute])
    sim_length = maximum(sim_data[:,:incident_minute])

### ressource_flow: the ressource flow matrix of the sim_data
### ressource_flow[:,:,1] = capcacity at district center
### ressource_flow[:,:,2] = capcacity driving to incident
### ressource_flow[:,:,3] = capcacity at incident
### ressource_flow[:,:,4] = capcacity driving back to district center
### ressource_flow[:,:,5] = capcacity at paperwork
### ressource_flow[:,:,5] = minutes of paperwork in the corresponding district
    ressource_flow = Array{Int64,3}(undef,sim_length - sim_start + 1000,
                                    size(simulation_capacity,2), 6) .= 0
    current_weekhour = incidents[1,:weekhour]
    current_minute   = minute(unix2datetime(incidents[1,:epoch]))
    ressource_flow[1,:,1] = simulation_capacity[current_weekhour,:]
    for i = 2:size(ressource_flow,1)
        if current_minute == 60
            current_minute = 0
            if current_weekhour >= size(simulation_capacity,1)
                current_weekhour = 0
            end
            current_weekhour += 1
            if current_weekhour == 1
                ressource_flow[i,:,1] .= 
                @view(simulation_capacity[current_weekhour,:]) - 
                @view(simulation_capacity[size(simulation_capacity,1),:])
            else
                ressource_flow[i,:,1] .= 
                @view(simulation_capacity[current_weekhour,:]) - 
                @view(simulation_capacity[current_weekhour-1,:])
            end
        end
        current_minute +=1
    end
    return ressource_flow
end