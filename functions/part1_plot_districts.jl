# Function to generate a plot from the district results
function plot_generation(districts, hexshape)
    plot_area = plot(axis=false, ticks=false)
    if length(unique(districts.location)) > 1
        districts.shape = hexshape.geometry
        normalized_values_area = equalize(districts.location)
        colors_area = Array([cgrad(:Pastel1_9, length(unique(districts.location)), categorical = true)[value] for value in normalized_values_area])
        for x = 1:nrow(districts)
            if districts[x, :location] == districts[x, :index]
                plot!(plot_area, districts[x, :shape], color=RGB(0/255,0/255,0/255))
            elseif districts[x, :location] > 0
                plot!(plot_area, districts[x, :shape], color=colors_area[x])
            else
                plot!(plot_area, districts[x, :shape], color=nothing)
            end
        end
    end
    return plot_area
end