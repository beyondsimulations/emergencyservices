function determine_patrol_location!(patrol_location::Matrix{Int64},
                                    patrol_area_time::Matrix{Int64},
                                    drivingtime::Array{Float64,2},
                                    ressource_flow::Array{Int64,3},
                                    locations::Vector{Int64},
                                    districts_grouped::GroupedDataFrame,
                                    mnt::Int64)
    patrol_area_time .+= 1
    for department = 1:size(patrol_location,2)
        for patrolcar = 1:ressource_flow[mnt,department,6]
            if patrol_location[patrolcar, department] == 0
                location = rand(1:nrow(districts_grouped[(locations[department],)]))
                patrol_location[patrolcar, department] = districts_grouped[(locations[department],)][location,:index]
                patrol_area_time[patrolcar, department] = 0
            elseif  patrol_area_time[patrolcar, department] > patrol_area
                location = rand(1:nrow(districts_grouped[(locations[department],)]))
                patrol_location[patrolcar, department] = districts_grouped[(locations[department],)][location,:index]
                patrol_area_time[patrolcar, department] = 0
            end
        end
        for patrolcar = ressource_flow[mnt,department,6]+1:size(patrol_location,1)
            patrol_location[patrolcar, department] = 0
            patrol_area_time[patrolcar, department] = 0
        end
    end
end

function determine_patrol_driving_time(district::Int64,
                                       incidents::DataFrame,
                                       traffic::Array{Float64,2},
                                       patrol_location::Matrix{Int64}, 
                                       patrol_drive::Vector{Float64}, 
                                       drivingtime::Array{Float64,2},
                                       current_incident::Int64,
                                       max_drive::Float64,
                                       mnt::Int64)
# calculate the driving time for each patrolling car in the district
    patrol_drive .= patrol_time
    new_time_calculated = false
    for patrol_car = 1:length(patrol_drive)
        if patrol_location[patrol_car,district] > 0
            patrol_drive[patrol_car] = dispatch_drivingtime(drivingtime[patrol_location[patrol_car,district],incidents[current_incident,:location]],traffic,mnt)
            new_time_calculated = true
        end
    end
# if a patrol car is faster than the maximal driving time, select the fastest car on patrol
    fastest_time = patrol_time
    if new_time_calculated == true
        fastest_time = findmin(patrol_drive)[1]
        patrol_car   = findmin(patrol_drive)[2]
        if fastest_time < patrol_time
            patrol_location[patrol_car,district] = 0
        end
    end
    fastest_time = Int(ceil(fastest_time))
    return fastest_time::Int64
end

    



            