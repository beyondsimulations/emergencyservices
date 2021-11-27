function fulfill_exchange_queue!(incidents::DataFrame,
                                 sim_data::DataFrame,
                                 location_district::Dict,
                                 ressource_flow::Array{Int64,3},
                                 drivingtime::Array{Float64,2},
                                 exchange_queue::Array{Union{Missing,Int64},1},
                                 candidates::Vector{Union{Missing,Float64}},
                                 locations::Vector{Int64},
                                 exchange_reserve::Vector{Int64},
                                 card_districts::Int64,
                                 mnt::Int64,
                                 own_district::Int64,
                                 max_drive::Float64,
                                 p::Int64)
    for j = 1:length(exchange_queue)
        if ismissing(exchange_queue[j]) == false
            current_case = exchange_queue[j]
            candidate = false
            candidates .= missing
            for i = 1:card_districts
                if ressource_flow[mnt,i,1] > exchange_reserve[p]
                    drive = dispatch_drivingtime(drivingtime[locations[i],
                                                    incidents[current_case,:location]],
                                                    traffic,mnt)
                    if drive < max_drive
                        candidates[i] = -(ressource_flow[mnt,i,1]/drive)
                        candidate = true
                    end
                end
            end
            if candidate == true
                i = findmax(skipmissing(candidates))[2]
                k = 1
                incident_dispatch!(sim_data::DataFrame,
                                   incidents::DataFrame,
                                   ressource_flow::Array{Int64,3},
                                   drivingtime::Array{Float64,2},
                                   traffic::Array{Float64,2},
                                   locations::Vector{Int64},
                                   current_case::Int64,
                                   mnt::Int64,
                                   i::Int64,
                                   k::Int64,
                                   own_district::Int64)
            end
        else
            break
        end
    end
end