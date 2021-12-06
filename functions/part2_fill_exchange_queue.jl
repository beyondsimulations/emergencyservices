# function to allocate incidents from the current queue of each department
# to a second queue that checks whether other departments could help out
function fill_exchange_queue!(sim_data::DataFrame,
                                incident_queue::Array{Union{Missing,Int64},3},
                                exchange_queue::Array{Union{Missing,Int64},1},
                                max_queue::Int64,
                                card_districts::Int64,
                                priority::Int64)
    place_in_queue = 1
    exchange_queue .= missing
    for i = 1:card_districts
        for j = 1:max_queue
            # allocate the incident from the main queues to the exchange queue
            if ismissing(incident_queue[j,i,priority]) == false
                current_case = incident_queue[j,i,priority]
                if place_in_queue > length(exchange_queue)
                    error("w_aus is too small!")
                    break
                else
                    if sim_data[current_case,:cars_missing] > 0
                        exchange_queue[place_in_queue] = current_case
                        place_in_queue += 1
                    end
                end
            else
                break
            end
        end
    end
end