using CSV
using DelimitedFiles
using DataFrames
#airdist = readdlm("data/air_2010.csv", ',', Float64)
#airdist = transpose(airdist)
#airdist = airdist[sortperm(airdist[:, 1]), :]
#airdist = airdist[2:end,2:end]
#airdist = round.(airdist./1000, digits = 2)
#writedlm("data/airdistances_2010.csv",  airdist, ',')
#shift = CSV.read("data/shift.csv", DataFrame)
#shift = shift[:,2]
#shift = round.(Int64, shift)
#writedlm("data/shifts_510.csv",  shift, ',')
drivedist = CSV.read("data/distance_2010.csv", DataFrame)
driving = Array{Float64,2}(undef,maximum(drivedist[:,:origin_id]),maximum(drivedist[:,:origin_id])) .= 0
for i = 1:nrow(drivedist)
    if ismissing(drivedist[i,:network_cost]) == false
        driving[drivedist[i,:origin_id],drivedist[i,:destination_id]] = drivedist[i,:network_cost]
    end
end
driving = round.(driving./1000, digits = 3)
writedlm("data/dirvingtimes_2010.csv",  driving, ',')
