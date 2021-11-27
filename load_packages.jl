# necessary packages for the framework
    using CSV
    using DelimitedFiles
    using DataFrames
    using JuMP
    using GAMS
    using Random
    using Shapefile
    using Plots
    using GAMS
    using Dates
    using Distributions

# necessary functions for the framework
    include("functions/both_adjacency_matrix.jl")
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
