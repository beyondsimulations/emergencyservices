# prepare the input data for stage 1 of the framework:
# Determine the number of hexagons in this problem instance
    hexsize = size(airdist,1)

# append the weekhour to the incident dataset
    incidents.weekhour = (dayofweek.(unix2datetime.(incidents.epoch)) .- 1) .* 24 .+ 
                            hour.(unix2datetime.(incidents.epoch)) .+ 1

# prepare the workload for each BA if allocated to a potential center
    workload = workload_calculation(incidents::DataFrame,
                                    prio_weight::Vector{Int64},
                                    hexsize::Int64)

# prepare the sets N_{ij} and M_{ij} from the article
    N = Array{Int64,3}(undef,hexsize,hexsize,hexsize)
    M = Array{Int64,3}(undef,hexsize,hexsize,hexsize)
    for i = 1:hexsize
        for j = 1:hexsize
            maxdist = 0
            for v = 1:hexsize
                if adjacent[j,v] == 1
                    if airdist[i,v] < airdist[i,j]
                        N[i,j,v] = 1
                    end
                    maxdist = max(maxdist,airdist[i,v])
                end
            end
            for v = 1:hexsize
                if adjacent[j,v] == 1
                    if airdist[i,v] < maxdist
                        M[i,j,v] = 1
                    end
                end
            end
        end
    end

    # prepare a array that displays the number of elements in N_{ij} and M_{ij}
        card_n = sum(N, dims=3)
        card_m = sum(N, dims=3)
