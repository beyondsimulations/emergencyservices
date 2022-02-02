# prepare the sets N_{ij} and M_{ij} from the article
# for further details take a look at our article
function sets_m_n(airdist::Array{Float64,2}, hex::Int64)
    N = Array{Bool,3}(undef,hex,hex,hex) .= 0
    M = Array{Bool,3}(undef,hex,hex,hex) .= 0
    maxdist = Array{Float64,2}(undef,hex,hex) .= 0
    for j = 1:hex
        for v = 1:hex
            if adjacent[j,v] == 1
                for i = 1:hex
                    if airdist[i,v] < airdist[i,j]
                        N[i,j,v] = 1
                    end
                    maxdist[i,j] = max(maxdist[i,j], airdist[i,v])
                end
            end
        end
    end
    for j = 1:hex        
        for v = 1:hex
            if adjacent[j,v] == 1
                for i = 1:hex
                    if airdist[i,v] < maxdist[i,j]
                        M[i,j,v] = 1
                    end
                end
            end
        end
    end
    card_n = sum(N, dims=3)[:,:,1]
    card_m = sum(M, dims=3)[:,:,1]
    return  N::Array{Bool,3}, 
            M::Array{Bool,3}, 
            card_n::Array{Int64,2}, 
            card_m::Array{Int64,2}
end