# Emergency Service Districting
## About the project
This repository contains the code used in a currently anonymised article. It contains a novel framework to create new district layouts for emergency services. First, we apply a modification of the p-median problem with a novel approach to compactness to derive improved district layouts. Second, we simulate emergency service operations based on the new layouts. With this repository, our framework can be reproduced and applied to other emergency service districting problems. Note, that the research data of our article is confidential, therefore we couldn't include our data sets for replication. For a first impression of our framework, we included a synthetic data set.

## Framework
This repository contains the following parts:
1. Emergency Service District Optimisation
2. Emergency Service Simulation
The choice of heuristics as well as parameters can be controlled in the file "main_benchmark_seetings.jl".

## Built with
* [Julia](https://github.com/JuliaLang)
* [GAMS](https://www.gams.com)

## Solver
* [CPLEX](https://www.ibm.com/analytics/cplex-optimizer)

## Getting started
### Prerequisites
Julia 1.6 and GAMS have to be installed on the machine executing the code in this repository. Furthermore, a valid GAMS license is neccessary to solve the districting optimisation with CPLEX. Else choose the option "opensource = true" in the file "start_framework.jl" to change from CPLEX to Cbc. Note, that Cbc is much slower than CPLEX by a factor of 150.

### Installation
1. Install Julia 1.6 and GAMS (use a valid GAMS license and installation if you want to use CPLEX for the district optimisation)
1. Clone the repo
2. Execute the file "install_packages.jl" to install all neccessary packages (also listed under "Associated Repositories")

### Start the framework with our sythetic data set
1. Adjust all parameters to adjust the problem in the file "start_framework.jl" (more details within the comments of the file)
2. Execute the file "start_framework.jl" to start the framework
3. The resulting district layout and simulation results will be saved in the folder "results"
4. All graphs are saved in the folder "graphs"

### Apply the benchmark on own datasets
To apply the benchmark on your own dataset you have to allocate several new files in the folder "data". A detailed instruction of all files and possibilities is listed in the file "load_input.jl". Execute the follwing steps two start the benchmark after all your files are allocated correctly:
1. Rename the variable "problem" in "main_benchmark_settings.jl" after "your_experiment_name" used in all your files
2. Further parameters can be adjusted as explained in "start_framework.jl"
3. Execute the file "start_framework.jl" to start the benchmark
4. The results will be saved in the folder "results" and "graphs"

## License
Distributed under the MIT License. See `LICENSE.txt` for more information.

## Associated Repositories
* [CSV.jl](https://github.com/JuliaData/CSV.jl)
* [DataFrames.jl](https://github.com/JuliaData/DataFrames.jl)
* [Combinatorics.jl](https://github.com/JuliaMath/Combinatorics.jl)
* [Distributions.jl](https://github.com/JuliaStats/Distributions.jl)
* [GAMS.jl](https://github.com/JuliaMath/Combinatorics.jl)
* [JuMP.jl](https://github.com/jump-dev/JuMP.jl)