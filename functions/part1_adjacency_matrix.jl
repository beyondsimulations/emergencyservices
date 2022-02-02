# create an adjacency matrix based on the airdistance
function adjacency_matrix(airdist::Array{Float64,2})
    adjacent = Array{Bool,2}(undef,size(airdist,1),size(airdist,1)) .= 0
    one_dist = minimum(airdist[airdist .> 0])
    for i = 1:size(airdist,1)
        for j = 1:size(airdist,1)
            if i != j
                if airdist[i,j] <= one_dist * 1.5
                    adjacent[i,j] = 1
                end
            end
        end
    end
    return adjacent::Array{Bool,2}
end