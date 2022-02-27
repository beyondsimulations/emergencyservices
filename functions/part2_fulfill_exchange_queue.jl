# function that fulfills all incidents in the exchange queue during
# the current minute "mnt" if possible
function fulfill_exchange_queue!(incidents::DataFrame,
                                 sim_data::DataFrame,
                                 ressource_flow::Array{Int64,3},
                                 drivingtime::Array{Float64,2},
                                 exchange_queue::Array{Union{Missing,Int64},1},
                                 candidates::Vector{Union{Missing,Float64}},
                                 locations::Vector{Int64},
                                 exchange_reserve::Vector{Int64},
                                 card_districts::Int64,
                                 mnt::Int64,
                                 dispatch::String,
                                 max_drive::Float64,
                                 p::Int64)
    for j = 1:length(exchange_queue)
        # check whether the queue holds candidates for exchange
        if ismissing(exchange_queue[j]) == false
            # clear the list of current candidates in the queue
            current_case = exchange_queue[j]
            candidate = false
            candidates .= missing
            # check for all districts within an acceptable perimeter
            # how long the driving time would take during the current
            # traffic flow
            @simd for i = 1:card_districts
                if ressource_flow[mnt,i,1] > exchange_reserve[p] &&
                    drivingtime[locations[i],incidents[current_case,:location]] <= max_drive
                    drive = dispatch_drivingtime(drivingtime[locations[i], incidents[current_case,:location]], traffic, mnt)
                    # save the location as exchange candidate and weight it by 
                    # the current number of cars available for dispatch
                    if drive < max_drive
                        candidates[i] = ressource_flow[mnt,i,1]/drive
                        candidate = true
                    end
                end
            end
            # determine the best candidate from the candidate list (if available)
            if candidate == true
                i = findmin(skipmissing(candidates))[2]
                k = 1
                fastest_time = 0
                # dispatch one car from the exchange location
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
                                   dispatch::String,
                                   fastest_time::Int64)
            end
        else
            break
        end
    end
end