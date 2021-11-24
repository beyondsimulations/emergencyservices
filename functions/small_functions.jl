# function to calculate the driving time after a car is dispatched
function dispatch_drivingtime(distance,traffic_flow,traffic_deviation)
    max(1, round(distance * traffic_flow * rand(Normal(1,traffic_deviation)),digits = 0))
end