using CSV
using DataFrames
using Dates
using DelimitedFiles
using Shapefile

problem = "0510"
ad = CSV.read("data/$problem/airdistances_$problem.csv", DataFrame)
ad = ad[1:end,2:end]
ad = round.(Matrix(ad),digits=2)
writedlm("data/$(problem)_new/airdistances_$problem.csv", ad)

ad = CSV.read("data/$problem.csv", DataFrame)
drive = Matrix{Float64}(undef,maximum(ad.origin_id),maximum(ad.origin_id)) .= 0
for i = 1:nrow(ad)
    if ismissing(ad[i,:network_cost])
        if ad[i,:origin_id] == ad[i,:destination_id]
            drive[ad[i,:origin_id],ad[i,:destination_id]] = 0.5
        else
            drive[ad[i,:origin_id],ad[i,:destination_id]] = 0.0
        end
    else
        drive[ad[i,:origin_id],ad[i,:destination_id]] = ad[i,:network_cost]/100
    end
end
for i = 1:maximum(ad.origin_id)
    for j = 1:maximum(ad.origin_id)
        if drive[i,j] == 0.0
            if i > 1
                if i < maximum(ad.origin_id)
                    drive[i,j] = (drive[i-1,j] + drive[i+1,j])/2+rand()
                else
                    drive[i,j] = (drive[i-2,j] + drive[i-1,j])/2+rand()
                end
            else
                drive[i,j] = (drive[i+2,j] + drive[i+1,j])/2+rand()
            end
        end
    end
end
drive = round.(drive, digits = 2)
writedlm("data/$problem/drivingtimes_$problem.csv", drive)

ad = ad[1:end,2:end]
ad = round.(Matrix(ad),digits=2)
writedlm("data/$(problem)_new/airdistances_$problem.csv", ad)

dt = CSV.read("data/$problem/drivingtimes_$problem.csv", DataFrame)
dt = dt[1:end,2:end]
dt = Matrix(dt)
writedlm("data/$(problem)_new/drivingtimes_$problem.csv", dt)


adj = CSV.read("data/$problem/adjacency_$problem.csv", DataFrame)
adj = adj[1:end,2:end]
adj = Matrix(coalesce.(adj,0))
adj = convert(Matrix{Bool}, adj)
writedlm("data/$(problem)_new/adjacency_$problem.csv", adj)

cap = CSV.read("data/$problem/capacity_$problem.csv", DataFrame)
cap = cap[1:end,2:end]
cap = Matrix(cap)
writedlm("data/$(problem)_new/capacity_$problem.csv", cap)

cd = CSV.read("data/$problem/current_districts_$problem.csv", DataFrame)
#cd = cd[:,[1,3]]
#cd = sort(cd, :index_nr)[:,2]

cd_out = Vector{Int64}(undef,size(adj,1)) .= 0
for x = 1:nrow(cd)
    if cd[x,3] > 0
        cd_out[cd[x,2]] = cd[x,1]
    end
end
cd = Vector(cd_out)
writedlm("data/$(problem)_new/current_districts_$problem.csv", cd)

cdp = unique(cd)
writedlm("data/$(problem)_new/current_departments_$problem.csv", cdp)

inc = CSV.read("data/$problem/incidents_$problem.csv", DataFrame)
inc = dropmissing!(inc)
inc_new = DataFrame(incidentid = Int64[],
                    priority = Int64[],
                    cars = Int64[],
                    length = Int64[],
                    backlog = Int64[],
                    location = Int64[],
                    epoch = Float64[])
for x = 1:size(inc,1)
    push!(inc_new, (
            incidentid  = x,
            priority    = inc[x, :priority],
            cars        = inc[x, :cars],
            length      = inc[x,:length],
            backlog     = inc[x, :backlog],
            location    = inc[x, :location],
            epoch       = datetime2unix(inc[x, :date_time])))
end
CSV.write("data/$(problem)_new/incidents_$problem.csv", inc_new)

trfc = CSV.read("data/$problem/traffic_flow_$problem.csv", DataFrame)
trfc = Matrix(trfc)
writedlm("data/$(problem)_new/traffic_flow_$problem.csv", trfc)

adj = readdlm("data/germany/adjacency_germany.csv", Bool)
for i = 1:size(adj,1)
    adj[i,i] = false
end
writedlm("data/germany/adjacency_germany.csv", adj)

current = readdlm("data/germany/current_districts_germany.csv", Int64)[:,1]
cd = DataFrame(index = Int[], location = Int[])
for i = 1:length(current)
    push!(cd, (index = i, location = current[i]))
end
CSV.write("results_stage1/germany/district_layout_germany_B0_C0.csv",cd)

current = readdlm("data/germany/capacity_germany.csv", Int64)