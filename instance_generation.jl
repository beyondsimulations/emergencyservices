using CSV
using DataFrames
using Dates
using Distributions
using Random
using Plots

# number of random incidents to generate
random_incidents = 10000

# number of days for generated data
total_days = 30

# number of hexagons
number_hexagons = 510

# create DataFrame for the storage of incidents
cases = DataFrame(caseid = Int[], 
                    priority = Int[], 
                    cars = Int[], 
                    length = Int[], 
                    backlog = Int[], 
                    location = Int[], 
                    epoch = Int[])

# current epoch time today at 00:00:00
current_time = round(Int64,datetime2unix(DateTime(today())))

# create the random incident DataFrame
for incident = 1:random_incidents
    epochtime = current_time +
                rand(0:total_days-1)::Int64 * 60 * 60 * 24 +
                round(Int64,rand(Normal(12,4),1)[1]) * 60 * 24 +
                rand(0:59*60)
    push!(cases, (caseid = rand(1:random_incidents*10),
                    priority = max(5 - rand(Poisson(1),1)[1],1),
                    cars = max(1,rand(Poisson(1),1)[1]),
                    length = round(Int64,max(rand(Normal(45,15),1)[1],5)),
                    backlog = round(Int64,max(rand(Normal(30,10),1)[1],5)),
                    location = rand(1:number_hexagons),
                    epoch = epochtime
                    )
        )
end
cases = sort!(cases, [:epoch])

# Plot some basic statistics
display(histogram(cases[:,:priority], fillcolor = :blue,   labels = "priority"))
display(histogram(cases[:,:cars],     fillcolor = :orange, labels = "cars"))
display(histogram(cases[:,:length],   fillcolor = :green,  labels = "length"))
display(histogram(cases[:,:backlog],  fillcolor = :purple, labels = "backlog"))
display(histogram(cases[:,:epoch],     fillcolor = :black,  labels = "time"))

CSV.write("data/cases.csv", cases)
print(cases[1:50,:])