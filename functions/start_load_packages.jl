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
    include("part1_adjacency_matrix.jl")
    include("part1_workload_calculation.jl")
    include("part1_sets_m_n.jl")
    include("part1_districting_model.jl")
    include("part1_normalize.jl")
    include("part1_equalize.jl")
    include("part1_plot_districts.jl")
    include("part2_small_functions.jl")
    include("part2_capacity_heuristic.jl")
    include("part2_ressource_flow_matrix.jl")
    include("part2_fill_queues.jl")
    include("part2_incident_dispatch.jl")
    include("part2_determine_patrol_location.jl")
    include("part2_fill_exchange_queue.jl")
    include("part2_fulfill_exchange_queue.jl")
    include("part2_prepare_next_minute.jl")
    include("part2_simulation.jl")
    include("evaluation_ressource_status.jl")
    include("evaluation_prepare_results.jl")
    include("evaluation_plot_results.jl")
    include("part2_prepare_stage.jl")
