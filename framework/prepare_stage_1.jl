# prepare the input data for stage 1 of the framework
# Create a theme for the Plots
    theme(:vibrant,
    titlefontsize = 10,
    legendfontsize = 6,
    legendtitlefontsize = 8,
    size = (800,400), show = true, dpi = 300,
    legend = :outerright)

# append the weekhour to the incident dataset
    incidents.weekhour = epoch_weekhour.(incidents.epoch)

# prepare the workload for each BA if allocated to a potential center
    if isfile("data/$problem/workload_$problem.csv")
        workload = readdlm("data/$problem/workload_$problem.csv", Float64)
        we = readdlm("data/$problem/weight_$problem.csv", Float64)[:,1]
        print("\n Workload and weight recovered from saved file.")
    else
        dur = @elapsed workload, we = workload_calculation(incidents::DataFrame,
                                                        prio_weight::Vector{Int64},
                                                        drivingtime::Array{Float64,2},
                                                        traffic::Array{Float64,2},
                                                        size(airdist,1)::Int64)
        workload = round.(workload, digits = 3)
        writedlm("data/$problem/workload_$problem.csv", workload)
        writedlm("data/$problem/weight_$problem.csv", we)
        print("\n Finished workload and weight calculation after ",dur," seconds.")
    end

# prepare the sets for the contiguity and compactness constraints
    dur = @elapsed N, M, card_n, card_m = sets_m_n(airdist::Array{Float64,2}, size(airdist,1)::Int64)
    print("\n Finished set calculation after ", dur," seconds.")