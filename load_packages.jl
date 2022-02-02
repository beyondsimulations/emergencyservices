# necessary packages for the framework
    using CSV
    using DelimitedFiles
    using DataFrames
    using JuMP
    using Random
    using Shapefile
    using Plots
    using StatsPlots
    using Dates
    using Distributions
    using Gurobi
    using CPLEX

# necessary functions for the framework
    include("functions/part1_adjacency_matrix.jl")
    include("functions/part1_workload_calculation.jl")
    include("functions/part1_sets_m_n.jl")
    include("functions/part1_districting_model.jl")
    include("functions/part1_normalize.jl")
    include("functions/part1_equalize.jl")
    include("functions/part1_plot_districts.jl")
    include("functions/part2_small_functions.jl")
    include("functions/part2_capacity_heuristic.jl")
    include("functions/part2_ressource_flow_matrix.jl")
    include("functions/part2_fill_queues.jl")
    include("functions/part2_incident_dispatch.jl")
    include("functions/part2_fill_exchange_queue.jl")
    include("functions/part2_fulfill_exchange_queue.jl")
    include("functions/part2_prepare_next_minute.jl")
    include("functions/part2_simulation.jl")
    include("functions/evaluation_ressource_status.jl")
    include("functions/evaluation_prepare_results.jl")
    include("functions/evaluation_plot_results.jl")
    include("functions/part2_prepare_stage.jl")
