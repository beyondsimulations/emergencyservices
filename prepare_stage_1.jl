# prepare the input data for stage 1 of the framework
# Create a theme for the Plots
    theme(:vibrant,
    titlefontsize = 10,
    legendfontsize = 6,
    legendtitlefontsize = 8,
    size = (800,400), show = true, dpi = 300,
    legend = :outerright)
# Determine the number of hexagons in this problem instance
    hex = size(airdist,1)

# append the weekhour to the incident dataset
    incidents.weekhour = epoch_weekhour.(incidents.epoch)

# prepare the workload for each BA if allocated to a potential center
    workload = workload_calculation(incidents::DataFrame,
                                    prio_weight::Vector{Int64},
                                    hex::Int64)

# prepare the sets for the contiguity and compactness constraints
    N, M, card_n, card_m = sets_m_n(airdist::Array{Float64,2}, 
                                    hex::Int64)
