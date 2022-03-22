import Pkg
Pkg.activate("emergency_services")

# import the necessary packages
    using CSV
    using DelimitedFiles
    using DataFrames
    using Dates
    using Distributions
    using Random
    using Plots

# number of random incidents to generate
    random_incidents = 50000

# number of days for generated data
    total_days = 105

# number of priorities
    priorities = 4

# number of hexagons
    hexsize = "2010"

# load and prepare weight data
    weight = readdlm("helper/weight_$hexsize.csv", Float64)
    sum_weight = sum(weight)
    for i = 2:length(weight)
        weight[i] = weight[i] + weight[i-1]
    end
    weight = weight./sum_weight

    function weighted_location(weight)
        rnd = rand()
        location = 0
        for i = 1:length(weight)
            if i == 1
                if rnd <= weight[1]
                    location = 1
                end
            elseif rnd <= weight[i]
                if rnd > weight[i-1]
                    location = i
                    break
                end
            end
        end
        if location == 0
            error("Location not correctly determined!")
        end
        return location
    end
        
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

        # create time
        day = rand(0:total_days-1)::Int64 * 60 * 60 * 24 
        hour = -1
        while hour < 0 || hour > 23
            hour = round(Int64,rand(Normal(12,4),1)[1])
        end
        hour =  hour * 60 * 60
        minute = rand(0:59*60)
        epochtime = current_time + day + hour + minute 

        # create priorities
        prio = priorities
        while prio > priorities - 1
            prio = rand(Poisson(0.85),1)[1]
        end
        prio = priorities - prio

        # create cars
        incident_cars = 1 + rand(Poisson(0.34),1)[1]
        
        # length and backlog from truncated distribution
        incident_length  = round(Int64, rand(TruncatedNormal(21.40, 29.97, 1,  360)))
        incident_backlog = round(Int64, rand(TruncatedNormal(31.65, 17.62, 10, 120)))

        push!(incidents, (incidentid = rand(1:10),
                            priority = prio,
                            cars     = incident_cars,
                            length   = incident_length,
                            backlog  = incident_backlog,
                            location = weighted_location(weight),
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
    display(histogram(incidents[:,:location], fillcolor = :red,    labels = "location"))

# save the data synthetic incident data
    CSV.write("data/incidents_$hexsize.csv", incidents)

# display the 50 first entrys for a first impression
    print(incidents[1:10,:])
    describe(incidents)