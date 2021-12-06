# Evaluate the results of the simulation
    incidents = innerjoin(incidents,sim_data,on=:incidentid)
    incidents[:,:response_time_first]   = incidents[:,:arrival_minute_first] - 
                                            incidents[:,:incident_minute]
    incidents[:,:response_time_all]     = incidents[:,:arrival_minute_all] -   
                                            incidents[:,:incident_minute]
    incidents[:,:dispatch_time_first]   = incidents[:,:dispatch_minute_first] -
                                            incidents[:,:incident_minute]
    incidents[:,:dispatch_time_all]     = incidents[:,:dispatch_minute_all] - 
                                            incidents[:,:incident_minute]
    incidents[:,:driving_time_first]    = incidents[:,:arrival_minute_first] - 
                                            incidents[:,:dispatch_minute_first]

# Group the results for evaluation
# 1. group the results according to the location and weekhour
    weekly_location = groupby(dropmissing(select!(copy(incidents), 
                                Not([:priority]))), [:location_responsible, :weekhour])
    weekly_location = combine(weekly_location,
                        nrow => :total_incidents_response,
                        :cars => mean => :requested_cars,
                        :cars_dispatched => mean => :dispatched_cars,
                        :dispatch_time_first => mean => :dispatch_time_first,
                        :dispatch_time_all => mean => :dispatch_time_all,
                        :response_time_first => mean => :response_time_first,
                        :response_time_all => mean => :response_time_all,
                        :driving_time_first => mean => :driving_time_first,
                        :cars_missing => mean => :cars_missing,
                        :cars_location_responsible => mean => :cars_location_responsible)
    weekly_location = sort!(weekly_location, [:weekhour, :location_responsible])
    weekly_location[!,:exchange_ratio] = 1 .- weekly_location[!,:cars_location_responsible] ./ 
                                                weekly_location[!,:dispatched_cars]
    weekly_location = round.(weekly_location,digits=4)

# 2. group the results according to the priority and weekhour
    weekly_priority = groupby(dropmissing(select!(copy(incidents), 
                                Not([:location_responsible]))), [:weekhour, :priority])
    weekly_priority = combine(weekly_priority,
                        nrow => :total_incidents_response,
                        :cars => mean => :requested_cars,
                        :cars_dispatched => mean => :dispatched_cars,
                        :dispatch_time_first => mean => :dispatch_time_first,
                        :dispatch_time_all => mean => :dispatch_time_all,
                        :response_time_first => mean => :response_time_first,
                        :response_time_all => mean => :response_time_all,
                        :driving_time_first => mean => :driving_time_first,
                        :cars_missing => mean => :cars_missing,
                        :cars_location_responsible => mean => :cars_location_responsible)
    weekly_priority = sort!(weekly_priority, [:weekhour, :priority])
    weekly_priority[!,:exchange_ratio] = 1 .- weekly_priority[!,:cars_location_responsible] ./ 
                                                weekly_priority[!,:dispatched_cars]
    weekly_priority = round.(weekly_priority,digits=4)

# 3. group the results for a single output row  - skip the cases that could not be fulfilled completely
    overall_skipmissing = combine(incidents,
                        nrow => :total_incidents_fulfilled,
                        :cars => mean => :requested_cars,
                        :cars_dispatched => mean => :dispatched_cars,
                        :dispatch_time_first => mean => :dispatch_time_first,
                        :response_time_first => mean => :response_time_first,
                        :driving_time_first => mean => :driving_time_first,
                        :cars_missing => mean => :cars_missing,
                        :cars_location_responsible => mean => :cars_location_responsible)
    overall_skipmissing[!,:incidents_unfulfilled] = size(incidents,1) .- 
                                                    overall_skipmissing[!,:total_incidents_fulfilled]
    overall_skipmissing = round.(overall_skipmissing,digits=4)

# 4. group the results for a single output row - include the cases that haven't been fulfilled completely
    overall_missing = combine(dropmissing(select!(copy(incidents), 
                                                    Not([:arrival_minute_all,:dispatch_minute_all,
                                                            :response_time_all,:dispatch_time_all]))),
                        nrow => :total_incidents_fulfilled,
                        :cars => mean => :requested_cars,
                        :cars_dispatched => mean => :dispatched_cars,
                        :dispatch_time_first => mean => :dispatch_time_first,
                        :response_time_first => mean => :response_time_first,
                        :driving_time_first => mean => :driving_time_first,
                        :cars_missing => mean => :cars_missing,
                        :cars_location_responsible => mean => :cars_location_responsible)
    overall_missing[!,:incidents_unfulfilled] = size(incidents,1) .- 
                                                overall_missing[!,:total_incidents_fulfilled]
    overall_missing[!,:cars_total_dispatched] = overall_missing[!,:dispatched_cars] .* 
                                                overall_missing[!,:total_incidents_fulfilled]
    overall_missing[!,:exchange_ratio] = 1 .- overall_missing[!,:cars_location_responsible] ./ 
                                                overall_missing[!,:dispatched_cars]
    overall_missing[!,:ratio_cars_undispatched] = overall_missing[!,:cars_missing] ./ 
                                                    overall_missing[!,:dispatched_cars]
    overall_missing = round.(overall_missing,digits=4)
        


