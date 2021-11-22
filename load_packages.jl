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

# necessary functions for the framework
    include("functions/adjacency_matrix.jl")
    include("functions/workload_calculation.jl")
    include("functions/sets_m_n.jl")
    include("functions/districting_model.jl")
    include("functions/normalize.jl")
    include("functions/equalize.jl")
    include("functions/plot_districts.jl")
