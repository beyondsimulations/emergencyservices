# function to normalize values
function equalize(vec)
    map = Array{Int64,2}(undef, length(unique(vec)),2) .= 0
    vec = round.(Int64, vec)
    map[:,1] = unique(vec)
    for i = 1:size(map,1)
        map[i,2] = i
    end
    for i = 1:size(vec,1)
        for j = 1:size(map,1)
            if vec[i] == map[j,1]
                vec[i] = map[j,2]
            end
        end
    end
    normalize(vec)
    return vec
end