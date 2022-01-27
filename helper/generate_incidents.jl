# import the necessary packages
    using CSV
    using DataFrames
    using Dates
    using Distributions
    using Random
    using Plots

# number of random incidents to generate
    random_incidents = 80000

# number of days for generated data
    total_days = 84

# number of hexagons
    hexsize = 0510

# create DataFrame for the storage of incidents
    incidents = DataFrame(incidentid = Int[], 
                            priority = Int[], 
                            cars = Int[], 
                            length = Int[], 
                            backlog = Int[], 
                            location = Int[], 
                            epoch = Int[]
                            )

# current epoch time today at 00:00:00
    current_time = round(Int64,datetime2unix(DateTime(today())))

# create the random incident DataFrame
    for incident = 1:random_incidents
        day = rand(0:total_days-1)::Int64 * 60 * 60 * 24 
        hour = -1
        while hour < 0 || hour > 23
            hour = round(Int64,rand(Normal(12,4),1)[1])
        end
        hour =  hour * 60 * 60
        minute = rand(0:59*60)
        epochtime = current_time + day + hour + minute        
        push!(incidents, (incidentid = rand(1:random_incidents*10),
                            priority = max(5 - rand(Poisson(1),1)[1],1),
                            cars = max(1,rand(Poisson(1),1)[1]),
                            length = round(Int64,max(rand(Normal(45,15),1)[1],5)),
                            backlog = round(Int64,max(rand(Normal(30,10),1)[1],5)),
                            location = rand(1:hexsize),
                            epoch = epochtime
                        )
            )
    end
    incidents = sort!(incidents, [:epoch])
    for incident = 1:random_incidents
        incidents[incident,:incidentid] = incident
    end

# Plot some basic statistics
    display(histogram(incidents[:,:priority], fillcolor = :blue,   labels = "priority"))
    display(histogram(incidents[:,:cars],     fillcolor = :orange, labels = "cars"))
    display(histogram(incidents[:,:length],   fillcolor = :green,  labels = "length"))
    display(histogram(incidents[:,:backlog],  fillcolor = :purple, labels = "backlog"))
    display(histogram(incidents[:,:epoch],    fillcolor = :black,  labels = "time"))

# save the data synthetic incident data
    CSV.write("data/incidents_$hexsize.csv", incidents)

# display the 50 first entrys for a first impression
    print(incidents[1:10,:])