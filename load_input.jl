# load all cases (necessary)
## the .csv file has to contain 7 columns representing the incidents
### column 1: caseid -> unique id for each incident (Int)
### column 2: priority -> priority of the incident starting with 1 as
###           as the highest priority (Int)
### column 3: cars -> number of cars requested (Int)
### column 4: length -> length of the incident in minutes (Int)
### column 5: backlog -> length of the paperwork/ backlog after the
###           incident in minutes (Int)
### column 6: location -> unique id of the corresponding basic area 
###           where the incident took place (Int)
### column 7: epoch -> epoch time of the beginning of the incident
###           in seconds (Int)
    incidents = CSV.read("data/incidents_$problem.csv", DataFrame)

# load the aerial distances between the basic areas (necessary)
## 2-dimensional array containing the airial distance between all
## combinations of basic areas (scale irrelevant, Float64)
## example: row 3 column 5 corresponds to the airial distance
##          between basic area 3 and basic area 5
    airdist = readdlm("data/airdistances_$problem.csv", ',', Float64)

# load the driving times between the basic areas(necessary)
## 2-dimensional array containing the driving time between all
## combinations of basic areas in minutes (Float64)
## example: row 3 column 5 corresponds to the driving time
##          between basic area 3 and basic area 5 in minutes
    drivingtime = readdlm("data/drivingtimes_$problem.csv", ',', Float64)

# load the shift pattern for each weekhour (necessary)
## array with 168 entrys, each entry corresponds to one weekhour
## each shift should be assigned with a number starting from 1
    shifts = readdlm("data/shifts_8hours_$problem.csv", ',', Int64)

# load the real capacity plan of the emergency service
## array with 168 rows, where each entry corresponds to one weekhour
## the number of rows depends on the number of districts (number_districts)
    if real_capacity == true
        simulation_capacity = readdlm("data/capacity_$problem.csv", ',', Int64)
        if size(simulation_capacity,2) != number_districts
            error("Number of districts does not match with the capacity plan!")
        end
    end

# load the adjacency matrix between the basic areas(if available)
## 2-dimensional array containing the adjacency between all
## combinations of basic areas (Int64). Important, if rivers or
## other barriers are contained within the area
## example: row 3 column 5 corresponds to the adjacency
##          between basic area 3 and basic area 5
## if no data is available, a matrix is created based on the 
## airial distance between the hexagonal BAs
    if isfile("data/adjacency_$problem.csv")
        adjacent = readdlm("data/adjacency_$problem.csv", ',', Bool)
    else
        adjacent = adjacency_matrix(airdist::Array{Float64,2})
    end

# load the array of potential BAs for a district center (if available)
# if no array is available, all BAs are potential locations (Int)
## binary array with a 1 if a BA represents a potential center, else 0
## the first entry in the array corresponds to the hexagon with the id 1
    if isfile("data/potential_locations_$problem.csv")
        potential_locations = readdlm("data/potential_locations_$problem.csv", ',', Bool)
    else
        potential_locations = Vector{Bool}(undef,size(airdist,1)) .= 1
    end

# load the array of current departments (if available)
# if no array is available, no BA is assumed as current location (Int)
## binary array with a 1 if a BA represents a current location, else 0
## the first entry in the array corresponds to the hexagon with the id 1
    if isfile("data/current_departments_$problem.csv")
        current_locations = readdlm("data/current_departments_$problem.csv", ',', Bool)
    else
        current_locations = Vector{Bool}(undef,size(airdist,1)) .= 0
    end

# load the traffic flow parameter for each weekhour (if available)
# if no array is available, no markup for the traffic is expected
## the .csv file has to contain 2-columns with 168 entrys (Float64)
### column 1: traffic flow parameter q
### column 2: standard deviation of q
### the first entry corresponds to the data for the first weekhour
### the first weekhour starts each monday at 00:00
    if isfile("data/traffic_flow_$problem.csv")
        traffic = readdlm("data/traffic_flow_$problem.csv", ',', Float64)
    else
        traffic = Array{Float64,2}(undef,168,2)
        traffic[:,1] .= 1
        traffic[:,2] .= 0
    end

# load the shape file of the problem instance (if available)
## the .shp file can contain multiple columns, 2 columns are important
## for our model:
### column :id hexagon id
### column :geometry shape file of the hexagon
    if isfile("grids/grid_$problem.shp")
        hexshape = Shapefile.Table("grids/grid_$problem.shp")
        hexshape = DataFrame(hexshape)
        hexshape = sort!(hexshape, :id)
    else
        hexshape = nothing
    end