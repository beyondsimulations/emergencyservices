import Pkg
Pkg.activate("emergency_services")

using CSV
using DataFrames

problem = "germany"
subproblem = ["G1","G2","G3"]
compactness = ["C0","C1","C2","C3"]
sim_results = CSV.read("results_stage2/$problem/simulation_$(problem)_G0_C0.csv", DataFrame)
sim_results[:,:subproblem] .= "G0"
sim_results[:,:compactness] .= "G0"
for sub in subproblem
    for comp in compactness
        stage = CSV.read("results_stage2/$problem/simulation_$(problem)_$(sub)_$(comp).csv", DataFrame)
        stage[:,:subproblem] .= sub
        stage[:,:compactness] .= comp
        append!(sim_results,stage)
    end
end
CSV.write("results_stage2/$problem/aggregated_simulation_$(problem)2.csv", sim_results)