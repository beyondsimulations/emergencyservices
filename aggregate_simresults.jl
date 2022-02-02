import Pkg
Pkg.activate("emergency_services")

using CSV
using DataFrames

problem = "belgium"
subproblem = ["B1","B2","B3"]
compactness = ["C0","C1","C2","C3"]
sim_results = CSV.read("results_stage2/$problem/simulation_$(problem)_B0_C0.csv", DataFrame)
sim_results[:,:subproblem] .= "B0"
sim_results[:,:compactness] .= "C0"
for sub in subproblem
    for comp in compactness
        stage = CSV.read("results_stage2/$problem/simulation_$(problem)_$(sub)_$(comp).csv", DataFrame)
        stage[:,:subproblem] .= sub
        stage[:,:compactness] .= comp
        append!(sim_results,stage)
    end
end
CSV.write("results_stage2/$problem/aggregated_simulation_$(problem).csv", sim_results)