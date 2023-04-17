import Pkg
Pkg.activate("emergency_services")

# load all necessary packages and functions
include("functions/start_load_packages.jl")

# Create the experimental backbone
Ratios = [0.5,1.0]
BAs = ["0510","1008","1508","2040"]
Centres = 3:3:24
Constraints = ["C0","C1","C2","C3"]

# Create the output file
benchmark = DataFrame(
    Ratio=Float64[],
    BAs=Int64[],
    Centres=Int64[],
    Constraints=String[],
    Duration=Float64[],
    ObjVal=Float64[],
    Gap=Float64[]
    )

for problem in BAs
    airdist = readdlm("data/$problem/airdistances_$problem.csv", Float64)
    drivingtime = readdlm("data/$problem/drivingtimes_$problem.csv", Float64)
    adjacent = adjacency_matrix(airdist::Array{Float64,2})
    workload = readdlm("data/$problem/workload_$problem.csv", Float64)
    N, M, card_n, card_m = sets_m_n(airdist::Array{Float64,2}, size(airdist,1)::Int64)
    for ratio in Ratios
        potential_locations = zeros(Bool,size(distance,1))
        for location in randperm(floor(size(distance,1)*ratio))
            potential_locations[location] = 1
        end
        for centre in Centres
            for constraint in Constraints
                X, gap, objval, scnds = model_and_optimise("gurobi"::String,  
                            centre::Int64,
                            drivingtime::Array{Float64,2},
                            zeros(Float64, size(distance,1))::Vector{Float64},
                            workload::Array{Float64,2},
                            adjacent::Array{Bool,2},
                            N::Array{Bool,3},
                            M::Array{Bool,3}, 
                            card_n::Array{Int64,2},
                            card_m::Array{Int64,2},
                            maximum(drivingtime)::Float64,
                            constraint::String,
                            potential_locations::Vector{Bool},
                            0.0::Float64,
                            0::Int64,
                            zeros(Bool,size(distance,1))::Vector{Bool},
                            0::Int64)
                push!(benchmark,(
                    Ratio = ratio,
                    BAs = size(distance,1),
                    Centres = centre,
                    Constraints = constraint,
                    Duration = scnds,
                    ObjVal=objval,
                    Gap=gap
                    )
                )
                CSV.write("results_algorithmic/benchmark.csv", benchmark)
            end
        end
    end
end