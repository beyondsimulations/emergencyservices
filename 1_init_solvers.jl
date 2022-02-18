# state the os
systemos = "windows"

import Pkg
Pkg.activate("emergency_services")

if systemos == "windows" 
    # Windows - Initialisation
    # Gurobi
    ENV["GUROBI_HOME"] = "C:\\gurobi912\\win64"
    Pkg.add("Gurobi")
    Pkg.build("Gurobi")
    # CPLEX
    ENV["CPLEX_STUDIO_BINARIES"] = "C:\\Program Files\\IBM\\ILOG\\CPLEX_Studio201\\cplex\\bin\\x86-64_win\\"
    Pkg.add("CPLEX")
    Pkg.build("CPLEX")
elseif  systemos == "macos" 
    # MacOS - Initialisation
    # Gurobi
    ENV["GUROBI_HOME"] = "/Library/gurobi950/macos_universal2/"
    Pkg.add("Gurobi")
    Pkg.build("Gurobi")
    # CPLEX
    #ENV["CPLEX_STUDIO_BINARIES"] = "/Applications/CPLEX_Studio201/cplex/bin/x86-64_osx/"
    #Pkg.add("CPLEX")
    #Pkg.build("CPLEX")
end
using Gurobi
using CPLEX
const GRB_ENV = Gurobi.Env()