# 5. create a DataFrame that holds the ressource flow during the simulation
    capacity_status, backlog_status = ressource_status(ressource_flow::Array{Int64,3},
                                                       incidents::DataFrame,
                                                       simulation_capacity::Array{Int64,2})

# 6. create a DataFrame that holds the assigned capacity per location and weekhour
    capacity_plot = sort!(stack(capacity_plot, 3:size(capacity_plot,2)), [:weekhour])

# Plot the results
# Create a theme for the Plots
    theme(:vibrant,
        titlefontsize = 12,
        legendfontsize = 6,
        legendtitlefontsize = 8,
        size = (800,400), show = true, dpi = 300,
        legend = :outerright,
        xticks = [0,12,24,36,48,60,72,84,96,108,120,132,144,156,168],
        minorticks = 4)

# plot the results for each location
    y_limit = ceil(Int64,maximum(weekly_location[:,:dispatch_time_first]))*1.05
    display(@df weekly_location plot(:weekhour, :dispatch_time_first,
    group = :location_responsible,
    lw = 0.5,
    title = "PK: average waiting time till allocation",
    legendtitle = "Location",
    xlabel = "hour of week",
    ylabel = "minutes",
    ylims = (0, y_limit)))

    y_limit = ceil(Int64,maximum(weekly_location[:,:driving_time_first]))*1.05
    display(@df weekly_location plot(:weekhour, :driving_time_first,
    group = :location_responsible,
    lw = 0.5,
    title = "Location: average driving time",
    legendtitle = "Location",
    xlabel = "hour of week",
    ylabel = "minutes",
    ylims = (0, y_limit)))

    y_limit = ceil(Int64,maximum(weekly_location[:,:total_incidents_response]))*1.05
    display(@df weekly_location plot(:weekhour, :total_incidents_response,
    group = :location_responsible, lw = 0.5,
    title = "Location: average incidents with response",
    legendtitle = "Location",
    xlabel = "hour of week",
    ylabel = "cases",
    ylims = (0, y_limit)))

    display(@df weekly_location plot(:weekhour, :exchange_ratio,
    group = :location_responsible,
    lw = 0.5,
    title = "Location: Exchange Proportion",
    legendtitle = "Location",
    xlabel = "hour of week",
    ylabel = "ratio",
    ylims = (0, 1)))

# plot the results for each priority
    y_limit = ceil(Int64,maximum(weekly_priority[:,:dispatch_time_first]))*1.05
    display(@df weekly_priority plot(:weekhour, :dispatch_time_first,
    group = :priority,
    lw = 0.5,
    title = "Priority: average waiting time till allocation",
    legendtitle = "Priority",
    xlabel = "hour of week",
    ylabel = "minutes",
    ylims = (0, y_limit)))

    y_limit = ceil(Int64,maximum(weekly_priority[:,:driving_time_first]))*1.05
    display(@df weekly_priority plot(:weekhour, :driving_time_first,
    group = :priority,
    lw = 0.5,
    title = "Priority: average driving time",
    legendtitle = "Priority",
    xlabel = "hour of week",
    ylabel = "minutes",
    ylims = (0, y_limit)))

    y_limit = ceil(Int64,maximum(weekly_priority[:,:total_incidents_response]))*1.05
    display(@df weekly_priority plot(:weekhour, :total_incidents_response,
    group = :priority, lw = 0.5,
    title = "Priority: average incidents with response",
    legendtitle = "Priority",
    xlabel = "hour of week",
    ylabel = "cases",
    ylims = (0, y_limit)))

    display(@df weekly_priority plot(:weekhour, :exchange_ratio,
    group = :priority,
    lw = 0.5,
    title = "Priority: Exchange Proportion",
    legendtitle = "Priority",
    xlabel = "hour of week",
    ylabel = "ratio",
    ylims = (0, 1)))

# plot the ressource flow during simulation
    y_limit_min = floor(Int64,minimum(capacity_plot[:,:value]))*0.9
    y_limit_max = ceil(Int64,maximum(capacity_plot[:,:value]))*1.05
    display(@df capacity_plot plot(:weekhour, :value, group = :variable,
                lw = 1, title = "Locations: ressources allocated per weekhour",
                legendtitle = "Location",
                xlabel = "hour of week",
                ylabel = "ressources",
                ylims = (y_limit_min, y_limit_max)))

# plot the ressource allcoation of the heuristic
    y_limit_min = floor(Int64,minimum(capacity_status[:,:value]))*0.9
    y_limit_max = ceil(Int64,maximum(capacity_status[:,:value]))*1.05
    display(@df capacity_status plot(:weekhour, :value, group = :variable,
                lw = 1, title = "Locations: average ressource status over all locations",
                legendtitle = "Status",
                xlabel = "hour of week",
                ylabel = "ressources",
                ylims = (y_limit_min, y_limit_max)))