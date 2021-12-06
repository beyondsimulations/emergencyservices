# this file has to be run before the start of the framework
# in case the framework hasn't been used yet. It installs all
# necessary packages for the framework.
import Pkg; 
Pkg.add("CSV")
Pkg.add("DataFrames")
Pkg.add("JuMP")
Pkg.add("GAMS")
Pkg.add("Shapefile")
Pkg.add("Plots")
Pkg.add("StatsPlots")
Pkg.add("Distributions")
Pkg.add("Cbc")