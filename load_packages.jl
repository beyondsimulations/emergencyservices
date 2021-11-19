# necessary packages for the framework
    using CSV
    using DelimitedFiles
    using DataFrames
    using JuMP
    using GAMS
    using Random
    using Shapefile
    using Plots

# necessary functions for the framework
    include("functions/adjacency_matrix.jl")
    include("functions/workload_calculation.jl")
