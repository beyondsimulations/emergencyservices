using CSV
using DelimitedFiles
using DataFrames
#airdist = readdlm("data/distance_0510.csv", ',', Float64)
#airdist = transpose(airdist)
#airdist = airdist[sortperm(airdist[:, 1]), :]
#airdist = airdist[2:end,2:end]
#airdist = round.(airdist, digits = 2)
#writedlm("data/drivingtimes_510.csv",  airdist, ',')
shift = CSV.read("data/shift.csv", DataFrame)
shift = shift[:,2]
shift = round.(Int64, shift)
writedlm("data/shifts_510.csv",  shift, ',')
