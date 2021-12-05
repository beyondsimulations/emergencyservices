# function to calculate the driving time after a car is dispatched
function dispatch_drivingtime(distance,traffic,epoch_minute)
    max(1, round(Int64, distance * traffic_markup(traffic,epoch_weekhour(epoch_minute))))
end

function traffic_markup(traffic,weekhour)
    traffic[weekhour,1] * rand(Normal(1,traffic[weekhour,2]))
end

# function to calculate the weekhour based on the current epoch
function epoch_weekhour(epoch_minute)
    epoch = epoch_minute
    weekhour = (dayofweek(unix2datetime(epoch)) - 1) * 24 + hour(unix2datetime(epoch)) + 1
    return weekhour
end