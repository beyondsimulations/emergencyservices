# Emergency Service Districting
## About the project
This repository contains the code used in a currently anonymized article. It contains a novel framework to create new district layouts for emergency services. First, we apply a modification of the p-median problem with a novel approach to compactness to derive improved district layouts. Second, we simulate emergency service operations based on the new layouts. With this repository, our framework can be reproduced and applied to other emergency service districting problems. Note, that the research data of our article is confidential; therefore, we couldn't include our data sets for replication. For a first impression of our framework, we included 4 synthetic data sets.

## Framework
This repository contains a framework with the following parts:
1. Emergency Service District Optimization (stage 1)
2. Emergency Service Simulation (stage 2)

## Built with
* [Julia](https://github.com/JuliaLang)
* [JuMP](https://www.gams.com)

## Solver
* [Gurobi](https://www.gurobi.com/)

## Getting started
### Prerequisites
Julia 1.7 and Gurobi have to be installed on the machine executing the code in this repository. Furthermore, a valid Gurobi licence is necessary to solve the districting optimization.

### Installation
1. Install Julia 1.7 and Gurobi (use a valid Gurobi licence and installation if you want to the district optimization).
2. Initialize Gurobi as stated in the description of the package [Gurobi.jl](https://github.com/jump-dev/Gurobi.jl)
3. Clone this repo
4. Execute the file “1_install_packages.jl” to install all necessary packages (also listed under “Associated Repositories”)

### Start the framework with our synthetic data set
1. Adjust all parameters to adjust the problem in the file “3_start_framework.jl” (more details within the comments of the file)
2. Execute the file “3_start_framework.jl” to start the framework
3. The resulting district layout and simulation results will be saved in the folders “results_stage1” and “results_stage2”.
4. All graphs are saved in the folder “graphs”.

### Apply the benchmark on own datasets
To apply the benchmark on your dataset, you have to allocate several new files in the folder “data”. A detailed instruction of all files and possibilities is listed in the file “2_load_input.jl”. Execute the following steps to start the benchmark after all your files are allocated correctly:
1. Rename the variable “problem” in “3_start_framework.jl” after “your_experiment_name” used in all your files
2. Further parameters can be adjusted as explained in “3_start_framework.jl”
3. Change the variable “subproblem” in “3_start_framework.jl” to differentiate between scenarios
4. Change the variable “compactness” in “3_start_framework.jl” to select the wished contiguity and compactness constraints
5. Execute the file “3_start_framework.jl” to start the benchmark
6. The results will be saved in the folders “results_stage1”, “results_stage2” and “graphs”

## Licence
Distributed under the MIT Licence. See `LICENSE.txt` for more information.

## Associated Repositories
* [CSV.jl](https://github.com/JuliaData/CSV.jl)
* [DataFrames.jl](https://github.com/JuliaData/DataFrames.jl)
* [Distributions.jl](https://github.com/JuliaStats/Distributions.jl)
* [Gurobi.jl](https://github.com/jump-dev/Gurobi.jl)
* [JuMP.jl](https://github.com/jump-dev/JuMP.jl)
* [Shapefile.jl](https://github.com/JuliaGeo/Shapefile.jl)
* [StatsPlots.jl](https://github.com/JuliaPlots/StatsPlots.jl)