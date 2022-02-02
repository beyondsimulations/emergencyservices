function plot_simulation_results(weekly_location::DataFrame, 
                                 weekly_priority::DataFrame, 
                                 capacity_status::DataFrame,
                                 capacity_plot::DataFrame,
                                 subproblem::String,
                                 compactness::String)
# plot the results
    theme(:vibrant,
    size = (800,400), show = true, dpi = 300,
    legend = :outerright,
    xticks = [0,12,24,36,48,60,72,84,96,108,120,132,144,156,168],
    minorticks = 4)
# plot the results for each location
    y_limit = ceil(Int64,maximum(weekly_location[:,:dispatch_time_first]))*1.05
    display(@df weekly_location plot(:weekhour, :dispatch_time_first,
    group = :location_responsible,
    lw = 0.5,
    title = "Location: average time till first dispatch",
    legendtitle = "Location",
    xlabel = "hour of week",
    ylabel = "minutes",
    ylims = (0, y_limit)))
    if save_plots == true
        savefig("graphs/$problem/location_dispatch_$(problem)_$(subproblem)_$(compactness).pdf")
    end

    y_limit = ceil(Int64,maximum(weekly_location[:,:driving_time_first]))*1.05
    display(@df weekly_location plot(:weekhour, :driving_time_first,
    group = :location_responsible,
    lw = 0.5,
    title = "Location: average driving time to incidents",
    legendtitle = "Location",
    xlabel = "hour of week",
    ylabel = "minutes",
    ylims = (0, y_limit)))
    if save_plots == true
        savefig("graphs/$problem/location_driving_$(problem)_$(subproblem)_$(compactness).pdf")
    end

    y_limit = ceil(Int64,maximum(weekly_location[:,:total_incidents_response]))*1.05
    display(@df weekly_location plot(:weekhour, :total_incidents_response,
    group = :location_responsible, lw = 0.5,
    title = "Location: average number of incidents with response",
    legendtitle = "Location",
    xlabel = "hour of week",
    ylabel = "incidents",
    ylims = (0, y_limit)))
    if save_plots == true
        savefig("graphs/$problem/location_incidents_$(problem)_$(subproblem)_$(compactness).pdf")
    end

    display(@df weekly_location plot(:weekhour, :exchange_ratio,
    group = :location_responsible,
    lw = 0.5,
    title = "Location: exchange ratio of cars",
    legendtitle = "Location",
    xlabel = "hour of week",
    ylabel = "ratio",
    ylims = (0, 1)))
    if save_plots == true
        savefig("graphs/$problem/location_exchange_$(problem)_$(subproblem)_$(compactness).pdf")
    end

# plot the results for each priority
    y_limit = ceil(Int64,maximum(weekly_priority[:,:dispatch_time_first]))*1.05
    display(@df weekly_priority plot(:weekhour, :dispatch_time_first,
    group = :priority,
    lw = 0.5,
    title = "Priority: average time till first dispatch",
    legendtitle = "Priority",
    xlabel = "hour of week",
    ylabel = "minutes",
    ylims = (0, y_limit)))
    if save_plots == true
        savefig("graphs/$problem/priority_dispatch_$(problem)_$(subproblem)_$(compactness).pdf")
    end

    y_limit = ceil(Int64,maximum(weekly_priority[:,:driving_time_first]))*1.05
    display(@df weekly_priority plot(:weekhour, :driving_time_first,
    group = :priority,
    lw = 0.5,
    title = "Priority: average driving time to incidents",
    legendtitle = "Priority",
    xlabel = "hour of week",
    ylabel = "minutes",
    ylims = (0, y_limit)))
    if save_plots == true
        savefig("graphs/$problem/priority_driving_$(problem)_$(subproblem)_$(compactness).pdf")
    end

    y_limit = ceil(Int64,maximum(weekly_priority[:,:total_incidents_response]))*1.05
    display(@df weekly_priority plot(:weekhour, :total_incidents_response,
    group = :priority, lw = 0.5,
    title = "Priority: average number of incidents with response",
    legendtitle = "Priority",
    xlabel = "hour of week",
    ylabel = "incidents",
    ylims = (0, y_limit)))
    if save_plots == true
        savefig("graphs/$problem/priority_incidents_$(problem)_$(subproblem)_$(compactness).pdf")
    end

    display(@df weekly_priority plot(:weekhour, :exchange_ratio,
    group = :priority,
    lw = 0.5,
    title = "Priority: exchange ratio of cars",
    legendtitle = "Priority",
    xlabel = "hour of week",
    ylabel = "ratio",
    ylims = (0, 1)))
    if save_plots == true
        savefig("graphs/$problem/priority_exchange_$(problem)_$(subproblem)_$(compactness).pdf")
    end

# plot the ressource flow during simulation
    y_limit_min = floor(Int64,minimum(capacity_plot[:,:value]))*0.9
    y_limit_max = ceil(Int64,maximum(capacity_plot[:,:value]))*1.05
    display(@df capacity_plot plot(:weekhour, :value, group = :variable,
                lw = 1, title = "Ressources: ressources allocated",
                legendtitle = "Location",
                xlabel = "hour of week",
                ylabel = "ressources",
                ylims = (y_limit_min, y_limit_max)))
    if save_plots == true
        savefig("graphs/$problem/ressources_allocated_$(problem)_$(subproblem)_$(compactness).pdf")
    end

# plot the ressource allcoation of the heuristic
    y_limit_min = floor(Int64,minimum(capacity_status[:,:value]))*0.9
    y_limit_max = ceil(Int64,maximum(capacity_status[:,:value]))*1.05
    display(@df capacity_status plot(:weekhour, :value, group = :variable,
                lw = 1, title = "Ressources: status of ressources",
                legendtitle = "Status",
                xlabel = "hour of week",
                ylabel = "ressources",
                ylims = (y_limit_min, y_limit_max)))
    if save_plots == true
        savefig("graphs/$problem/ressources_status_$(problem)_$(subproblem)_$(compactness).pdf")
    end
end