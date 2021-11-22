# prepare the sets N_{ij} and M_{ij} from the article
function sets_m_n(airdist::Array{Float64,2}, 
                    hex::Int64)
    N = Array{Bool,3}(undef,hex,hex,hex) .= 0
    M = Array{Bool,3}(undef,hex,hex,hex) .= 0
    for i = 1:hex
        for j = 1:hex
            maxdist = 0
            for v = 1:hex
                if adjacent[j,v] == 1
                    if airdist[i,v] < airdist[i,j]
                        N[i,j,v] = 1
                    end
                    maxdist = max(maxdist,airdist[i,v])
                end
            end
            for v = 1:hex
                if adjacent[j,v] == 1
                    if airdist[i,v] < maxdist
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