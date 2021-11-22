# Function to normalize values
function normalize(vec)
    [(x - minimum(vec))/(maximum(vec) - minimum(vec)) for x in vec]
end